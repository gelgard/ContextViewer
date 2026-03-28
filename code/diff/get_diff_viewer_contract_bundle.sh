#!/usr/bin/env bash
# AI Task 084: Stage 9 diff viewer contract bundle (read-only DB + Stage 4 interpretation scripts).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
INTERP_DIR="${SCRIPT_DIR}/../interpretation"

LATEST_PROJ="${INTERP_DIR}/get_latest_valid_snapshot_projection.sh"
DIFF_SUM="${INTERP_DIR}/get_latest_snapshot_diff_summary.sh"
TIMELINE="${INTERP_DIR}/get_valid_snapshot_timeline_projection.sh"

usage() {
  cat <<'USAGE'
get_diff_viewer_contract_bundle.sh — Stage 9 diff viewer contract bundle

Usage:
  get_diff_viewer_contract_bundle.sh --project-id <id>

Runs (read-only):
  get_latest_valid_snapshot_projection.sh
  get_latest_snapshot_diff_summary.sh
  get_valid_snapshot_timeline_projection.sh
Optional: one extra SELECT for previous valid snapshot body when diff reports a previous id.

Stdout:
  One JSON object:
    project_id            (number)
    generated_at          (UTC ISO-8601)
    status                "ok" on successful assembly
    comparison_ready      (boolean) true iff two latest valid snapshots exist for diff
    latest_snapshot       { snapshot_id, snapshot_timestamp, projection }
    previous_snapshot     { snapshot_id, snapshot_timestamp, projection } — projection null when none
    diff_summary          Stage 4 top-level-key semantics:
                            added_top_level_keys, removed_top_level_keys, changed_top_level_keys (arrays)
    viewer_context        UX-safe hints (counts, viewer_state); no invented metrics
    consistency_checks    booleans aligning sources

Safe for 0 / 1 / 2+ valid snapshots (exit 0 when project id is valid format and DB reachable).

Environment:
  PostgreSQL via child scripts; optional project root .env.local when DB vars unset.

Dependencies: jq, psql; child scripts executable

Options:
  -h, --help     Show this help
USAGE
}

project_id=""

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
command -v psql >/dev/null 2>&1 || {
  echo "error: psql is required" >&2
  exit 127
}

for s in "$LATEST_PROJ" "$DIFF_SUM" "$TIMELINE"; do
  if [[ ! -f "$s" || ! -x "$s" ]]; then
    echo "error: missing or not executable: $s" >&2
    exit 1
  fi
done

run_capture() {
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

latest_json="$(run_capture bash "$LATEST_PROJ" "$project_id")" || exit "$?"
diff_json="$(run_capture bash "$DIFF_SUM" "$project_id")" || exit "$?"
timeline_json="$(run_capture bash "$TIMELINE" "$project_id")" || exit "$?"

for label in latest_json diff_json timeline_json; do
  val="${!label}"
  if ! printf '%s\n' "$val" | jq -e . >/dev/null 2>&1; then
    echo "error: invalid JSON from child ($label)" >&2
    exit 3
  fi
done

if [[ -f "${PROJECT_ROOT}/.env.local" && -z "${DATABASE_URL:-}" && -z "${PGHOST:-}" && -z "${PGDATABASE:-}" ]]; then
  # shellcheck disable=SC1090
  set -a
  source "${PROJECT_ROOT}/.env.local"
  set +a
fi

export PGCONNECT_TIMEOUT="${PGCONNECT_TIMEOUT:-10}"

PSQL_CMD=(psql)
if [[ -n "${DATABASE_URL:-}" ]]; then
  PSQL_CMD+=("$DATABASE_URL")
fi

prev_id_num="$(printf '%s' "$diff_json" | jq -r 'if .previous_snapshot_id == null then empty else .previous_snapshot_id | tonumber end')"

previous_snapshot_json=""
if [[ -n "$prev_id_num" ]]; then
  previous_snapshot_json="$("${PSQL_CMD[@]}" -v ON_ERROR_STOP=1 -q -t -A <<SQL
SELECT COALESCE(
  (
    SELECT json_build_object(
      'snapshot_id', s.id,
      'snapshot_timestamp',
        to_char(s."timestamp", 'YYYY-MM-DD"T"HH24:MI:SS"'),
      'projection', s.raw_json
    )
    FROM snapshots s
    WHERE s.project_id = ${project_id}::bigint
      AND s.id = ${prev_id_num}::bigint
      AND s.is_valid IS TRUE
  ),
  json_build_object('snapshot_id', NULL, 'snapshot_timestamp', NULL, 'projection', NULL)
)::text;
SQL
)" || {
    echo "error: database query failed (previous snapshot)" >&2
    exit 3
  }
  # If row missing but diff said there was a previous id, reattach id for viewer/debug
  previous_snapshot_json="$(printf '%s\n' "$previous_snapshot_json" | jq --argjson pid "$prev_id_num" '
    if .snapshot_id == null then . + {snapshot_id: $pid} else . end
  ')"
