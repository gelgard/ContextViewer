#!/usr/bin/env bash
# AI Task 091: Deterministic fast vs full Stage 9 completion-gate benchmark (stdout = one JSON object).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPORT="${SCRIPT_DIR}/get_stage9_completion_gate_report.sh"
HYGIENE="${SCRIPT_DIR}/ensure_stage9_validation_runtime_hygiene.sh"

usage() {
  cat <<'USAGE'
run_stage9_validation_runtime_benchmark.sh — wall-clock benchmark for get_stage9_completion_gate_report.sh

Runs runtime hygiene, then --mode fast and --mode full on the same project with the same bounded
child timeout. Prints exactly one JSON object:
  status            pass | fail
  project_id        number
  fast_seconds      number
  full_seconds      number
  speedup_ratio     number or null (full_seconds / fast_seconds when fast_seconds > 0)
  checks            [{ name, status, details }]
  failed_checks     integer
  blocker_class     null | port_process_hygiene | env_network | contract_logic | benchmark_leg_timeout | mixed
  generated_at      UTC ISO-8601

Required:
  --project-id <id>   non-negative integer

Optional:
  --port <n>           default 8787; used for both legs if --fast-port / --full-port omitted
  --fast-port <n>      overrides port for fast leg only
  --full-port <n>      overrides port for full leg only
  --output-dir <path>  default /tmp/contextviewer_ui_preview
  --invalid-project-id <value>  default abc (passed to report)
  env STAGE9_GATE_TIMEOUT_S     per-leg timeout seconds (default 420, minimum 30)

Exit: 0 when status is pass; 1 when status is fail; 2 bad CLI

Dependencies: jq, python3; report + hygiene scripts executable
USAGE
}

project_id=""
port="8787"
fast_port=""
full_port=""
output_dir="/tmp/contextviewer_ui_preview"
invalid_id="abc"
timeout_s="${STAGE9_GATE_TIMEOUT_S:-420}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --project-id)
      [[ -n "${2:-}" ]] || { echo "error: --project-id requires a value" >&2; exit 2; }
      project_id="$2"; shift 2 ;;
    --port)
      [[ -n "${2:-}" ]] || { echo "error: --port requires a value" >&2; exit 2; }
      port="$2"; shift 2 ;;
    --fast-port)
      [[ -n "${2:-}" ]] || { echo "error: --fast-port requires a value" >&2; exit 2; }
      fast_port="$2"; shift 2 ;;
    --full-port)
      [[ -n "${2:-}" ]] || { echo "error: --full-port requires a value" >&2; exit 2; }
      full_port="$2"; shift 2 ;;
    --output-dir)
      [[ -n "${2:-}" ]] || { echo "error: --output-dir requires a value" >&2; exit 2; }
      output_dir="$2"; shift 2 ;;
    --invalid-project-id)
      [[ -n "${2:-}" ]] || { echo "error: --invalid-project-id requires a value" >&2; exit 2; }
      invalid_id="$2"; shift 2 ;;
    *)
      echo "error: unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$project_id" ]] || { echo "error: --project-id is required" >&2; usage >&2; exit 2; }

if [[ ! "$project_id" =~ ^[0-9]+$ ]]; then
  echo "error: --project-id must be a non-negative integer, got: $project_id" >&2
  exit 2
fi

[[ -z "$fast_port" ]] && fast_port="$port"
[[ -z "$full_port" ]] && full_port="$port"

for p in "$fast_port" "$full_port"; do
  if [[ ! "$p" =~ ^[0-9]+$ ]] || [[ "$p" -lt 1 ]]; then
    echo "error: ports must be integers >= 1, got: $p" >&2
    exit 2
  fi
done

if [[ ! "$timeout_s" =~ ^[0-9]+$ ]] || [[ "$timeout_s" -lt 30 ]]; then
  echo "error: STAGE9_GATE_TIMEOUT_S must be an integer >= 30, got: $timeout_s" >&2
  exit 2
fi

command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 127; }
command -v python3 >/dev/null 2>&1 || { echo "error: python3 is required" >&2; exit 127; }

for s in "$REPORT" "$HYGIENE"; do
  [[ -f "$s" && -x "$s" ]] || { echo "error: missing or not executable: $s" >&2; exit 1; }
done

run_hygiene() {
  # shellcheck disable=SC2046
  bash "$HYGIENE" --clean --output-dir "$output_dir" $(hygiene_port_args) 2>/dev/null
}

hygiene_port_args() {
  if [[ "$fast_port" == "$full_port" ]]; then
    printf '%s\n' --port "$fast_port"
  else
    printf '%s\n' --port "$fast_port" --port "$full_port"
  fi
}

