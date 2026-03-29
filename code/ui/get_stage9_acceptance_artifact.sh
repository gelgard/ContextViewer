#!/usr/bin/env bash
# AI Task 094: Stage 9 primary acceptance artifact — fast completion evidence only (no benchmark; no contextJSON authority).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CTX_DIR="$REPO_ROOT/contextJSON"
COMPLETION="${SCRIPT_DIR}/get_stage9_completion_gate_report.sh"
HYGIENE="${SCRIPT_DIR}/ensure_stage9_validation_runtime_hygiene.sh"

usage() {
  cat <<'USAGE'
get_stage9_acceptance_artifact.sh — Stage 9 lightweight primary acceptance artifact (one JSON object)

Builds minimum authoritative closure evidence from the fast completion path only:
  get_stage9_completion_gate_report.sh --mode fast --skip-hygiene-preflight
  (after optional runtime hygiene), plus informational external-export filename metadata.

No benchmark. No markdown-derived runtime. contextJSON/* is not acceptance authority — only an
optional informational latest-filename field under external_export_metadata.

Required:
  --project-id <id>   non-negative integer

Optional:
  --port <n>, --output-dir <path>, --invalid-project-id <value>  (defaults match Stage 9 gates)
  --skip-hygiene            skip ensure_stage9_validation_runtime_hygiene (caller ran hygiene)
  env STAGE9_GATE_TIMEOUT_S child timeout (default 420, min 30)
  env STAGE9_HYGIENE_SKIP=1 skip hygiene (diagnostics only)

Stdout: one JSON object:
  schema_version, project_id, generated_at, status, closure_ready,
  acceptance_authority, completion_report (full fast report object),
  external_export_metadata (latest_contextjson_filename nullable, is_acceptance_authority: false)

Exit 0 when closure_ready; exit 3 when artifact is valid but not ready; exit 2 CLI; exit 1 bad id.
USAGE
}

project_id=""
port="8787"
output_dir="/tmp/contextviewer_ui_preview"
invalid_id="abc"
child_timeout_s="${STAGE9_GATE_TIMEOUT_S:-420}"
skip_hygiene="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --project-id)
      [[ -n "${2:-}" ]] || { echo "error: --project-id requires a value" >&2; exit 2; }
      project_id="$2"; shift 2 ;;
    --port)
      [[ -n "${2:-}" ]] || { echo "error: --port requires a value" >&2; exit 2; }
      port="$2"; shift 2 ;;
    --output-dir)
      [[ -n "${2:-}" ]] || { echo "error: --output-dir requires a value" >&2; exit 2; }
      output_dir="$2"; shift 2 ;;
    --invalid-project-id)
      [[ -n "${2:-}" ]] || { echo "error: --invalid-project-id requires a value" >&2; exit 2; }
      invalid_id="$2"; shift 2 ;;
    --skip-hygiene)
      skip_hygiene="1"; shift ;;
    *)
      echo "error: unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$project_id" ]] || { echo "error: --project-id is required" >&2; usage >&2; exit 2; }
if [[ ! "$project_id" =~ ^[0-9]+$ ]]; then
  echo "error: --project-id must be a non-negative integer, got: $project_id" >&2
  exit 1
fi
if [[ ! "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]]; then
  echo "error: --port must be an integer >= 1, got: $port" >&2
  exit 1
fi
if [[ ! "$child_timeout_s" =~ ^[0-9]+$ ]] || [[ "$child_timeout_s" -lt 30 ]]; then
  echo "error: STAGE9_GATE_TIMEOUT_S must be an integer >= 30, got: $child_timeout_s" >&2
  exit 1
fi

command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 127; }
[[ -f "$COMPLETION" && -x "$COMPLETION" ]] || { echo "error: missing or not executable: $COMPLETION" >&2; exit 1; }
[[ -f "$HYGIENE" && -x "$HYGIENE" ]] || { echo "error: missing or not executable: $HYGIENE" >&2; exit 1; }

run_bounded() {
  python3 - "$child_timeout_s" "$@" <<'PY'
import subprocess
import sys
timeout_s = int(sys.argv[1])
cmd = sys.argv[2:]
try:
    proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout_s)
    if proc.stdout:
        sys.stdout.write(proc.stdout)
    if proc.stderr:
        sys.stderr.write(proc.stderr)
    sys.exit(proc.returncode)
except subprocess.TimeoutExpired as exc:
    out = exc.stdout or ""
    err = exc.stderr or ""
    if isinstance(out, bytes):
        out = out.decode("utf-8", errors="replace")
    if isinstance(err, bytes):
        err = err.decode("utf-8", errors="replace")
    if out:
        sys.stdout.write(out)
    if err:
        sys.stderr.write(err)
    sys.stderr.write(f"error: timeout after {timeout_s}s: {' '.join(cmd)}\n")
    sys.exit(124)
PY
}

hygiene_skip_env="${STAGE9_HYGIENE_SKIP:-0}"
if [[ "$skip_hygiene" != "1" && "$hygiene_skip_env" != "1" ]]; then
  set +e
  hygiene_out="$(bash "$HYGIENE" --port "$port" --output-dir "$output_dir" --clean 2>/dev/null)"
  hygiene_rc=$?
  set -e
  hygiene_st="fail"
  if [[ "$hygiene_rc" -eq 0 ]] && printf '%s' "$hygiene_out" | jq -e . >/dev/null 2>&1; then
    hygiene_st="$(printf '%s' "$hygiene_out" | jq -r '.status // "fail"')"
  fi
  if [[ "$hygiene_st" != "ok" ]]; then
    ga="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    pid_num="$project_id"
    blk_c="$(printf '%s' "$hygiene_out" | jq -c . 2>/dev/null || printf '%s' "$hygiene_out" | head -c 1200 | jq -Rs .)"
    # Minimal not-ready artifact (hygiene blocked inner completion)
    jq -n \
      --argjson pid "$pid_num" \
      --arg ga "$ga" \
      --arg hv "$hygiene_st" \
      --argjson hrc "$hygiene_rc" \
      --arg bc "$blk_c" \
      '{
        schema_version: "stage9_acceptance_artifact_v1",
        project_id: ($pid | tonumber),
        generated_at: $ga,
        status: "not_ready",
        closure_ready: false,
        acceptance_authority: "fast_completion_report_embed",
        hygiene_block: { status: $hv, exit_code: $hrc, details: $bc },
        completion_report: null,
        external_export_metadata: {
          latest_contextjson_filename: null,
          purpose: "viewer_export_informational_only",
          is_acceptance_authority: false
        }
      }'
    exit 3
  fi
fi

latest_fn=""
if [[ -d "$CTX_DIR" ]]; then
  # shellcheck disable=SC2012
  latest="$(ls -1 "$CTX_DIR"/json_*.json 2>/dev/null | LC_ALL=C sort | tail -1 || true)"
  [[ -n "$latest" && -f "$latest" ]] && latest_fn="$(basename "$latest")"
fi

set +e
comp_out="$(run_bounded bash "$COMPLETION" --mode fast --skip-hygiene-preflight --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
comp_rc=$?
set -e

if ! printf '%s' "$comp_out" | jq -e . >/dev/null 2>&1; then
  ga="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  jq -n \
    --argjson pid "$project_id" \
    --arg ga "$ga" \
    --argjson crc "$comp_rc" \
    --arg raw "${comp_out:0:2000}" \
    --arg fn "$latest_fn" \
    '{
      schema_version: "stage9_acceptance_artifact_v1",
      project_id: ($pid | tonumber),
      generated_at: $ga,
      status: "not_ready",
      closure_ready: false,
      acceptance_authority: "fast_completion_report_embed",
      completion_report_parse_error: { exit_code: $crc, raw_head: $raw },
      completion_report: null,
      external_export_metadata: {
        latest_contextjson_filename: (if $fn == "" then null else $fn end),
        purpose: "viewer_export_informational_only",
        is_acceptance_authority: false
      }
    }'
  exit 3
fi

comp_json="$(printf '%s' "$comp_out" | jq -c .)"
rep_st="$(printf '%s' "$comp_json" | jq -r '.status // "not_ready"')"
ready="false"
[[ "$rep_st" == "ready_for_stage_transition" ]] && ready="true"

ga="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
jq -n \
  --arg sv "stage9_acceptance_artifact_v1" \
  --argjson pid "$project_id" \
  --arg ga "$ga" \
  --arg st "$rep_st" \
  --argjson cr "$ready" \
  --argjson crep "$comp_json" \
  --arg fn "$latest_fn" \
  '{
    schema_version: $sv,
    project_id: ($pid | tonumber),
    generated_at: $ga,
    status: $st,
    closure_ready: $cr,
    acceptance_authority: "fast_completion_report_embed",
    completion_report: $crep,
    external_export_metadata: {
      latest_contextjson_filename: (if $fn == "" then null else $fn end),
      purpose: "viewer_export_informational_only",
      is_acceptance_authority: false
    }
  }'

if [[ "$comp_rc" -eq 0 ]] && [[ "$rep_st" == "ready_for_stage_transition" ]]; then
  exit 0
fi
exit 3
