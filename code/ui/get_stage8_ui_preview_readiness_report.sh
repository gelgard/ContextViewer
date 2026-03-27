#!/usr/bin/env bash
# AI Task 059: Stage 8 UI preview readiness report (read-only; stdout = one JSON object).
# AI Task 080: delivery smoke gains production shell marker check; readiness still gates on full delivery pass.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREPARE="${SCRIPT_DIR}/prepare_ui_preview_launch.sh"
BOOTSTRAP_VERIFY="${SCRIPT_DIR}/verify_stage8_ui_bootstrap_contracts.sh"
DELIVERY_VERIFY="${SCRIPT_DIR}/verify_stage8_ui_preview_delivery.sh"

usage() {
  cat <<'USAGE'
get_stage8_ui_preview_readiness_report.sh — Stage 8 UI preview readiness (demo / investor go/no-go)

Usage:
  get_stage8_ui_preview_readiness_report.sh --project-id <id> [--port <n>] [--output-dir <path>] [--invalid-project-id <value>]

Runs (read-only against source data):
  prepare_ui_preview_launch.sh --project-id <id> --output-dir <path> --invalid-project-id <value>
  verify_stage8_ui_bootstrap_contracts.sh --project-id <id> --invalid-project-id <value>
  verify_stage8_ui_preview_delivery.sh --project-id <id> --port <n> --output-dir <path> --invalid-project-id <value>

Stdout:
  One JSON object:
    project_id
    generated_at (UTC ISO-8601)
    status                 ready | not_ready
    preview_artifacts      output_dir, output_file, open_command (from prepare)
    verification:
      bootstrap_smoke      full JSON from verify_stage8_ui_bootstrap_contracts.sh
      delivery_smoke       full JSON from verify_stage8_ui_preview_delivery.sh
    readiness_summary      overview_available, visualization_available, history_available,
                           preview_launch_ready, local_delivery_ready, investor_demo_ready
    consistency_checks     project_id_match, artifact_matches_project, bootstrap_pass,
                           delivery_pass, all_ready_flags_true

Exit 0 only when status is ready. Exit 3 when JSON is assembled but status is not_ready or consistency checks fail.
Invalid CLI: stderr + non-zero (no JSON). prepare failure: propagated exit (no JSON). Malformed child JSON: stderr + exit 3.

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

for s in "$PREPARE" "$BOOTSTRAP_VERIFY" "$DELIVERY_VERIFY"; do
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

bootstrap_json="$(run_capture_json_always bash "$BOOTSTRAP_VERIFY" --project-id "$project_id" --invalid-project-id "$invalid_id")"

delivery_json="$(run_capture_json_always bash "$DELIVERY_VERIFY" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"

if ! printf '%s\n' "$bootstrap_json" | jq -e . >/dev/null 2>&1; then
  echo "error: invalid JSON from verify_stage8_ui_bootstrap_contracts.sh" >&2
  exit 3
fi

if ! printf '%s\n' "$delivery_json" | jq -e . >/dev/null 2>&1; then
  echo "error: invalid JSON from verify_stage8_ui_preview_delivery.sh" >&2
  exit 3
fi

output_file="$(printf '%s' "$prepare_json" | jq -r '.output_file')"
artifact_exists="false"
if [[ -n "$output_file" && -f "$output_file" ]]; then
  artifact_exists="true"
fi

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

report="$(jq -n \
  --arg ga "$generated_at" \
  --argjson pid "$project_id" \
  --argjson prep "$prepare_json" \
  --argjson boot "$bootstrap_json" \
  --argjson del "$delivery_json" \
  --argjson art_ex "$artifact_exists" \
  '
  def check_name_pass($smoke; $n):
    (($smoke.checks // []) | map(select(.name == $n)) | .[0].status // "fail") == "pass";

  def sections_has($arr; $k):
    (($arr | type) == "array") and (($arr | index($k)) != null);

  ($prep.project_id) as $ppid
  | ($ppid == ($pid | tonumber)) as $pid_ok
  | ($boot.status == "pass") as $boot_pass
  | ($del.status == "pass") as $del_pass
  | $art_ex as $file_ok
  | check_name_pass($boot; "bootstrap: ui_sections.overview") as $ov
  | check_name_pass($boot; "bootstrap: ui_sections.visualization_workspace") as $viz
  | check_name_pass($boot; "bootstrap: ui_sections.history_workspace") as $hist
  | (($prep.preview_summary // empty).sections_rendered // []) as $sr
  | ($ov and sections_has($sr; "overview")) as $ov_a
  | ($viz and sections_has($sr; "visualization")) as $viz_a
  | ($hist and sections_has($sr; "history")) as $hist_a
  | (($prep.open_command | type == "string") and ($prep.open_command | startswith("open "))) as $open_ok
  | ($file_ok and ($prep.output_file | type == "string")
     and ($prep.output_file | endswith("contextviewer_ui_preview_\($pid).html"))) as $art_match
  | check_name_pass($del; "delivery: preview_url matches expected") as $url_ok
  | ($pid_ok and $url_ok) as $proj_match
  | {
      overview_available: ($ov_a and $boot_pass),
      visualization_available: ($viz_a and $boot_pass),
      history_available: ($hist_a and $boot_pass),
      preview_launch_ready: ($file_ok and $art_match and $open_ok),
      local_delivery_ready: $del_pass,
      investor_demo_ready: (
        ($ov_a and $boot_pass)
        and ($viz_a and $boot_pass)
        and ($hist_a and $boot_pass)
        and $file_ok
        and $art_match
        and $del_pass
      )
    } as $rs
  | ($rs | [.overview_available, .visualization_available, .history_available,
            .preview_launch_ready, .local_delivery_ready, .investor_demo_ready] | all) as $all_flags
  | {
      project_id_match: $proj_match,
      artifact_matches_project: ($art_match and $file_ok),
      bootstrap_pass: $boot_pass,
      delivery_pass: $del_pass,
      all_ready_flags_true: $all_flags
    } as $cc
  | (if (
        $cc.project_id_match
        and $cc.artifact_matches_project
        and $cc.bootstrap_pass
        and $cc.delivery_pass
        and $cc.all_ready_flags_true
      ) then "ready" else "not_ready" end) as $st
  | {
      project_id: ($pid | tonumber),
      generated_at: $ga,
      status: $st,
      preview_artifacts: {
        output_dir: $prep.output_dir,
        output_file: $prep.output_file,
        open_command: $prep.open_command
      },
      verification: {
        bootstrap_smoke: $boot,
        delivery_smoke: $del
      },
      readiness_summary: $rs,
      consistency_checks: $cc
    }
  ')"

printf '%s\n' "$report"

ready="$(printf '%s' "$report" | jq -r '.status')"
[[ "$ready" == "ready" ]] || exit 3
