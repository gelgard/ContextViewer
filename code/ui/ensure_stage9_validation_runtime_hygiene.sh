#!/usr/bin/env bash
# AI Task 091: Stage 9 validation runtime hygiene (ports + stale preview/verifier processes; stdout = one JSON object).
set -euo pipefail

usage() {
  cat <<'USAGE'
ensure_stage9_validation_runtime_hygiene.sh — preflight for Stage 9 UI/preview validators

Inspects listener ports and optionally terminates *only* clearly identified stale helpers:
  - python3 -m http.server whose command line matches preview output dir or contextviewer_ui_preview
  - orphaned bash processes matching verify_stage9_* / get_stage9_completion_gate_report.sh
    (excluding this process and its parent), via pgrep when available.

Stdout: exactly one JSON object (see script header in repo).

Options:
  -h, --help
  --port <n>                Repeatable; default 8787 if none given
  --output-dir <path>       default /tmp/contextviewer_ui_preview
  --clean                   Default: clean stale matches (SIGTERM)
  --no-clean                Audit only
  --allow-foreign           Do not fail if a non-preview process holds --port (still reported)

Exit: 0 ok, 1 fail (always JSON stdout), 2 bad CLI (stderr, no JSON)

Environment:
  STAGE9_HYGIENE_SKIP=1 — emit ok JSON and exit 0 (parent gates use for diagnostics only; do not use in CI closure evidence)

Dependencies: jq, lsof, ps; pgrep optional
USAGE
}

ports=()
output_dir="/tmp/contextviewer_ui_preview"
clean=true
allow_foreign=false
skip_all="${STAGE9_HYGIENE_SKIP:-0}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --port)
      [[ -n "${2:-}" ]] || { echo "error: --port needs value" >&2; exit 2; }
      ports+=("$2"); shift 2 ;;
    --output-dir)
      [[ -n "${2:-}" ]] || { echo "error: --output-dir needs value" >&2; exit 2; }
      output_dir="$2"; shift 2 ;;
    --clean) clean=true; shift ;;
    --no-clean) clean=false; shift ;;
    --allow-foreign) allow_foreign=true; shift ;;
    *) echo "error: unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ ${#ports[@]} -eq 0 ]] && ports=(8787)

command -v jq >/dev/null 2>&1 || { echo "error: jq required" >&2; exit 2; }

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
my_pid="$$"
parent_pid="${PPID:-0}"

if [[ "$skip_all" == "1" ]]; then
  ports_json="$(printf '%s\n' "${ports[@]}" | jq -cn -R '[inputs | tonumber]')"
  jq -n \
    --arg ga "$generated_at" \
    --argjson ports "$ports_json" \
    --arg od "$output_dir" \
    '{
      status: "ok",
      generated_at: $ga,
      ports_checked: $ports,
      output_dir: $od,
      cleaned_processes: [],
      port_listeners: [],
      foreign_listeners: [],
      checks: [{
        name: "hygiene_skip",
        status: "pass",
        details: "STAGE9_HYGIENE_SKIP=1"
      }],
      failed_checks: 0,
      blocker_class: null
    }'
  exit 0
fi

od_abs="$output_dir"
if [[ -d "$output_dir" ]]; then
  od_abs="$(cd "$output_dir" && pwd)" || od_abs="$output_dir"
fi
od_base="$(basename "$od_abs")"

is_our_http_server_cmd() {
  local c="$1"
  [[ "$c" == *"python"* ]] && [[ "$c" == *"http.server"* ]] \
    && { [[ "$c" == *"$od_abs"* ]] || [[ "$c" == *"$od_base"* ]] || [[ "$c" == *"contextviewer_ui_preview"* ]]; }
}

is_stale_verifier_cmd() {
  local c="$1"
  [[ "$c" == *"verify_stage9_secondary_flows_readiness_gate"* ]] \
    || [[ "$c" == *"verify_stage9_completion_gate"* ]] \
    || [[ "$c" == *"get_stage9_completion_gate_report"* ]]
}

should_skip_pid() {
  local p="$1"
  [[ "$p" == "$my_pid" ]] || [[ "$p" == "$parent_pid" ]]
}

listener_pids_for_port() {
  local port="$1"
  lsof -nP -iTCP:"$port" -sTCP:LISTEN -t 2>/dev/null || true
}

listeners_json='[]'
cleaned_json='[]'
checks_json='[]'
fc=0
blocker='null'

add_chk() {
  local n="$1" st="$2" det="$3"
  checks_json="$(jq -n --argjson c "$checks_json" --arg n "$n" --arg st "$st" --arg d "$det" \
    '$c + [{name: $n, status: $st, details: $d}]')"
  if [[ "$st" == "fail" ]]; then
    fc=$((fc + 1))
  fi
}

