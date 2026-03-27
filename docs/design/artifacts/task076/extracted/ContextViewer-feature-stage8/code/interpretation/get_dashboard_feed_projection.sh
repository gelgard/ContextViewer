#!/usr/bin/env bash
# AI Task 022: dashboard-ready JSON feed from interpretation bundle (read-only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'USAGE'
get_dashboard_feed_projection.sh — normalized dashboard feed from interpretation bundle

Usage:
  get_dashboard_feed_projection.sh <project_id>

Runs get_interpretation_bundle_projection.sh (same directory) and maps its JSON into a
stable dashboard contract.

Stdout:
  One JSON object:
    project_id                    (number)
    generated_at                  (string, UTC — same as bundle bundle_generated_at)
    overview                      (object):
      latest_snapshot_timestamp   (string or null)
      total_valid_snapshots       (integer)
      diff_changed_keys_count     (integer) — length of diff changed_top_level_keys
      changes_count               (integer)
    roadmap                       (array)
    progress                      (object):
      implemented                 (array)
      in_progress                 (array)
      next                        (array)
    timeline                      (array) — snapshot timeline rows (not the full timeline script wrapper)

Missing or wrong-shaped fields use safe fallbacks (0, [], null as appropriate).

Environment:
  Same as get_interpretation_bundle_projection.sh (PostgreSQL; optional .env.local in child scripts).

Dependencies: jq; bundle requires psql via child scripts

Options:
  -h, --help     Show this help
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  echo "error: exactly one argument required: project_id" >&2
  usage >&2
  exit 2
fi

project_id="$1"
if [[ ! "$project_id" =~ ^[0-9]+$ ]]; then
  echo "error: project_id must be a non-negative integer, got: $project_id" >&2
  exit 1
fi

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

bundle_json="$("${SCRIPT_DIR}/get_interpretation_bundle_projection.sh" "$project_id")" || {
  echo "error: bundle projection failed" >&2
  exit 3
}

printf '%s\n' "$bundle_json" | jq '
  . as $b
  | ($b.project_id) as $pid
  | ($b.bundle_generated_at) as $gen
  | {
      project_id: $pid,
      generated_at: $gen,
      overview: {
        latest_snapshot_timestamp: (
          if ($b.latest_snapshot | type) == "object" then
            $b.latest_snapshot.snapshot_timestamp
          else
            null
          end
        ),
        total_valid_snapshots: (
          if ($b.timeline | type) == "object"
             and ($b.timeline.total_valid_snapshots | type) == "number" then
            $b.timeline.total_valid_snapshots
          else
            0
          end
        ),
        diff_changed_keys_count: (
          if ($b.diff_summary | type) == "object"
             and ($b.diff_summary.diff_summary | type) == "object"
             and ($b.diff_summary.diff_summary.changed_top_level_keys | type) == "array" then
            ($b.diff_summary.diff_summary.changed_top_level_keys | length)
          else
            0
          end
        ),
        changes_count: (
          if ($b.changes_projection | type) == "object"
             and ($b.changes_projection.changes_count | type) == "number" then
            $b.changes_projection.changes_count
          else
            0
          end
        )
      },
      roadmap: (
        if ($b.roadmap_progress | type) == "object"
           and ($b.roadmap_progress.roadmap | type) == "array" then
          $b.roadmap_progress.roadmap
        else
          []
        end
      ),
      progress: (
        def empty_prog:
          {implemented: [], in_progress: [], next: []};
        def from_cs($cs):
          if ($cs | type) != "object" then
            empty_prog
          else
            {
              implemented: (
                if ($cs.implemented | type) == "array" then $cs.implemented else [] end
              ),
              in_progress: (
                if ($cs.in_progress | type) == "array" then $cs.in_progress else [] end
              ),
              next: (
                if ($cs.next | type) == "array" then $cs.next else [] end
              )
            }
          end;
        def from_rp($rp):
          if ($rp | type) != "object" or ($rp.progress | type) != "object" then
            empty_prog
          else
            {
              implemented: (
                if ($rp.progress.implemented | type) == "array" then $rp.progress.implemented else [] end
              ),
              in_progress: (
                if ($rp.progress.in_progress | type) == "array" then $rp.progress.in_progress else [] end
              ),
              next: (
                if ($rp.progress.next | type) == "array" then $rp.progress.next else [] end
              )
            }
          end;
        if ($b.current_status | type) == "object"
           and ($b.current_status.current_status | type) == "object" then
          from_cs($b.current_status.current_status)
        else
          from_rp($b.roadmap_progress)
        end
      ),
      timeline: (
        if ($b.timeline | type) == "object"
           and ($b.timeline.timeline | type) == "array" then
          $b.timeline.timeline
        else
          []
        end
      )
    }
'