else
  previous_snapshot_json='{"snapshot_id":null,"snapshot_timestamp":null,"projection":null}'
fi

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

bundle_json="$(jq -n \
  --arg ga "$generated_at" \
  --argjson pid "$project_id" \
  --argjson latest "$latest_json" \
  --argjson diff "$diff_json" \
  --argjson tl "$timeline_json" \
  --argjson prev "$previous_snapshot_json" \
  '
  ($latest | {snapshot_id, snapshot_timestamp, projection}) as $Lnest
  | ($diff.diff_summary) as $ds
  | ($tl.total_valid_snapshots) as $tc
  | ($diff.latest_snapshot_id) as $dl
  | ($diff.previous_snapshot_id) as $dp
  | ($Lnest.snapshot_id) as $lsid
  | (($dp != null) and ($dl != null)) as $comp_ready
  | (
      if $tc == 0 then "empty"
      elif $tc == 1 then "single"
      else "comparable_pool"
      end
    ) as $vstate
  | {
      project_id: ($pid | tonumber),
      generated_at: $ga,
      status: "ok",
      comparison_ready: $comp_ready,
      latest_snapshot: $Lnest,
      previous_snapshot: (
        if $dp == null then
          { snapshot_id: null, snapshot_timestamp: null, projection: null }
        else
          {
            snapshot_id: ($prev.snapshot_id // $dp),
            snapshot_timestamp: $prev.snapshot_timestamp,
            projection: $prev.projection
          }
        end
      ),
      diff_summary: $ds,
      viewer_context: {
        valid_snapshots_count: $tc,
        viewer_state: $vstate,
        empty_state: ($tc == 0),
        single_snapshot_only: ($tc == 1),
        hint: (
          if $tc == 0 then
            "No valid snapshots; diff viewer has nothing to compare."
          elif $tc == 1 then
            "Only one valid snapshot; key-level diff arrays are empty until a second valid snapshot exists."
          elif $comp_ready then
            "Two or more valid snapshots; diff_summary reflects top-level key changes between the two newest."
          else
            "Unexpected comparison state; inspect diff_summary and timeline."
          end
        )
      },
      consistency_checks: {
        project_ids_aligned: (
          ($latest.project_id == ($pid | tonumber))
          and ($diff.project_id == ($pid | tonumber))
          and ($tl.project_id == ($pid | tonumber))
        ),
        diff_latest_matches_latest_projection: (
          (($dl == null) and ($lsid == null))
          or ($dl == $lsid)
        ),
        timeline_head_matches_diff_latest: (
          (($tl.timeline | type == "array")
            and (($tl.timeline | length) == 0)
            and ($dl == null))
          or (
            (($tl.timeline | length) > 0)
            and ($dl == $tl.timeline[0].snapshot_id)
          )
        ),
        diff_previous_matches_timeline_or_null: (
          ($dp == null)
          or (
            (($tl.timeline | length) > 1)
            and ($dp == $tl.timeline[1].snapshot_id)
          )
        ),
        diff_summary_is_stage4_shape: (
          ($ds | type == "object")
          and ($ds.added_top_level_keys | type == "array")
          and ($ds.removed_top_level_keys | type == "array")
          and ($ds.changed_top_level_keys | type == "array")
        ),
        previous_row_loaded_when_expected: (
          ($dp == null)
          or (
            ($prev.snapshot_id == $dp)
            and ($prev.snapshot_timestamp != null)
          )
        )
      }
    }
  ')"

printf '%s\n' "$bundle_json"

ok="$(printf '%s' "$bundle_json" | jq -r '
  .consistency_checks | [
    .project_ids_aligned,
    .diff_latest_matches_latest_projection,
    .timeline_head_matches_diff_latest,
    .diff_previous_matches_timeline_or_null,
    .diff_summary_is_stage4_shape,
    .previous_row_loaded_when_expected
  ] | all
')"
[[ "$ok" == "true" ]] || exit 3
