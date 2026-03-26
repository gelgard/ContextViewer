#!/usr/bin/env bash
# AI Task 057: Stage 8 local HTTP preview — prepare HTML + background http.server + metadata JSON.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREPARE="${SCRIPT_DIR}/prepare_ui_preview_launch.sh"

usage() {
  cat <<'USAGE'
start_ui_preview_server.sh — generate preview HTML and start python3 http.server on --output-dir

Usage:
  start_ui_preview_server.sh --project-id <id> [--port <n>] [--output-dir <path>] [--invalid-project-id <value>]

Calls prepare_ui_preview_launch.sh, then starts a local HTTP server (python3 -m http.server) rooted
at the output directory (background, via nohup). Prints exactly one JSON object with URLs and commands.

Stdout JSON:
  project_id
  generated_at
  output_dir
  output_file
  server_url            http://127.0.0.1:<port>/
  preview_url           http://127.0.0.1:<port>/contextviewer_ui_preview_<id>.html
  server_command        exact command used to start the server
  open_command          open <preview_url> (macOS)

Missing/non-numeric --project-id: stderr + non-zero exit.
Invalid --port (<1 or non-integer): stderr + non-zero exit.
Prepare failure: propagated exit.
Server start / readiness failure: stderr + exit 3.

Dependencies: jq, python3, curl (readiness check); prepare script chains to DB

Options:
  -h, --help                    Show this help
  --project-id <id>             Required. Non-negative integer.
  --port <n>                    Optional. Integer >= 1 (default: 8787)
  --output-dir <path>           Optional. Default: /tmp/contextviewer_ui_preview
  --invalid-project-id <value>  Optional. Passed to prepare (default: abc)
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
command -v python3 >/dev/null 2>&1 || {
  echo "error: python3 is required" >&2
  exit 127
}
command -v curl >/dev/null 2>&1 || {
  echo "error: curl is required" >&2
  exit 127
}

if [[ ! -f "$PREPARE" || ! -x "$PREPARE" ]]; then
  echo "error: missing or not executable: $PREPARE" >&2
  exit 1
fi

errf="$(mktemp)"
set +e
prepare_out="$(bash "$PREPARE" --project-id "$project_id" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>"$errf")"
prep_rc=$?
set -e
if [[ "$prep_rc" -ne 0 ]]; then
  [[ -s "$errf" ]] && cat "$errf" >&2
  rm -f "$errf"
  exit "$prep_rc"
fi
rm -f "$errf"

if ! printf '%s\n' "$prepare_out" | jq -e . >/dev/null 2>&1; then
  echo "error: prepare_ui_preview_launch.sh stdout is not valid JSON" >&2
  exit 3
fi

out_dir_abs="$(printf '%s' "$prepare_out" | jq -r '.output_dir')"
out_file_abs="$(printf '%s' "$prepare_out" | jq -r '.output_file')"

if [[ ! -f "$out_file_abs" ]]; then
  echo "error: preview HTML not found at expected path: $out_file_abs" >&2
  exit 3
fi

preview_name="contextviewer_ui_preview_${project_id}.html"
preview_url="http://127.0.0.1:${port}/${preview_name}"
server_url="http://127.0.0.1:${port}/"

# Prefer python3 -m http.server --directory (Python 3.7+) so server_command is a single reproducible line.
use_directory=false
if python3 -m http.server --help 2>&1 | grep -q '\-\-directory'; then
  use_directory=true
fi

srv_log="$(mktemp)"
set +e
if [[ "$use_directory" == true ]]; then
  server_command="$(printf 'nohup python3 -m http.server %q --directory %q </dev/null >/dev/null 2>&1 &' "$port" "$out_dir_abs")"
  nohup python3 -m http.server "$port" --directory "$out_dir_abs" </dev/null >"$srv_log" 2>&1 &
  srv_pid=$!
else
  inner="$(printf 'cd %q && exec python3 -m http.server %q' "$out_dir_abs" "$port")"
  server_command="$(printf 'nohup bash -c %q </dev/null >/dev/null 2>&1 &' "$inner")"
  nohup bash -c "$inner" </dev/null >"$srv_log" 2>&1 &
  srv_pid=$!
fi
set -e

ready=0
for _ in $(seq 1 80); do
  if kill -0 "$srv_pid" 2>/dev/null; then
    code="$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 1 "$preview_url" 2>/dev/null || true)"
    if [[ "$code" == "200" ]]; then
      ready=1
      break
    fi
  else
    break
  fi
  sleep 0.1
done

if [[ "$ready" -ne 1 ]]; then
  echo "error: HTTP server did not become ready for ${preview_url}" >&2
  if [[ -s "$srv_log" ]]; then
    echo "error: server log:" >&2
    cat "$srv_log" >&2
  fi
  rm -f "$srv_log"
  kill "$srv_pid" 2>/dev/null || true
  exit 3
fi
rm -f "$srv_log"

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

open_command="$(printf 'open %q' "$preview_url")"

jq -n \
  --argjson pid "$project_id" \
  --arg ga "$generated_at" \
  --arg od "$out_dir_abs" \
  --arg of "$out_file_abs" \
  --arg su "$server_url" \
  --arg pu "$preview_url" \
  --arg sc "$server_command" \
  --arg oc "$open_command" \
  '{
    project_id: ($pid | tonumber),
    generated_at: $ga,
    output_dir: $od,
    output_file: $of,
    server_url: $su,
    preview_url: $pu,
    server_command: $sc,
    open_command: $oc
  }'
