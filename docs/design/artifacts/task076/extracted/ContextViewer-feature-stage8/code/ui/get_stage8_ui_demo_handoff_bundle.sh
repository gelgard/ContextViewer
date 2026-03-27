#!/usr/bin/env bash
# AI Task 060: Stage 8 UI demo handoff bundle (read-only; stdout = one JSON object).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREPARE="${SCRIPT_DIR}/prepare_ui_preview_launch.sh"
START_SERVER="${SCRIPT_DIR}/start_ui_preview_server.sh"
READINESS="${SCRIPT_DIR}/get_stage8_ui_preview_readiness_report.sh"

usage() {
  cat <<'USAGE'
get_stage8_ui_demo_handoff_bundle.sh — Stage 8 UI demo / investor handoff (single JSON bundle)

Usage:
  get_stage8_ui_demo_handoff_bundle.sh --project-id <id> [--port <n>] [--output-dir <path>] [--invalid-project-id <value>]

Runs (read-only against source data):
  prepare_ui_preview_launch.sh --project-id <id> --output-dir <path> --invalid-project-id <value>
  start_ui_preview_server.sh --project-id <id> --port <n> --output-dir <path> --invalid-project-id <value>
  get_stage8_ui_preview_readiness_report.sh --project-id <id> --port <n> --output-dir <path> --invalid-project-id <value>

Stdout:
  One JSON object:
    project_id
    generated_at (UTC)
    status                 ready | not_ready
    handoff                output_dir, output_file, file_open_command, server_url, preview_url,
                           browser_open_command, demo_steps
    readiness              full JSON from get_stage8_ui_preview_readiness_report.sh
    consistency_checks     project_id_match, output_file_matches_project, preview_url_matches_project,
                           readiness_ready, browser_open_command_matches_preview_url

Exit 0 only when status is ready. Exit 3 when JSON is assembled but status is not_ready or consistency fails.
Invalid CLI: stderr + non-zero (no JSON). prepare or server failure: propagated exit (no bundle JSON).
Malformed child JSON: stderr + exit 3.

Dependencies: jq; children require curl, python3, psql, etc.

Options:
  -h, --help                    Show this help
  --project-id <id>             Required. Non-negative integer.
  --port <n>                    Optional. Integer >= 1 (default: 8787)
  --output-dir <path>           Optional. Default: /tmp/contextviewer_ui_preview
  --invalid-project-id <value>  Optional. Passed to children (default: abc)
USAGE
}

project_id=""
port="8787"
output_dir="/tmp/contextviewer_ui_preview"
invalid_id="abc"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --project-id)
      if [[ -z "${2:-}" ]]; then
        echo "error: --project-id requires a value" >&2
        exit 2
      fi
      project_id="$2"
      shift 2
      ;;
    --port)
      if [[ -z "${2:-}" ]]; then
        echo "error: --port requires a value" >&2
        exit 2
      fi
      port="$2"
      shift 2
      ;;
    --output-dir)
      if [[ -z "${2:-}" ]]; then
        echo "error: --output-dir requires a value" >&2
        exit 2
      fi
      output_dir="$2"
      shift 2
      ;;
    --invalid-project-id)
      if [[ -z "${2:-}" ]]; then
        echo "error: --invalid-project-id requires a value" >&2
        exit 2
      fi
      invalid_id="$2"
      shift 2
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

if [[ -z "$project_id" ]]; then
  echo "error: --project-id is required" >&2
  usage >&2
  exit 2
fi

if [[ ! "$project_id" =~ ^[0-9]+$ ]]; then
  echo "error: --project-id must be a non-negative integer, got: $project_id" >&2
  exit 1
fi

