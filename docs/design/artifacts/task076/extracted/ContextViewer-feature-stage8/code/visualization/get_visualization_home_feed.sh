#!/usr/bin/env bash
# AI Task 037: Stage 6 visualization home feed (read-only; list + optional selected visualization).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST_FEED="${SCRIPT_DIR}/../dashboard/get_project_list_overview_feed.sh"
VIS_FEED="${SCRIPT_DIR}/get_project_visualization_feed.sh"

usage() {
  cat <<'USAGE'
get_visualization_home_feed.sh — unified visualization home feed (summary + projects; optional selected payload)

Usage:
  get_visualization_home_feed.sh
  get_visualization_home_feed.sh --project-id <id>

No arguments:
  Loads the project list overview (get_project_list_overview_feed.sh) and prints one JSON
  object with generated_at, summary, projects, and selected_project_visualization: null.

With --project-id:
  Same as above, plus selected_project_visualization from get_project_visualization_feed.sh for that id.

Stdout:
  One JSON object:
    generated_at                      (string, UTC ISO-8601)
    summary                           (object):
      total_projects
      projects_with_import_status     count of projects where latest_import_status is set
      projects_with_valid_snapshots   count of projects where total_valid_snapshots > 0
      projects_with_visualization_data
                                    count of projects where latest_valid_snapshot_timestamp is not null
    projects                          (array) — same as list feed projects[]
    selected_project_visualization    (object or null)

Environment:
  Same as get_project_list_overview_feed.sh / get_project_visualization_feed.sh (PostgreSQL).

Dependencies: jq; child scripts require psql

Options:
  -h, --help          Show this help
  --project-id <id>   Include visualization feed for this project (non-negative integer)
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
if [[ ! -f "$VIS_FEED" ]]; then
  echo "error: missing script: $VIS_FEED" >&2
  exit 1
fi
if [[ ! -x "$VIS_FEED" ]]; then
  echo "error: not executable: $VIS_FEED" >&2
  exit 1
fi

# Reject non-numeric --project-id before any child calls (clear error; no DB required).
if [[ -n "$project_id_opt" && ! "$project_id_opt" =~ ^[0-9]+$ ]]; then
  echo "error: --project-id must be a non-negative integer, got: $project_id_opt" >&2
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
  errf="$(mktemp)"
  set +e
  selected_json="$("$VIS_FEED" "$project_id_opt" 2>"$errf")"
  vis_rc=$?
  set -e
  err_body=""
  [[ -f "$errf" ]] && err_body="$(cat "$errf")"
  rm -f "$errf"
  if [[ "$vis_rc" -ne 0 ]]; then
    [[ -n "$err_body" ]] && printf '%s\n' "$err_body" >&2
    exit "$vis_rc"
  fi
  if ! printf '%s\n' "$selected_json" | jq -e . >/dev/null 2>&1; then
    echo "error: project visualization feed stdout is not valid JSON" >&2
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
          ),
        projects_with_visualization_data:
          ([$projs[] | select(.latest_valid_snapshot_timestamp != null)] | length)
      },
      projects: $projs,
      selected_project_visualization: $sel
    }
'
