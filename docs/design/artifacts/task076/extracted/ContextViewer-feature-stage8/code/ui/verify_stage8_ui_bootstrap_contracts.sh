#!/usr/bin/env bash
# AI Task 054: Stage 8 UI bootstrap JSON contract smoke suite (stdout = one JSON report).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP="${SCRIPT_DIR}/get_ui_bootstrap_bundle.sh"

usage() {
  cat <<'USAGE'
verify_stage8_ui_bootstrap_contracts.sh — Stage 8 UI bootstrap JSON contract smoke tests

Runs contract checks against get_ui_bootstrap_bundle.sh and prints exactly one JSON object:
  status        pass | fail (fail if any check fails)
  checks        array of { name, status, details }
  failed_checks integer count of failed checks
  generated_at  UTC ISO-8601

Required:
  --project-id <id>   non-negative integer; must exist in DB for positive checks to pass

Optional:
  --invalid-project-id <value>   string used for negative exit-code checks on bootstrap (default: abc)

Invalid top-level --project-id (not a non-negative integer):
  stdout only: JSON with status fail, failed_checks 1, check name "project_id"; exit 1.

Missing --project-id on this script: stderr + exit 2 (no JSON).

Prerequisites:
  jq; get_ui_bootstrap_bundle.sh requires psql, python3

No ingestion, network beyond DB, or background work.

Usage:
  verify_stage8_ui_bootstrap_contracts.sh --project-id <id>
  verify_stage8_ui_bootstrap_contracts.sh --project-id <id> --invalid-project-id <value>

Options:
  -h, --help     Show this help
USAGE
}

project_id=""
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
  generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  jq -n \
    --arg ga "$generated_at" \
    '{
      status: "fail",
      checks: [{
        name: "project_id",
        status: "fail",
        details: "--project-id must be a non-negative integer"
      }],
      failed_checks: 1,
      generated_at: $ga
    }'
  exit 1
fi

command -v jq >/dev/null 2>&1 || {
  echo "error: jq is required" >&2
  exit 127
}

if [[ ! -f "$BOOTSTRAP" || ! -x "$BOOTSTRAP" ]]; then
  echo "error: missing or not executable: $BOOTSTRAP" >&2
  exit 1
fi

checks='[]'

add_check() {
  local n="$1" s="$2" d="$3"
  checks="$(jq -n \
    --argjson c "$checks" \
    --arg n "$n" \
    --arg st "$s" \
    --arg det "$d" \
    '$c + [{name: $n, status: $st, details: $det}]')"
}

generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# --- positive: bootstrap bundle ---
errf="$(mktemp)"
set +e
boot_out="$(bash "$BOOTSTRAP" --project-id "$project_id" --invalid-project-id "$invalid_id" 2>"$errf")"
boot_rc=$?
set -e
es="$(cat "$errf" 2>/dev/null || true)"
rm -f "$errf"

if [[ "$boot_rc" -ne 0 ]]; then
  add_check "bootstrap: exit 0" "fail" "exit ${boot_rc}: ${es:0:500}"
else
  add_check "bootstrap: exit 0" "pass" "exit 0"
fi

if [[ "$boot_rc" -eq 0 ]] && printf '%s\n' "$boot_out" | jq -e . >/dev/null 2>&1; then
  if ! printf '%s\n' "$boot_out" | jq -e '(.project_id | type == "number")' >/dev/null 2>&1; then
    add_check "bootstrap: project_id shape" "fail" "project_id missing or not a number"
  else
    add_check "bootstrap: project_id shape" "pass" "number field present"
  fi

  if ! printf '%s\n' "$boot_out" | jq -e '(.generated_at | type == "string")' >/dev/null 2>&1; then
    add_check "bootstrap: generated_at shape" "fail" "generated_at missing or not a string"
  else
    add_check "bootstrap: generated_at shape" "pass" "string field present"
  fi

  if ! printf '%s\n' "$boot_out" | jq -e '
      (.ui_sections.overview | type == "object")
      and (.ui_sections.overview | has("project_overview"))
      and (.ui_sections.overview | has("dashboard_feed"))
    ' >/dev/null 2>&1; then
    add_check "bootstrap: ui_sections.overview" "fail" "expected project_overview and dashboard_feed"
  else
    add_check "bootstrap: ui_sections.overview" "pass" "overview payload shape OK (PG-OV-001)"
  fi

  if ! printf '%s\n' "$boot_out" | jq -e '
      (.ui_sections.visualization_workspace | type == "object")
      and (.ui_sections.visualization_workspace | has("contracts"))
      and (.ui_sections.visualization_workspace | has("consistency_checks"))
    ' >/dev/null 2>&1; then
    add_check "bootstrap: ui_sections.visualization_workspace" "fail" "expected contracts + consistency_checks"
  else
    add_check "bootstrap: ui_sections.visualization_workspace" "pass" "visualization workspace payload OK (PG-AR-001/002)"
  fi

  if ! printf '%s\n' "$boot_out" | jq -e '
      (.ui_sections.history_workspace | type == "object")
      and (.ui_sections.history_workspace | has("contracts"))
      and (.ui_sections.history_workspace | has("consistency_checks"))
    ' >/dev/null 2>&1; then
    add_check "bootstrap: ui_sections.history_workspace" "fail" "expected contracts + consistency_checks"
  else
    add_check "bootstrap: ui_sections.history_workspace" "pass" "history workspace payload OK (PG-HI-001/002)"
  fi

  for ck in project_id_match overview_present visualization_consistent history_consistent; do
    if ! printf '%s\n' "$boot_out" | jq -e --arg k "$ck" '(.consistency_checks[$k] | type == "boolean")' >/dev/null 2>&1; then
      add_check "bootstrap: consistency_checks.$ck" "fail" "missing or not boolean"
    else
      add_check "bootstrap: consistency_checks.$ck" "pass" "boolean field present"
    fi
  done

  if ! printf '%s\n' "$boot_out" | jq -e '
      (.consistency_checks.project_id_match == true)
      and (.consistency_checks.overview_present == true)
      and (.consistency_checks.visualization_consistent == true)
      and (.consistency_checks.history_consistent == true)
    ' >/dev/null 2>&1; then
    add_check "bootstrap: all consistency_checks true" "fail" "one or more consistency flags false"
  else
    add_check "bootstrap: all consistency_checks true" "pass" "all four true (PG-UX-001 single payload)"
  fi