if [[ ! "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]]; then
  echo "error: --port must be an integer >= 1, got: $port" >&2
  exit 1
fi

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

for s in "$PREPARE" "$START_SERVER" "$READINESS"; do
  if [[ ! -f "$s" || ! -x "$s" ]]; then
    echo "error: missing or not executable: $s" >&2
    exit 1
  fi
done

run_capture_strict() {
  local errf out rc
  errf="$(mktemp)"
  set +e
  out="$("$@" 2>"$errf")"
  rc=$?
  set -e
  if [[ "$rc" -ne 0 ]]; then
    [[ -s "$errf" ]] && cat "$errf" >&2
    rm -f "$errf"
    return "$rc"
  fi
  rm -f "$errf"
  printf '%s' "$out"
  return 0
}

run_capture_json_always() {
  local errf out rc
  errf="$(mktemp)"
  set +e
  out="$("$@" 2>"$errf")"
  rc=$?
  set -e
  [[ -s "$errf" ]] && cat "$errf" >&2
  rm -f "$errf"
  printf '%s' "$out"
  return "$rc"
}

prepare_json="$(run_capture_strict bash "$PREPARE" --project-id "$project_id" --output-dir "$output_dir" --invalid-project-id "$invalid_id")" || exit "$?"

if ! printf '%s\n' "$prepare_json" | jq -e . >/dev/null 2>&1; then
  echo "error: prepare_ui_preview_launch.sh stdout is not valid JSON" >&2
  exit 3
fi

server_json="$(run_capture_strict bash "$START_SERVER" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")" || exit "$?"

if ! printf '%s\n' "$server_json" | jq -e . >/dev/null 2>&1; then
  echo "error: start_ui_preview_server.sh stdout is not valid JSON" >&2
  exit 3
fi

readiness_json="$(run_capture_json_always bash "$READINESS" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"

if ! printf '%s\n' "$readiness_json" | jq -e . >/dev/null 2>&1; then
  echo "error: get_stage8_ui_preview_readiness_report.sh stdout is not valid JSON" >&2
  exit 3
fi

preview_url="$(printf '%s' "$server_json" | jq -r '.preview_url')"
browser_open="$(printf '%s' "$server_json" | jq -r '.open_command')"
expected_browser_open="$(printf 'open %q' "$preview_url")"
if [[ "$browser_open" == "$expected_browser_open" ]]; then
  browser_match_json="true"
else
  browser_match_json="false"
fi

demo_steps_json="$(jq -n '
  [
    "Open local preview URL in a browser (see handoff.preview_url).",
    "Confirm the overview section is visible (data-section=\"overview\").",
    "Confirm the visualization section is visible (data-section=\"visualization\").",
    "Confirm the history section is visible (data-section=\"history\")."
  ]
')"

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Last arg = jq program. Use --argjson for readiness + prep/srv. Parenthesize multi-line `and ... as $x`
# chains: otherwise jq binds `as` to the last conjunct and the program can collapse to boolean false.
report="$(jq -n \
  --argjson R "$readiness_json" \
  --argjson prepJ "$prepare_json" \
  --argjson srvJ "$server_json" \
  --argjson bok "$browser_match_json" \
  --argjson steps "$demo_steps_json" \
  --arg ga "$generated_at" \
  --argjson pidnum "$project_id" \
  --argjson port "$port" \
  "$(cat <<'JQINLINE'
($R.status == "ready") as $r_ok
| (($prepJ.open_command | type == "string") and ($prepJ.open_command | length) > 0) as $file_cmd_ok
| (($srvJ.open_command | type == "string") and ($srvJ.open_command | length) > 0) as $bcn
| (($srvJ.preview_url | type == "string") and ($srvJ.preview_url | contains("127.0.0.1"))) as $preview_host_ok
| (
    ($prepJ.project_id == ($pidnum | tonumber))
    and ($srvJ.project_id == ($pidnum | tonumber))
    and ($R.project_id == ($pidnum | tonumber))
  ) as $pid_match
| (
    ($prepJ.output_file == $srvJ.output_file)
    and ($prepJ.output_file | type == "string")
    and ($prepJ.output_file | endswith("contextviewer_ui_preview_\($pidnum).html"))
  ) as $of_match
| ($srvJ.preview_url == ("http://127.0.0.1:" + ($port | tostring) + "/contextviewer_ui_preview_" + ($pidnum | tostring) + ".html")) as $purl_match
| {
    project_id_match: $pid_match,
    output_file_matches_project: $of_match,
    preview_url_matches_project: $purl_match,
    readiness_ready: $r_ok,
    browser_open_command_matches_preview_url: ($bok and $bcn)
  } as $meta
| (if (
      $meta.project_id_match
      and $meta.output_file_matches_project
      and $meta.preview_url_matches_project
      and $meta["readiness_ready"]
      and $meta.browser_open_command_matches_preview_url
      and $file_cmd_ok
      and $bcn
      and $preview_host_ok
    ) then "ready" else "not_ready" end) as $st
| {
    project_id: ($pidnum | tonumber),
    generated_at: $ga,
    status: $st,
    handoff: {
      output_dir: $prepJ.output_dir,
      output_file: $prepJ.output_file,
      file_open_command: $prepJ.open_command,
      server_url: $srvJ.server_url,
      preview_url: $srvJ.preview_url,
      browser_open_command: $srvJ.open_command,
      demo_steps: $steps
    },
    "readiness": $R,
    consistency_checks: $meta
  }
JQINLINE
)")"

printf '%s\n' "$report"

ready="$(printf '%s' "$report" | jq -r '.status')"
[[ "$ready" == "ready" ]] || exit 3