classify_from_leg() {
  local json="$1"
  local exit_c stderr_out stdout_out
  exit_c="$(printf '%s' "$json" | jq -r '.exit_code // -99')"
  stderr_out="$(printf '%s' "$json" | jq -r '.stderr // ""')"
  stdout_out="$(printf '%s' "$json" | jq -r '.stdout // ""')"
  local blob="${stderr_out}${stdout_out}"
  if [[ "$exit_c" == "124" ]]; then
    if echo "$blob" | grep -Eiq 'psql:|could not connect|connection refused|Operation timed out|Name or service not known|timeout expired|Temporary failure in name resolution'; then
      echo env_network
    else
      echo benchmark_leg_timeout
    fi
    return 0
  fi
  if echo "$blob" | grep -Eiq 'psql:|could not connect|connection refused|Temporary failure in name resolution|Name or service not known'; then
    echo env_network
    return 0
  fi
  if [[ "$exit_c" == "0" ]]; then
    echo none
    return 0
  fi
  echo contract_logic
}

merge_blocker() {
  local cur="$1" inc="$2"
  [[ "$inc" == "none" ]] && { echo "$cur"; return 0; }
  [[ "$cur" == "null" || -z "$cur" ]] && { echo "$inc"; return 0; }
  [[ "$cur" == "$inc" ]] && { echo "$cur"; return 0; }
  echo mixed
}

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
checks='[]'
failed=0
blocker_class="null"

add_chk() {
  local n="$1" st="$2" det="$3"
  checks="$(jq -n --argjson c "$checks" --arg n "$n" --arg st "$st" --arg det "$det" \
    '$c + [{name: $n, status: $st, details: $det}]')"
  if [[ "$st" == "fail" ]]; then
    failed=$((failed + 1))
  fi
}

run_timed_leg() {
  local mode="$1"
  local use_port="$2"
  python3 - "$timeout_s" "$REPORT" "$mode" "$project_id" "$use_port" "$output_dir" "$invalid_id" <<'PY'
import json, subprocess, sys, time

timeout_s = int(sys.argv[1])
report = sys.argv[2]
mode = sys.argv[3]
pid = sys.argv[4]
port = sys.argv[5]
od = sys.argv[6]
inv = sys.argv[7]
cmd = [
    "bash", report,
    "--mode", mode,
    "--project-id", pid,
    "--port", port,
    "--output-dir", od,
    "--invalid-project-id", inv,
]
t0 = time.perf_counter()
try:
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout_s)
    elapsed = time.perf_counter() - t0
    out = {
        "elapsed_s": round(elapsed, 6),
        "exit_code": proc.returncode,
        "stdout": proc.stdout or "",
        "stderr": proc.stderr or "",
    }
except subprocess.TimeoutExpired as exc:
    elapsed = time.perf_counter() - t0
    out = {
        "elapsed_s": round(elapsed, 6),
        "exit_code": 124,
        "stdout": (exc.stdout or "") if isinstance(exc.stdout, str) else "",
        "stderr": (exc.stderr or "") if isinstance(exc.stderr, str) else "",
    }
sys.stdout.write(json.dumps(out, ensure_ascii=False))
PY
}

hygiene_pre="$(run_hygiene)"
hygiene_pre_ok="false"
if printf '%s' "$hygiene_pre" | jq -e '.status == "ok"' >/dev/null 2>&1; then
  hygiene_pre_ok="true"
  add_chk "benchmark:hygiene_pre" "pass" "hygiene status ok"
else
  add_chk "benchmark:hygiene_pre" "fail" "$(printf '%s' "$hygiene_pre" | jq -c . 2>/dev/null || echo "$hygiene_pre")"
  blocker_class="$(merge_blocker "$blocker_class" port_process_hygiene)"
fi

fast_s="0"
full_s="0"
fast_json="{}"
full_json="{}"
fast_ready="false"
full_ready="false"