else
  if [[ "$boot_rc" -eq 0 ]]; then
    add_check "bootstrap: project_id shape" "fail" "stdout is not valid JSON"
    add_check "bootstrap: generated_at shape" "fail" "skipped: invalid JSON"
    add_check "bootstrap: ui_sections.overview" "fail" "skipped: invalid JSON"
    add_check "bootstrap: ui_sections.visualization_workspace" "fail" "skipped: invalid JSON"
    add_check "bootstrap: ui_sections.history_workspace" "fail" "skipped: invalid JSON"
    add_check "bootstrap: consistency_checks.project_id_match" "fail" "skipped: invalid JSON"
    add_check "bootstrap: consistency_checks.overview_present" "fail" "skipped: invalid JSON"
    add_check "bootstrap: consistency_checks.visualization_consistent" "fail" "skipped: invalid JSON"
    add_check "bootstrap: consistency_checks.history_consistent" "fail" "skipped: invalid JSON"
    add_check "bootstrap: all consistency_checks true" "fail" "skipped: invalid JSON"
  else
    det="skipped: bootstrap exited ${boot_rc}"
    add_check "bootstrap: project_id shape" "fail" "$det"
    add_check "bootstrap: generated_at shape" "fail" "$det"
    add_check "bootstrap: ui_sections.overview" "fail" "$det"
    add_check "bootstrap: ui_sections.visualization_workspace" "fail" "$det"
    add_check "bootstrap: ui_sections.history_workspace" "fail" "$det"
    add_check "bootstrap: consistency_checks.project_id_match" "fail" "$det"
    add_check "bootstrap: consistency_checks.overview_present" "fail" "$det"
    add_check "bootstrap: consistency_checks.visualization_consistent" "fail" "$det"
    add_check "bootstrap: consistency_checks.history_consistent" "fail" "$det"
    add_check "bootstrap: all consistency_checks true" "fail" "$det"
  fi
fi

# --- negative: bootstrap without --project-id (expect exit 2) ---
run_negative_expect_2() {
  local name="$1"
  shift
  local errf out rc
  errf="$(mktemp)"
  set +e
  out="$("$@" 2>"$errf")"
  rc=$?
  set -e
  rm -f "$errf"
  if [[ "$rc" -eq 2 ]]; then
    add_check "$name" "pass" "exit 2 as expected (missing --project-id)"
  elif [[ "$rc" -eq 0 ]]; then
    add_check "$name" "fail" "expected exit 2, got 0; stdout: ${out:0:200}"
  else
    add_check "$name" "fail" "expected exit 2 for missing --project-id, got ${rc}"
  fi
}

run_negative_expect_1() {
  local name="$1"
  shift
  local errf out rc
  errf="$(mktemp)"
  set +e
  out="$("$@" 2>"$errf")"
  rc=$?
  set -e
  rm -f "$errf"
  if [[ "$rc" -eq 1 ]]; then
    add_check "$name" "pass" "exit 1 as expected for invalid --project-id"
  elif [[ "$rc" -eq 0 ]]; then
    add_check "$name" "fail" "expected exit 1, got 0; stdout: ${out:0:200}"
  else
    add_check "$name" "fail" "expected exit 1 for invalid --project-id, got ${rc}"
  fi
}

run_negative_expect_2 "negative: bootstrap missing --project-id" bash "$BOOTSTRAP"
run_negative_expect_1 "negative: bootstrap invalid --project-id" bash "$BOOTSTRAP" --project-id "$invalid_id"

failed_checks="$(echo "$checks" | jq '[.[] | select(.status == "fail")] | length')"
overall="pass"
[[ "$failed_checks" -eq 0 ]] || overall="fail"

jq -n \
  --arg st "$overall" \
  --argjson checks "$checks" \
  --argjson fc "$failed_checks" \
  --arg ga "$generated_at" \
  '{status: $st, checks: $checks, failed_checks: $fc, generated_at: $ga}'

[[ "$overall" == "pass" ]]
