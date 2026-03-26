#!/usr/bin/env bash
# AI Task 051: Stage 7 history home feed (read-only; list + optional selected history bundle).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIST_FEED="${SCRIPT_DIR}/../dashboard/get_project_list_overview_feed.sh"
BUNDLE_FEED="${SCRIPT_DIR}/get_project_history_bundle_feed.sh"

usage() {
  cat <<'USAGE'
get_history_home_feed.sh — unified history home feed (summary + projects; optional selected bundle)

Usage:
  get_history_home_feed.sh
  get_history_home_feed.sh --project-id <id>

No arguments:
  Loads the project list overview (get_project_list_overview_feed.sh) and prints one JSON
  object with generated_at, summary, projects, selected_project_history: null, and consistency_checks.

With --project-id:
  Same as above, plus selected_project_history from get_project_history_bundle_feed.sh for that id.

Stdout:
  One JSON object:
    generated_at                      (string, UTC ISO-8601)
    summary                           (object):
      total_projects
      projects_with_valid_snapshots     count of projects where total_valid_snapshots > 0
      projects_with_history_data        count of projects where latest_valid_snapshot_timestamp is not null
    projects                          (array) — same as list feed projects[]
    selected_project_history            (object or null) — full bundle feed output when selected
    consistency_checks:
      summary_total_matches_projects_length
      selected_project_id_match
      selected_history_consistent

Environment:
  Same as get_project_list_overview_feed.sh / get_project_history_bundle_feed.sh (PostgreSQL).

Dependencies: jq; child scripts require psql, python3

Options:
  -h, --help          Show this help
  --project-id <id>   Include history bundle for this project (non-negative integer)
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
if [[ ! -f "$BUNDLE_FEED" ]]; then
  echo "error: missing script: $BUNDLE_FEED" >&2
  exit 1
fi
if [[ ! -x "$BUNDLE_FEED" ]]; then
  echo "error: not executable: $BUNDLE_FEED" >&2
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
  selected_json="$(bash "$BUNDLE_FEED" --project-id "$project_id_opt" 2>"$errf")"
  bun_rc=$?
  set -e
  err_body=""
  [[ -f "$errf" ]] && err_body="$(cat "$errf")"
  rm -f "$errf"
  if [[ "$bun_rc" -ne 0 ]]; then
    [[ -n "$err_body" ]] && printf '%s\n' "$err_body" >&2
    exit "$bun_rc"
  fi
  if ! printf '%s\n' "$selected_json" | jq -e . >/dev/null 2>&1; then
    echo "error: history bundle feed stdout is not valid JSON" >&2
    exit 3
  fi
fi

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

req_json='null'
[[ -n "$project_id_opt" ]] && req_json="$project_id_opt"

result="$(
  jq -n \
    --arg ga "$generated_at" \
    --argjson list "$list_json" \
    --argjson sel "$selected_json" \
    --argjson requested "$req_json" \
    '
    ($list) as $L
    | ($L.projects // []) as $projs
    | {
        generated_at: $ga,
        summary: {
          total_projects: $L.total_projects,
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
          projects_with_history_data:
            ([$projs[] | select(.latest_valid_snapshot_timestamp != null)] | length)
        },
        projects: $projs,
        selected_project_history: $sel,
        consistency_checks: {
          summary_total_matches_projects_length: ($L.total_projects == ($projs | length)),
          selected_project_id_match: (
            if $requested == null then true
            else ($sel != null and ($sel | type == "object") and ($sel.project_id == ($requested | tonumber)))
            end
          ),
          selected_history_consistent: (
            if $requested == null then true
            else (
              $sel != null
              and ($sel | type == "object")
              and ($sel.consistency_checks | type == "object")
              and ($sel.consistency_checks.project_id_match == true)
              and ($sel.consistency_checks.range_match == true)
              and ($sel.consistency_checks.timeline_count_consistent == true)
              and ($sel.consistency_checks.latest_timestamp_aligned == true)
            )
            end
          )
        }
      }
    '
)"

if ! printf '%s\n' "$result" | jq -e '.consistency_checks | [.summary_total_matches_projects_length, .selected_project_id_match, .selected_history_consistent] | all' >/dev/null 2>&1; then
  echo "error: consistency checks failed" >&2
  printf '%s\n' "$result" | jq -c '.consistency_checks' >&2 || true
  exit 3
fi

printf '%s\n' "$result"
