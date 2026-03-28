#!/usr/bin/env bash
# AI Task 086: Stage 9 settings/profile contract bundle (read-only; existing feeds only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERVIEW="${SCRIPT_DIR}/../dashboard/get_project_overview_feed.sh"
IMPORT_STATUS="${SCRIPT_DIR}/../ingestion/get_project_import_status.sh"
LATEST_VALID="${SCRIPT_DIR}/../interpretation/get_latest_valid_snapshot_projection.sh"

usage() {
  cat <<'USAGE'
get_settings_profile_contract_bundle.sh — Stage 9 settings/profile contract bundle

Usage:
  get_settings_profile_contract_bundle.sh --project-id <id>

Runs (read-only):
  get_project_overview_feed.sh <id>
  get_project_import_status.sh <id>
  get_latest_valid_snapshot_projection.sh <id>

Stdout:
  One JSON object:
    project_id
    generated_at          (UTC ISO-8601)
    status                "ok" when assembly and consistency checks pass
    profile               identity + integration + snapshot context (no user prefs / feature flags)
    settings_surface_state  UX-safe readiness hints only
    data_sources          which scripts supplied each contract slice
    consistency_checks    cross-feed alignment booleans

No markdown inputs. Unknown project → child stderr + non-zero (typically exit 4 from overview).
Malformed child JSON or failed consistency → stderr + exit 3.

Environment:
  PostgreSQL via child scripts; optional project root .env.local when DB vars unset.

Dependencies: jq; children require psql

Options:
  -h, --help     Show this help
  --project-id <id>   Required. Non-negative integer; project row must exist.
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

for s in "$OVERVIEW" "$IMPORT_STATUS" "$LATEST_VALID"; do
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

ov_json="$(run_capture bash "$OVERVIEW" "$project_id")" || exit "$?"
im_json="$(run_capture bash "$IMPORT_STATUS" "$project_id")" || exit "$?"
lv_json="$(run_capture bash "$LATEST_VALID" "$project_id")" || exit "$?"

for label in ov_json im_json lv_json; do
  val="${!label}"
  if ! printf '%s\n' "$val" | jq -e . >/dev/null 2>&1; then
    echo "error: invalid JSON from child ($label)" >&2
    exit 3
  fi
done

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

bundle_json="$(jq -n \
  --arg ga "$generated_at" \
  --argjson pid "$project_id" \
  --argjson ov "$ov_json" \
  --argjson im "$im_json" \
  --argjson lv "$lv_json" \
  '
  ($pid | tonumber) as $pnum
  | ($ov.total_valid_snapshots // 0) as $tvs
  | (
      if $ov.latest_import_status == null then "never_imported"
      elif $ov.latest_import_status == "imported" then "imported"
      else "import_failed_or_partial" end
    ) as $ov_norm
  | {
      project_id: $pnum,
      generated_at: $ga,
      status: "ok",
      profile: {
        project_id: $ov.project_id,
        name: $ov.name,
        github_url: $ov.github_url,
        created_at: $ov.created_at,
        overview_generated_at: $ov.overview_generated_at,
        integration_status: $im.integration_status,
        overview_latest_import_status: $ov.latest_import_status,
        latest_import_time: $ov.latest_import_time,
        latest_import_log: $im.latest_import_log,
        latest_valid_snapshot_timestamp: $ov.latest_valid_snapshot_timestamp,
        total_valid_snapshots: $ov.total_valid_snapshots,
        latest_valid_snapshot_id: $lv.snapshot_id,
        latest_valid_projection_timestamp: $lv.snapshot_timestamp,
        total_snapshots_all_validity: $im.snapshot_count
      },
      settings_surface_state: {
        integration_never_run: ($im.integration_status == "never_imported"),
        has_valid_runtime_snapshots: ($tvs > 0),
        has_github_remote: (
          ($ov.github_url != null)
          and (($ov.github_url | tostring | length) > 0)
        ),
        latest_projection_present: ($lv.snapshot_id != null),
        user_preferences_in_contract: false,
        writable_product_settings_supported: false,
        hint: (
          if ($im.integration_status == "never_imported") then
            "No import has run yet; surface is identity and integration metadata only."
          elif ($tvs == 0) then
            "Imports may exist but there are no valid snapshots; runtime-backed views stay empty until valid contextJSON is stored."
          else
            "Valid snapshots exist; profile reflects DB-backed project and integration state only — no saved end-user preferences in this contract."
          end
        )
      },
      data_sources: [
        {
          script: "code/dashboard/get_project_overview_feed.sh",
          role: "project_identity_overview_aggregates"
        },
        {
          script: "code/ingestion/get_project_import_status.sh",
          role: "import_integration_logs_snapshot_totals"
        },
        {
          script: "code/interpretation/get_latest_valid_snapshot_projection.sh",
          role: "latest_valid_snapshot_row"
        }
      ],
      consistency_checks: {
        project_ids_aligned: (
          ($ov.project_id == $pnum)
          and ($im.project_id == $pnum)
          and ($lv.project_id == $pnum)
        ),
        overview_import_status_matches_integration_feed: ($ov_norm == $im.integration_status),
        latest_valid_timestamp_matches_overview: (
          (($ov.latest_valid_snapshot_timestamp == null) and ($lv.snapshot_timestamp == null))
          or ($ov.latest_valid_snapshot_timestamp == $lv.snapshot_timestamp)
        ),
        valid_snapshot_count_matches_projection_presence: (
          ($tvs == 0 and $lv.snapshot_id == null)
          or ($tvs > 0 and $lv.snapshot_id != null)
        )
      }
    }
  ')"

printf '%s\n' "$bundle_json"

ok="$(printf '%s' "$bundle_json" | jq -r '
  .consistency_checks
  | [
      .project_ids_aligned,
      .overview_import_status_matches_integration_feed,
      .latest_valid_timestamp_matches_overview,
      .valid_snapshot_count_matches_projection_presence
    ] | all
')"
[[ "$ok" == "true" ]] || exit 3
