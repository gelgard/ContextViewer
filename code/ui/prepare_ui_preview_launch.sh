#!/usr/bin/env bash
# AI Task 056: Stage 8 UI preview launcher — render HTML + emit open command metadata (stdout JSON).
# AI Task 080: unchanged contract; child render emits `render_profile: 080_shell_tokens` + production shell HTML.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RENDER="${SCRIPT_DIR}/render_ui_bootstrap_preview.sh"

usage() {
  cat <<'USAGE'
prepare_ui_preview_launch.sh — generate UI preview HTML and print launch metadata (JSON)

Usage:
  prepare_ui_preview_launch.sh --project-id <id> [--output-dir <path>] [--invalid-project-id <value>]

Calls render_ui_bootstrap_preview.sh with a deterministic filename under --output-dir:
  contextviewer_ui_preview_<project-id>.html

Stdout (exactly one JSON object):
  project_id
  generated_at
  output_dir          (absolute path)
  output_file           (absolute path to the HTML file)
  open_command          plain shell string: open <absolute-path> (macOS)
  preview_summary:
    sections_rendered
    source_consistency_checks
    (optional) render_profile from child — e.g. 080_shell_tokens

Missing/non-numeric --project-id: stderr + non-zero exit.
Output directory creation failure or unresolvable path: stderr + exit 3.
Child failure: propagated exit.
Invalid JSON from child: stderr + exit 3.

Environment:
  Same as render_ui_bootstrap_preview.sh (PostgreSQL via bootstrap chain).

Dependencies: jq; render script requires python3 and get_ui_bootstrap_bundle.sh

Options:
  -h, --help                    Show this help
  --project-id <id>             Required. Non-negative integer; project must exist.
  --output-dir <path>           Optional. Default: /tmp/contextviewer_ui_preview
  --invalid-project-id <value>  Optional. Passed to render (default: abc)
USAGE
}

project_id=""
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

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

if [[ ! -f "$RENDER" || ! -x "$RENDER" ]]; then
  echo "error: missing or not executable: $RENDER" >&2
  exit 1
fi

if ! mkdir -p "$output_dir"; then
  echo "error: could not create output directory: $output_dir" >&2
  exit 3
fi

output_dir_abs="$(cd "$output_dir" && pwd)" || {
  echo "error: could not resolve output directory: $output_dir" >&2
  exit 3
}

out_file="${output_dir_abs}/contextviewer_ui_preview_${project_id}.html"

errf="$(mktemp)"
set +e
render_out="$(bash "$RENDER" --project-id "$project_id" --output "$out_file" --invalid-project-id "$invalid_id" 2>"$errf")"
render_rc=$?
set -e
if [[ "$render_rc" -ne 0 ]]; then
  [[ -s "$errf" ]] && cat "$errf" >&2
  rm -f "$errf"
  exit "$render_rc"
fi
rm -f "$errf"

if ! printf '%s\n' "$render_out" | jq -e . >/dev/null 2>&1; then
  echo "error: render script stdout is not valid JSON" >&2
  exit 3
fi

# macOS: `open <path>`; quote path safely for the emitted command string
open_command="$(printf 'open %q' "$out_file")"

jq -n \
  --argjson r "$render_out" \
  --arg od "$output_dir_abs" \
  --arg of "$out_file" \
  --arg oc "$open_command" \
  '
  {
    project_id: $r.project_id,
    generated_at: $r.generated_at,
    output_dir: $od,
    output_file: $of,
    open_command: $oc,
    preview_summary: {
      sections_rendered: $r.sections_rendered,
      source_consistency_checks: $r.source_consistency_checks,
      render_profile: ($r.render_profile // null)
    }
  }
  '