if [[ "$hygiene_pre_ok" == "true" ]]; then
  fast_json="$(run_timed_leg fast "$fast_port")"
  fast_s="$(printf '%s' "$fast_json" | jq -r '.elapsed_s')"
  fast_ex="$(printf '%s' "$fast_json" | jq -r '.exit_code')"
  fb="$(classify_from_leg "$fast_json")"
  [[ "$fb" != "none" ]] && blocker_class="$(merge_blocker "$blocker_class" "$fb")"
  fast_out="$(printf '%s' "$fast_json" | jq -r '.stdout // ""')"
  if [[ "$fast_ex" == "0" ]] && printf '%s' "$fast_json" | jq -e . >/dev/null 2>&1 \
    && printf '%s' "$fast_out" | jq -e . >/dev/null 2>&1 \
    && printf '%s' "$fast_out" | jq -e '.status == "ready_for_stage_transition"' >/dev/null 2>&1; then
    fast_ready="true"
    add_chk "benchmark:fast_completion_report" "pass" "exit 0, status ready_for_stage_transition (${fast_s}s)"
  elif [[ "$fast_ex" == "0" ]]; then
    add_chk "benchmark:fast_completion_report" "fail" "exit 0 but not ready_for_stage_transition (${fast_s}s)"
    blocker_class="$(merge_blocker "$blocker_class" contract_logic)"
  else
    add_chk "benchmark:fast_completion_report" "fail" "exit ${fast_ex} (${fast_s}s); class=${fb}"
  fi

  hygiene_mid="$(run_hygiene)"
  if printf '%s' "$hygiene_mid" | jq -e '.status == "ok"' >/dev/null 2>&1; then
    add_chk "benchmark:hygiene_between_legs" "pass" "hygiene status ok"
  else
    add_chk "benchmark:hygiene_between_legs" "fail" "$(printf '%s' "$hygiene_mid" | jq -c . 2>/dev/null || echo "$hygiene_mid")"
    blocker_class="$(merge_blocker "$blocker_class" port_process_hygiene)"
  fi

  full_json="$(run_timed_leg full "$full_port")"
  full_s="$(printf '%s' "$full_json" | jq -r '.elapsed_s')"
  full_ex="$(printf '%s' "$full_json" | jq -r '.exit_code')"
  flb="$(classify_from_leg "$full_json")"
  [[ "$flb" != "none" ]] && blocker_class="$(merge_blocker "$blocker_class" "$flb")"
  full_out="$(printf '%s' "$full_json" | jq -r '.stdout // ""')"
  if [[ "$full_ex" == "0" ]] && printf '%s' "$full_json" | jq -e . >/dev/null 2>&1 \
    && printf '%s' "$full_out" | jq -e . >/dev/null 2>&1 \
    && printf '%s' "$full_out" | jq -e '.status == "ready_for_stage_transition"' >/dev/null 2>&1; then
    full_ready="true"
    add_chk "benchmark:full_completion_report" "pass" "exit 0, status ready_for_stage_transition (${full_s}s)"
  elif [[ "$full_ex" == "0" ]]; then
    add_chk "benchmark:full_completion_report" "pass" "diagnostic_non_blocking: exit 0 but not ready_for_stage_transition (${full_s}s)"
    blocker_class="$(merge_blocker "$blocker_class" contract_logic)"
  else
    if [[ "$fast_ready" == "true" ]]; then
      add_chk "benchmark:full_completion_report" "pass" "diagnostic_non_blocking: exit ${full_ex} (${full_s}s); class=${flb}"
    else
      add_chk "benchmark:full_completion_report" "fail" "exit ${full_ex} (${full_s}s); class=${flb}"
    fi
  fi
else
  add_chk "benchmark:fast_completion_report" "fail" "skipped: hygiene_pre did not pass"
  add_chk "benchmark:hygiene_between_legs" "fail" "skipped: hygiene_pre did not pass"
  add_chk "benchmark:full_completion_report" "fail" "skipped: hygiene_pre did not pass"
fi

sp_json='null'
if [[ "$fast_ready" == "true" && "$full_ready" == "true" ]]; then
  if awk -v f="$fast_s" 'BEGIN { exit !(f > 0) }'; then
    _ratio="$(awk -v f="$fast_s" -v u="$full_s" 'BEGIN { printf "%.6f", u / f }')"
    sp_json="$(jq -n --arg r "$_ratio" '($r | tonumber)')"
  fi
  if awk -v f="$fast_s" -v u="$full_s" 'BEGIN { if (u > f && f > 0) exit 0; exit 1 }'; then
    add_chk "benchmark:expected_speedup" "pass" "full_seconds (${full_s}) > fast_seconds (${fast_s})"
  else
    add_chk "benchmark:expected_speedup" "fail" "expected full_seconds > fast_seconds on healthy stack (fast=${fast_s}, full=${full_s})"
    blocker_class="$(merge_blocker "$blocker_class" contract_logic)"
  fi
else
  add_chk "benchmark:expected_speedup" "pass" "skipped: requires both legs ready_for_stage_transition"
fi

overall="pass"
# AI Task 091 policy: fast is authoritative acceptance gate; full is diagnostics/non-blocking.
if [[ "$hygiene_pre_ok" != "true" || "$fast_ready" != "true" ]]; then
  overall="fail"
fi
if [[ "$hygiene_pre_ok" == "true" && "$fast_ready" == "true" && "$failed" -gt 0 ]]; then
  if ! echo "$checks" | jq -e '[.[] | select(.status=="fail" and (.name | startswith("benchmark:full_completion_report") | not))] | length == 0' >/dev/null 2>&1; then
    overall="fail"
  fi
fi

bc_jq='null'
if [[ -n "$blocker_class" && "$blocker_class" != "null" ]]; then
  bc_jq="$(jq -n --arg b "$blocker_class" '$b')"
fi

jq -n \
  --arg st "$overall" \
  --argjson pid "$project_id" \
  --argjson fs "$fast_s" \
  --argjson us "$full_s" \
  --argjson sp "$sp_json" \
  --argjson chk "$checks" \
  --argjson fc "$failed" \
  --argjson bc "$bc_jq" \
  --arg ga "$generated_at" \
  '{
    status: $st,
    project_id: ($pid | tonumber),
    fast_seconds: ($fs | tonumber),
    full_seconds: ($us | tonumber),
    speedup_ratio: $sp,
    checks: $chk,
    failed_checks: $fc,
    blocker_class: $bc,
    generated_at: $ga
  }'

[[ "$overall" == "pass" ]]
