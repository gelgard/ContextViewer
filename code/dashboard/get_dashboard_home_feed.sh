#!/usr/bin/env bash
# AI Task 026: Stage 5 dashboard home feed (read-only; composes dashboard scripts).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST_FEED="${SCRIPT_DIR}/get_project_list_overview_feed.sh"
OVERVIEW_FEED="${SCRIPT_DIR}/get_project_overview_feed.sh"

usage() {
  cat <<'USAGE'
get_dashboard_home_feed.sh — unified home feed (summary + projects; optional selected overview)

Usage:
  get_dashboard_home_feed.sh
  get_dashboard_home_feed.sh --project-id <id>

No arguments:
  Loads the project list overview (get_project_list_overview_feed.sh) and prints one JSON
  object with generated_at, summary, projects, and selected_project_overview: null.

With --project-id:
  Same as above, plus selected_project_overview from get_project_overview_feed.sh for that id.

Stdout:
  One JSON object:
    generated_at                  (string, UTC ISO-8601)
    summary                       (object):
      total_projects
      projects_with_import_status     count of projects where latest_import_status is set
      projects_with_valid_snapshots   count of projects where total_valid_snapshots > 0
    projects                      (array) — same as list feed projects[]
    selected_project_overview     (object or null)

Environment:
  Same as get_project_list_overview_feed.sh / get_project_overview_feed.sh (PostgreSQL).

Dependencies: jq; child scripts require psql

Options:
  -h, --help          Show this help
  --project-id <id>   Include overview for this project (non-negative integer)
USAGE
}

# Parse CLI (allow any order; --help wins when seen)
project_id_opt=""
args=("$@")
i=0
while [[ $i -lt ${#args[@]} ]]; do
  a="${args[$i]}"
  case "$a" in
    -h|--help)
      usage
      exit 0
      ;;
    --project-id)
      next=$((i + 1))
      if [[ $next -ge ${#args[@]} ]]; then
        echo "error: --project-id requires a value" >&2
        exit 2
      fi
      if [[ -n "$project_id_opt" ]]; then
        echo "error: duplicate --project-id" >&2
        exit 2
      fi
      project_id_opt="${args[$next]}"
      i=$((next + 1))
      continue
      ;;
    *)
      echo "error: unknown argument: $a" >&2
      exit 2
      ;;
  esac
  i=$((i + 1))
done

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

if [[ ! -f "$LIST_FEED" ]]; then
  echo "error: missing script: $LIST_FEED" >&2
  exit 1
fi
if [[ ! -x "$LIST_FEED" ]]; then
  echo "error: not executable: $LIST_FEED" >&2
  exit 1
fi
if [[ ! -f "$OVERVIEW_FEED" ]]; then
  echo "error: missing script: $OVERVIEW_FEED" >&2
  exit 1
fi
if [[ ! -x "$OVERVIEW_FEED" ]]; then
  echo "error: not executable: $OVERVIEW_FEED" >&2
  exit 1
fi

list_json="$("$LIST_FEED")" || {
  echo "error: get_project_list_overview_feed.sh failed" >&2
  exit 3
}

if ! printf '%s\n' "$list_json" | jq -e . >/dev/null 2>&1; then
  echo "error: list feed stdout is not valid JSON" >&2
  exit 3
fi

selected_json='null'
if [[ -n "$project_id_opt" ]]; then
  if [[ ! "$project_id_opt" =~ ^[0-9]+$ ]]; then
    echo "error: --project-id must be a non-negative integer, got: $project_id_opt" >&2
    exit 1
  fi
  errf="$(mktemp)"
  set +e
  selected_json="$("$OVERVIEW_FEED" "$project_id_opt" 2>"$errf")"
  ov_rc=$?
  set -e
  err_body=""
  [[ -f "$errf" ]] && err_body="$(cat "$errf")"
  rm -f "$errf"
  if [[ "$ov_rc" -ne 0 ]]; then
    [[ -n "$err_body" ]] && printf '%s\n' "$err_body" >&2
    exit "$ov_rc"
  fi
  if ! printf '%s\n' "$selected_json" | jq -e . >/dev/null 2>&1; then
    echo "error: project overview stdout is not valid JSON" >&2
    exit 3
  fi
fi

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

jq -n \
  --arg ga "$generated_at" \
  --argjson list "$list_json" \
  --argjson sel "$selected_json" \
  '
  ($list) as $L
  | ($L.projects // []) as $projs
  | {
      generated_at: $ga,
      summary: {
        total_projects: $L.total_projects,
        projects_with_import_status:
          ([$projs[] | select(.latest_import_status != null)] | length),
        projects_with_valid_snapshots:
          (
            [$projs[]
              | select(
                  (.total_valid_snapshots | type) == "number"
                  and .total_valid_snapshots > 0
                )
            ]
            | length
          )
      },
      projects: $projs,
      selected_project_overview: $sel
    }
'