kill_pid_term() {
  local pid="$1" reason="$2"
  kill -TERM "$pid" 2>/dev/null || true
  cleaned_json="$(jq -n --argjson c "$cleaned_json" --argjson p "$pid" --arg r "$reason" \
    '$c + [{pid: $p, reason: $r, signal: "SIGTERM"}]')"
}

ports_json="$(printf '%s\n' "${ports[@]}" | jq -cn -R '[inputs | tonumber]')"

for port in "${ports[@]}"; do
  if [[ ! "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]]; then
    add_chk "port_numeric" "fail" "invalid port: $port"
    continue
  fi
  for pid in $(listener_pids_for_port "$port"); do
    [[ -z "$pid" ]] && continue
    should_skip_pid "$pid" && continue
    cmd="$(ps -p "$pid" -o command= 2>/dev/null | tr '\n' ' ' || true)"
    row="$(jq -n --argjson pt "$port" --argjson pi "$pid" --arg c "$cmd" '{port: $pt, pid: $pi, command: $c}')"
    if is_our_http_server_cmd "$cmd"; then
      listeners_json="$(jq -n --argjson acc "$listeners_json" --argjson r "$row" '$acc + [$r]')"
      if [[ "$clean" == true ]]; then
        kill_pid_term "$pid" "python_http_server_preview_port_${port}"
      fi
    fi
  done
done

if [[ "$clean" == true ]] && [[ "$(jq 'length' <<<"$cleaned_json")" -gt 0 ]] 2>/dev/null; then
  sleep 0.35
fi

# Re-scan for remaining foreign TCP listeners on requested ports
foreign_final='[]'
for port in "${ports[@]}"; do
  [[ "$port" =~ ^[0-9]+$ ]] || continue
  for pid in $(listener_pids_for_port "$port"); do
    [[ -z "$pid" ]] && continue
    should_skip_pid "$pid" && continue
    cmd="$(ps -p "$pid" -o command= 2>/dev/null | tr '\n' ' ' || true)"
    is_our_http_server_cmd "$cmd" && continue
    row="$(jq -n --argjson pt "$port" --argjson pi "$pid" --arg c "$cmd" '{port: $pt, pid: $pi, command: $c}')"
    foreign_final="$(jq -n --argjson acc "$foreign_final" --argjson r "$row" '$acc + [$r]')"
  done
done

if [[ "$(jq 'length' <<<"$foreign_final")" -gt 0 ]]; then
  if [[ "$allow_foreign" == true ]]; then
    add_chk "foreign_listener_warn" "pass" "allow-foreign: $(jq -c . <<<"$foreign_final")"
  else
    add_chk "foreign_listener" "fail" "port_process_hygiene: non-preview TCP listener: $(jq -c . <<<"$foreign_final")"
    blocker='"port_process_hygiene"'
  fi
else
  add_chk "port_listeners" "pass" "no blocking foreign listeners on requested ports"
fi

if command -v pgrep >/dev/null 2>&1 && [[ "$clean" == true ]]; then
  for pat in \
    'verify_stage9_secondary_flows_readiness_gate\.sh' \
    'verify_stage9_completion_gate\.sh' \
    'get_stage9_completion_gate_report\.sh'; do
    while read -r pid; do
      [[ -z "$pid" ]] && continue
      should_skip_pid "$pid" && continue
      cmd="$(ps -p "$pid" -o command= 2>/dev/null | tr '\n' ' ' || true)"
      is_stale_verifier_cmd "$cmd" || continue
      kill_pid_term "$pid" "stale_verifier_pgrep_${pat}"
    done < <(pgrep -f "$pat" 2>/dev/null || true)
  done
fi

st="ok"
[[ "$fc" -gt 0 ]] && st="fail"

jq -n \
  --arg st "$st" \
  --arg ga "$generated_at" \
  --argjson ports "$ports_json" \
  --arg od "$output_dir" \
  --argjson cleaned "$cleaned_json" \
  --argjson lst "$listeners_json" \
  --argjson fr "$foreign_final" \
  --argjson chk "$checks_json" \
  --argjson fc "$fc" \
  --argjson bc "$blocker" \
  '{
    status: $st,
    generated_at: $ga,
    ports_checked: $ports,
    output_dir: $od,
    cleaned_processes: $cleaned,
    port_listeners: $lst,
    foreign_listeners: $fr,
    checks: $chk,
    failed_checks: $fc,
    blocker_class: $bc
  }'

[[ "$st" == "ok" ]] && exit 0
exit 1
