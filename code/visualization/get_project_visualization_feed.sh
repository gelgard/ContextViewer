#!/usr/bin/env bash
# AI Task 036: Stage 6 project visualization feed (overview + visualization API bundle).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OVERVIEW="${SCRIPT_DIR}/../dashboard/get_project_overview_feed.sh"
VIS_BUNDLE="${SCRIPT_DIR}/get_visualization_api_contract_bundle.sh"

usage() {
  cat <<'USAGE'
get_project_visualization_feed.sh — project overview plus Stage 6 visualization API bundle

Usage:
  get_project_visualization_feed.sh <project_id>

Runs (read-only):
  code/dashboard/get_project_overview_feed.sh <project_id>
  code/visualization/get_visualization_api_contract_bundle.sh --project-id <project_id>

Stdout:
  One JSON object:
    generated_at         (UTC ISO-8601 — when this aggregate was built)
    project_overview     — full output of get_project_overview_feed.sh
    visualization        — full output of get_visualization_api_contract_bundle.sh
    consistency_checks:
      project_id_match   — project_overview.project_id == visualization.contracts.architecture_tree.project_id
      snapshot_alignment — architecture_tree.snapshot_id == architecture_graph.snapshot_id
      smoke_status_pass  — visualization.contracts.visualization_contract_smoke.status == "pass"

Invalid or non-numeric project_id: stderr + non-zero exit.
Missing project: stderr from child + non-zero exit.

Environment:
  PostgreSQL via child scripts; optional project root .env.local when DB vars unset.

Dependencies: jq; child scripts require psql

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

if [[ ! -f "$OVERVIEW" || ! -x "$OVERVIEW" ]]; then
  echo "error: missing or not executable: $OVERVIEW" >&2
  exit 1
fi
if [[ ! -f "$VIS_BUNDLE" || ! -x "$VIS_BUNDLE" ]]; then
  echo "error: missing or not executable: $VIS_BUNDLE" >&2
  exit 1
fi

err_ov="$(mktemp)"
set +e
overview_json="$("$OVERVIEW" "$project_id" 2>"$err_ov")"
ov_rc=$?
set -e
if [[ "$ov_rc" -ne 0 ]]; then
  [[ -s "$err_ov" ]] && cat "$err_ov" >&2
  rm -f "$err_ov"
  exit "$ov_rc"
fi
rm -f "$err_ov"

if ! printf '%s\n' "$overview_json" | jq -e . >/dev/null 2>&1; then
  echo "error: project overview stdout is not valid JSON" >&2
  exit 3
fi

err_vb="$(mktemp)"
set +e
visualization_json="$("$VIS_BUNDLE" --project-id "$project_id" 2>"$err_vb")"
vb_rc=$?
set -e
if [[ "$vb_rc" -ne 0 ]]; then
  [[ -s "$err_vb" ]] && cat "$err_vb" >&2
  rm -f "$err_vb"
  exit "$vb_rc"
fi
rm -f "$err_vb"

if ! printf '%s\n' "$visualization_json" | jq -e . >/dev/null 2>&1; then
  echo "error: visualization bundle stdout is not valid JSON" >&2
  exit 3
fi

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

jq -n \
  --arg ga "$generated_at" \
  --argjson ov "$overview_json" \
  --argjson vz "$visualization_json" \
  '
  {
    generated_at: $ga,
    project_overview: $ov,
    visualization: $vz,
    consistency_checks: {
      project_id_match: (
        ($ov.project_id | tostring) == ($vz.contracts.architecture_tree.project_id | tostring)
      ),
      snapshot_alignment: (
        ($vz.contracts.architecture_tree.snapshot_id == $vz.contracts.architecture_graph.snapshot_id)
      ),
      smoke_status_pass: ($vz.contracts.visualization_contract_smoke.status == "pass")
    }
  }
  '
