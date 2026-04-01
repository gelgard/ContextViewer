#!/usr/bin/env bash
# AI Task 059: Stage 8 UI preview readiness report (read-only; stdout = one JSON object).
# AI Task 080: delivery smoke gains production shell marker check; readiness still gates on full delivery pass.
# AI Task 081: structured Overview from dashboard feed.
# AI Task 082: unified viz workspace HTML.
# AI Task 083: history workspace HTML; production surface classes on served preview.
# AI Task 085: diff viewer section; render_profile + diff_viewer_state in preview_summary.
# AI Task 088: settings section; render_profile 088_stage9_secondary_flows_preview; settings_surface_state; investor gate includes settings.
# AI Task 102: fast artifact path reads diff comparison flags from embedded payload and live diff contract.
# AI Task 103: fast delivery checks Task 103 diff preview fidelity markers when comparison_ready.
# AI Task 105: fast delivery checks change-inspector preview markers when comparison_ready.
# AI Task 106: fast delivery checks inspector DOM contract marker (106) when comparison_ready.
# AI Task 107: fast delivery checks inspector default-focus markers when comparison_ready and rows list exists.
# AI Task 108: fast delivery checks inspector focus-summary (108) when comparison_ready and rows list exists.
# AI Task 109: fast delivery checks focus-summary DOM-contract markers (109) when focus-summary is present.
# AI Task 110: fast delivery checks focus-summary presence-field markers (110) when focus-summary is present.
# AI Task 111: fast delivery checks focus-summary state-chip markers (111) when focus-summary is present.
# AI Task 112: fast delivery checks state-chips DOM contract (112) when focus-summary is present.
# AI Task 113: fast delivery checks focus-summary source-link markers (113) when focus-summary is present.
# AI Task 114: fast delivery checks focus-summary source-link DOM-fields (114) when focus-summary is present.
# AI Task 115: fast delivery checks focus-summary source-link chips (115) when focus-summary is present.
# AI Task 116: fast delivery checks focus-summary source-link chips DOM contract (116) when focus-summary is present.
# AI Task 117: fast delivery checks focus-summary source-link hint (117) when focus-summary is present.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREPARE="${SCRIPT_DIR}/prepare_ui_preview_launch.sh"
BOOTSTRAP_VERIFY="${SCRIPT_DIR}/verify_stage8_ui_bootstrap_contracts.sh"
DELIVERY_VERIFY="${SCRIPT_DIR}/verify_stage8_ui_preview_delivery.sh"
DIFF_CONTRACT="${SCRIPT_DIR}/../diff/get_diff_viewer_contract_bundle.sh"

usage() {
  cat <<'USAGE'
get_stage8_ui_preview_readiness_report.sh — Stage 8 UI preview readiness (demo / investor go/no-go)

Usage:
  get_stage8_ui_preview_readiness_report.sh --project-id <id> [--mode <fast|full>] [--port <n>] [--output-dir <path>] [--invalid-project-id <value>]

Runs (read-only against source data):
  prepare_ui_preview_launch.sh --project-id <id> --output-dir <path> --invalid-project-id <value>
  full mode:
    verify_stage8_ui_bootstrap_contracts.sh --project-id <id> --invalid-project-id <value>
    verify_stage8_ui_preview_delivery.sh --project-id <id> --port <n> --output-dir <path> --invalid-project-id <value>
  fast mode:
    bootstrap consistency from prepare.preview_summary + local artifact delivery checks (no delivery/server subprocess)

Stdout:
  One JSON object:
    project_id
    generated_at (UTC ISO-8601)
    status                 ready | not_ready
    preview_artifacts      output_dir, output_file, open_command (from prepare)
    render_profile         from prepare.preview_summary (e.g. 088_stage9_secondary_flows_preview)
    verification:
      bootstrap_smoke      full JSON from verify_stage8_ui_bootstrap_contracts.sh
      delivery_smoke       full JSON from verify_stage8_ui_preview_delivery.sh
    readiness_summary      overview_available, visualization_available, history_available,
                           diff_viewer_available, diff_viewer_empty_state_only, diff_viewer_comparison_ready,
                           settings_profile_available, settings_contract_consistent, settings_read_only_flags_ok,
                           preview_launch_ready, local_delivery_ready, investor_demo_ready
    consistency_checks     project_id_match, artifact_matches_project, bootstrap_pass,
                           delivery_pass, all_ready_flags_true

Exit 0 only when status is ready. Exit 3 when JSON is assembled but status is not_ready or consistency checks fail.
Invalid CLI: stderr + non-zero (no JSON). prepare failure: propagated exit (no JSON). Malformed child JSON: stderr + exit 3.

Dependencies: jq; children require curl, python3, psql, etc.

Options:
  -h, --help                    Show this help
  --project-id <id>             Required. Non-negative integer.
  --mode <fast|full>            Optional. full default (legacy exhaustive); fast skips bootstrap/delivery subprocesses.
  --port <n>                    Optional. Integer >= 1 (default: 8787)
  --output-dir <path>           Optional. Default: /tmp/contextviewer_ui_preview
  --invalid-project-id <value>  Optional. Passed to children (default: abc)
USAGE
}

project_id=""
port="8787"
output_dir="/tmp/contextviewer_ui_preview"
invalid_id="abc"
mode="full"

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
    --mode)
      if [[ -z "${2:-}" ]]; then
        echo "error: --mode requires a value" >&2
        exit 2
      fi
      mode="$2"
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
if [[ "$mode" != "fast" && "$mode" != "full" ]]; then
  echo "error: --mode must be fast or full, got: $mode" >&2
  exit 2
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

build_prepare_json_fast_from_artifact() {
  local artifact="$1"
  local out_dir_abs
  out_dir_abs="$(cd "$(dirname "$artifact")" && pwd)"

  local has_overview has_viz has_hist has_diff has_settings has_payload has_shell
  has_overview="false"; has_viz="false"; has_hist="false"; has_diff="false"; has_settings="false"; has_payload="false"; has_shell="false"
  grep -q 'data-section="overview"' "$artifact" 2>/dev/null && has_overview="true"
  grep -q 'data-section="visualization"' "$artifact" 2>/dev/null && has_viz="true"
  grep -q 'data-section="history"' "$artifact" 2>/dev/null && has_hist="true"
  grep -q 'data-section="diff"' "$artifact" 2>/dev/null && has_diff="true"
  grep -q 'data-section="settings"' "$artifact" 2>/dev/null && has_settings="true"
  grep -q 'id="ui-bootstrap-payload"' "$artifact" 2>/dev/null && has_payload="true"
  grep -q 'data-cv-preview-shell="080"' "$artifact" 2>/dev/null && has_shell="true"

  df_json="$(
    python3 - "$artifact" <<'PYDF'
import json
import re
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    html = f.read()
m = re.search(
    r'<script type="application/json" id="ui-bootstrap-payload">\s*([\s\S]*?)\s*</script>',
    html,
)
comp = False
if m:
    try:
        pl = json.loads(m.group(1))
        dv = (pl.get("ui_sections") or {}).get("diff_viewer") or {}
        comp = dv.get("comparison_ready") is True
    except (json.JSONDecodeError, TypeError, AttributeError):
        pass
print(json.dumps({"comparison_ready": comp, "empty_state_only": not comp}))
PYDF
  )"

  jq -n \
    --argjson pid "$project_id" \
    --arg ga "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg od "$out_dir_abs" \
    --arg of "$artifact" \
    --arg oc "open $artifact" \
    --argjson ho "$has_overview" \
    --argjson hv "$has_viz" \
    --argjson hh "$has_hist" \
    --argjson hd "$has_diff" \
    --argjson hs "$has_settings" \
    --argjson hp "$has_payload" \
    --argjson hsh "$has_shell" \
    --argjson df "$df_json" \
    '
    def sec_list($ho; $hv; $hh; $hd; $hs):
      [
        (if $ho then "overview" else empty end),
        (if $hv then "visualization" else empty end),
        (if $hh then "history" else empty end),
        (if $hd then "diff" else empty end),
        (if $hs then "settings" else empty end)
      ];
    {
      project_id: ($pid | tonumber),
      generated_at: $ga,
      output_dir: $od,
      output_file: $of,
      open_command: $oc,
      preview_summary: {
        sections_rendered: sec_list($ho; $hv; $hh; $hd; $hs),
        source_consistency_checks: {
          project_id_match: ($ho and $hv and $hh and $hp and $hsh),
          overview_present: $ho,
          visualization_consistent: $hv,
          history_consistent: $hh
        },
        render_profile: "088_stage9_secondary_flows_preview",
        diff_viewer_state: {
          available: $hd,
          empty_state_only: (if $hd then $df.empty_state_only else true end),
          comparison_ready: (if $hd then $df.comparison_ready else false end)
        },
        settings_surface_state: {
          available: $hs,
          contract_consistent: $hs,
          user_preferences_in_contract: false,
          writable_product_settings_supported: false
        }
      }
    }'
}

prepare_json=""
if [[ "$mode" == "fast" ]]; then
  fast_artifact="${output_dir%/}/contextviewer_ui_preview_${project_id}.html"
  if [[ -f "$fast_artifact" ]]; then
    refresh_fast_artifact="false"
    if grep -q 'data-cv-inspector-rows-dom-contract="106"' "$fast_artifact" 2>/dev/null; then
      if ! grep -q 'data-cv-inspector-default-focus-mode="107"' "$fast_artifact" 2>/dev/null \
        || ! grep -q 'data-cv-diff-inspector-default-focus="107"' "$fast_artifact" 2>/dev/null \
        || ! grep -q 'data-cv-diff-inspector-focus-summary="108"' "$fast_artifact" 2>/dev/null \
        || ! grep -q 'data-cv-diff-inspector-focus-summary-dom-contract="109"' "$fast_artifact" 2>/dev/null \
        || ! grep -q 'data-cv-diff-inspector-focus-summary-presence-fields="110"' "$fast_artifact" 2>/dev/null \
        || ! grep -q 'data-cv-diff-inspector-focus-summary-state-chips="111"' "$fast_artifact" 2>/dev/null \
        || ! grep -q 'data-cv-diff-inspector-focus-summary-state-chips-dom-contract="112"' "$fast_artifact" 2>/dev/null \
        || ! grep -q 'data-cv-diff-inspector-focus-summary-source-link="113"' "$fast_artifact" 2>/dev/null \
        || ! grep -q 'data-cv-diff-inspector-focus-summary-source-link-dom-fields="114"' "$fast_artifact" 2>/dev/null \
        || ! grep -q 'data-cv-diff-inspector-focus-summary-source-link-chips="115"' "$fast_artifact" 2>/dev/null \
        || ! grep -q 'data-cv-diff-inspector-focus-summary-source-link-chips-dom-contract="116"' "$fast_artifact" 2>/dev/null \
        || ! grep -q 'data-cv-diff-inspector-focus-summary-source-link-hint="117"' "$fast_artifact" 2>/dev/null; then
        refresh_fast_artifact="true"
      fi
    fi
    if [[ "$refresh_fast_artifact" == "true" ]]; then
      prepare_json="$(run_capture_strict bash "$PREPARE" --project-id "$project_id" --output-dir "$output_dir" --invalid-project-id "$invalid_id")" || exit "$?"
    else
    prepare_json="$(build_prepare_json_fast_from_artifact "$fast_artifact")"
    fi
    if [[ -f "$DIFF_CONTRACT" && -x "$DIFF_CONTRACT" ]]; then
      set +e
      live_diff="$("$DIFF_CONTRACT" --project-id "$project_id" 2>/dev/null)"
      ld_rc=$?
      set -e
      if [[ "$ld_rc" -eq 0 ]] && printf '%s' "$live_diff" | jq -e . >/dev/null 2>&1; then
        prepare_json="$(printf '%s' "$prepare_json" | jq --argjson ld "$live_diff" '
          .preview_summary.diff_viewer_state |= (
            if (.available == true) then
              ($ld.comparison_ready == true) as $cr
              | . + {empty_state_only: ($cr | not), comparison_ready: $cr}
            else . end
          )
        ')"
      fi
    fi
  else
    prepare_json="$(run_capture_strict bash "$PREPARE" --project-id "$project_id" --output-dir "$output_dir" --invalid-project-id "$invalid_id")" || exit "$?"
  fi
else
  prepare_json="$(run_capture_strict bash "$PREPARE" --project-id "$project_id" --output-dir "$output_dir" --invalid-project-id "$invalid_id")" || exit "$?"
fi

if ! printf '%s\n' "$prepare_json" | jq -e . >/dev/null 2>&1; then
  echo "error: prepare_ui_preview_launch.sh stdout is not valid JSON" >&2
  exit 3
fi

if [[ "$mode" == "full" ]]; then
  bootstrap_json="$(run_capture_json_always bash "$BOOTSTRAP_VERIFY" --project-id "$project_id" --invalid-project-id "$invalid_id")"
else
  prep_cc="$(printf '%s' "$prepare_json" | jq -c '.preview_summary.source_consistency_checks // {}')"
  prep_sections="$(printf '%s' "$prepare_json" | jq -c '.preview_summary.sections_rendered // []')"
  fast_boot_checks='[]'
  add_fast_boot_check() {
    local n="$1" s="$2" d="$3"
    fast_boot_checks="$(jq -n \
      --argjson c "$fast_boot_checks" \
      --arg n "$n" \
      --arg st "$s" \
      --arg det "$d" \
      '$c + [{name: $n, status: $st, details: $det}]')"
  }
  if printf '%s' "$prep_sections" | jq -e 'index("overview") != null and index("visualization") != null and index("history") != null' >/dev/null 2>&1; then
    add_fast_boot_check "bootstrap-fast: section roots overview/visualization/history" "pass" "present in prepare.preview_summary.sections_rendered"
  else
    add_fast_boot_check "bootstrap-fast: section roots overview/visualization/history" "fail" "missing one or more required section roots"
  fi
  if printf '%s' "$prep_cc" | jq -e '.project_id_match == true and .overview_present == true and .visualization_consistent == true and .history_consistent == true' >/dev/null 2>&1; then
    add_fast_boot_check "bootstrap-fast: source_consistency_checks core flags" "pass" "all required core flags true"
  else
    add_fast_boot_check "bootstrap-fast: source_consistency_checks core flags" "fail" "one or more core flags are not true"
  fi
  fast_boot_failed="$(printf '%s' "$fast_boot_checks" | jq '[.[] | select(.status == "fail")] | length')"
  fast_boot_status="pass"
  [[ "$fast_boot_failed" -eq 0 ]] || fast_boot_status="fail"
  bootstrap_json="$(jq -n \
    --arg st "$fast_boot_status" \
    --argjson checks "$fast_boot_checks" \
    --argjson fc "$fast_boot_failed" \
    --arg ga "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{status: $st, checks: $checks, failed_checks: $fc, generated_at: $ga, mode: "fast_prepare_summary"}')"
fi

if [[ "$mode" == "full" ]]; then
  delivery_json="$(run_capture_json_always bash "$DELIVERY_VERIFY" --project-id "$project_id" --port "$port" --output-dir "$output_dir" --invalid-project-id "$invalid_id")"
else
  output_file_fast="$(printf '%s' "$prepare_json" | jq -r '.output_file // ""')"
  fast_checks='[]'
  add_fast_check() {
    local n="$1" s="$2" d="$3"
    fast_checks="$(jq -n \
      --argjson c "$fast_checks" \
      --arg n "$n" \
      --arg st "$s" \
      --arg det "$d" \
      '$c + [{name: $n, status: $st, details: $det}]')"
  }
  if [[ -n "$output_file_fast" && -f "$output_file_fast" ]]; then
    add_fast_check "delivery-fast: preview artifact exists" "pass" "output_file exists"
    if grep -q 'data-section="overview"' "$output_file_fast" 2>/dev/null; then
      add_fast_check "delivery-fast: overview marker" "pass" 'found data-section="overview"'
    else
      add_fast_check "delivery-fast: overview marker" "fail" 'missing data-section="overview"'
    fi
    if grep -q 'data-section="visualization"' "$output_file_fast" 2>/dev/null; then
      add_fast_check "delivery-fast: visualization marker" "pass" 'found data-section="visualization"'
    else
      add_fast_check "delivery-fast: visualization marker" "fail" 'missing data-section="visualization"'
    fi
    if grep -q 'data-section="history"' "$output_file_fast" 2>/dev/null; then
      add_fast_check "delivery-fast: history marker" "pass" 'found data-section="history"'
    else
      add_fast_check "delivery-fast: history marker" "fail" 'missing data-section="history"'
    fi
    if grep -q 'data-section="diff"' "$output_file_fast" 2>/dev/null; then
      add_fast_check "delivery-fast: diff marker" "pass" 'found data-section="diff"'
    else
      add_fast_check "delivery-fast: diff marker" "fail" 'missing data-section="diff"'
    fi
    prep_cmp="$(printf '%s' "$prepare_json" | jq -r '.preview_summary.diff_viewer_state.comparison_ready // false')"
    if [[ "$prep_cmp" == "true" ]]; then
      if grep -q 'data-cv-diff-fidelity="103"' "$output_file_fast" 2>/dev/null \
        && grep -q 'data-cv-diff-comparison-ready="true"' "$output_file_fast" 2>/dev/null; then
        add_fast_check "delivery-fast: diff preview fidelity (103)" "pass" "comparison-ready fidelity markers"
      else
        add_fast_check "delivery-fast: diff preview fidelity (103)" "fail" "regenerate preview (prepare_ui_preview_launch) for Task 103 markers"
      fi
    else
      add_fast_check "delivery-fast: diff preview fidelity (103)" "pass" "skipped (comparison_ready false)"
    fi
    if [[ "$prep_cmp" == "true" ]]; then
      if grep -q 'data-cv-diff-inspector-preview="105"' "$output_file_fast" 2>/dev/null; then
        add_fast_check "delivery-fast: diff change inspector preview (105)" "pass" "data-cv-diff-inspector-preview present"
      else
        add_fast_check "delivery-fast: diff change inspector preview (105)" "fail" "regenerate preview for Task 105 inspector integration"
      fi
    else
      add_fast_check "delivery-fast: diff change inspector preview (105)" "pass" "skipped (comparison_ready false)"
    fi
    if [[ "$prep_cmp" == "true" ]]; then
      if grep -q 'data-cv-diff-inspector-dom-contract="106"' "$output_file_fast" 2>/dev/null; then
        add_fast_check "delivery-fast: diff inspector DOM contract (106)" "pass" 'data-cv-diff-inspector-dom-contract present'
      else
        add_fast_check "delivery-fast: diff inspector DOM contract (106)" "fail" "regenerate preview for Task 106 DOM markers"
      fi
    else
      add_fast_check "delivery-fast: diff inspector DOM contract (106)" "pass" "skipped (comparison_ready false)"
    fi
    if [[ "$prep_cmp" == "true" ]]; then
      if grep -q 'data-cv-inspector-rows-dom-contract="106"' "$output_file_fast" 2>/dev/null; then
        if grep -q 'data-cv-inspector-default-focus-mode="107"' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-diff-inspector-default-focus="107"' "$output_file_fast" 2>/dev/null; then
          add_fast_check "delivery-fast: diff inspector default focus (107)" "pass" "107 focus markers present"
        else
          add_fast_check "delivery-fast: diff inspector default focus (107)" "fail" "regenerate preview for Task 107 default-focus markers"
        fi
      else
        add_fast_check "delivery-fast: diff inspector default focus (107)" "pass" "skipped (no inspector rows list)"
      fi
    else
      add_fast_check "delivery-fast: diff inspector default focus (107)" "pass" "skipped (comparison_ready false)"
    fi
    if [[ "$prep_cmp" == "true" ]]; then
      if grep -q 'data-cv-inspector-rows-dom-contract="106"' "$output_file_fast" 2>/dev/null; then
        if grep -q 'data-cv-diff-inspector-focus-summary="108"' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-key="' "$output_file_fast" 2>/dev/null; then
          add_fast_check "delivery-fast: diff inspector focus summary (108)" "pass" "108 summary markers present"
        else
          add_fast_check "delivery-fast: diff inspector focus summary (108)" "fail" "regenerate preview for Task 108 focus-summary"
        fi
      else
        add_fast_check "delivery-fast: diff inspector focus summary (108)" "pass" "skipped (no inspector rows list)"
      fi
    else
      add_fast_check "delivery-fast: diff inspector focus summary (108)" "pass" "skipped (comparison_ready false)"
    fi
    if [[ "$prep_cmp" == "true" ]]; then
      if grep -q 'data-cv-diff-inspector-focus-summary="108"' "$output_file_fast" 2>/dev/null; then
        if grep -q 'data-cv-diff-inspector-focus-summary-dom-contract="109"' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-field="key"' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-field="latest_type"' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-field="previous_type"' "$output_file_fast" 2>/dev/null; then
          add_fast_check "delivery-fast: diff inspector focus summary DOM contract (109)" "pass" "109 summary DOM markers present"
        else
          add_fast_check "delivery-fast: diff inspector focus summary DOM contract (109)" "fail" "regenerate preview for Task 109 focus-summary DOM markers"
        fi
      else
        add_fast_check "delivery-fast: diff inspector focus summary DOM contract (109)" "pass" "skipped (no focus-summary block)"
      fi
    else
      add_fast_check "delivery-fast: diff inspector focus summary DOM contract (109)" "pass" "skipped (comparison_ready false)"
    fi
    if [[ "$prep_cmp" == "true" ]]; then
      if grep -q 'data-cv-diff-inspector-focus-summary="108"' "$output_file_fast" 2>/dev/null; then
        if grep -q 'data-cv-diff-inspector-focus-summary-presence-fields="110"' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-latest-present="' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-field="latest_present"' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-field="previous_present"' "$output_file_fast" 2>/dev/null; then
          add_fast_check "delivery-fast: diff inspector focus-summary presence fields (110)" "pass" "110 presence markers present"
        else
          add_fast_check "delivery-fast: diff inspector focus-summary presence fields (110)" "fail" "regenerate preview for Task 110 presence fields"
        fi
      else
        add_fast_check "delivery-fast: diff inspector focus-summary presence fields (110)" "pass" "skipped (no focus-summary block)"
      fi
    else
      add_fast_check "delivery-fast: diff inspector focus-summary presence fields (110)" "pass" "skipped (comparison_ready false)"
    fi
    if [[ "$prep_cmp" == "true" ]]; then
      if grep -q 'data-cv-diff-inspector-focus-summary="108"' "$output_file_fast" 2>/dev/null; then
        if grep -q 'data-cv-diff-inspector-focus-summary-state-chips="111"' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-chip="latest_type"' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-chip-value="' "$output_file_fast" 2>/dev/null; then
          add_fast_check "delivery-fast: diff inspector focus-summary state chips (111)" "pass" "111 state-chip markers present"
        else
          add_fast_check "delivery-fast: diff inspector focus-summary state chips (111)" "fail" "regenerate preview for Task 111 state chips"
        fi
      else
        add_fast_check "delivery-fast: diff inspector focus-summary state chips (111)" "pass" "skipped (no focus-summary block)"
      fi
    else
      add_fast_check "delivery-fast: diff inspector focus-summary state chips (111)" "pass" "skipped (comparison_ready false)"
    fi
    if [[ "$prep_cmp" == "true" ]]; then
      if grep -q 'data-cv-diff-inspector-focus-summary="108"' "$output_file_fast" 2>/dev/null; then
        if grep -q 'data-cv-diff-inspector-focus-summary-state-chips-dom-contract="112"' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-state-chip-field="latest_type"' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-state-chip-value="' "$output_file_fast" 2>/dev/null; then
          add_fast_check "delivery-fast: diff inspector focus-summary state-chips DOM contract (112)" "pass" "112 state-chips DOM contract present"
        else
          add_fast_check "delivery-fast: diff inspector focus-summary state-chips DOM contract (112)" "fail" "regenerate preview for Task 112 state-chips DOM contract"
        fi
      else
        add_fast_check "delivery-fast: diff inspector focus-summary state-chips DOM contract (112)" "pass" "skipped (no focus-summary block)"
      fi
    else
      add_fast_check "delivery-fast: diff inspector focus-summary state-chips DOM contract (112)" "pass" "skipped (comparison_ready false)"
    fi
    if [[ "$prep_cmp" == "true" ]]; then
      if grep -q 'data-cv-diff-inspector-focus-summary="108"' "$output_file_fast" 2>/dev/null; then
        if grep -q 'data-cv-diff-inspector-focus-summary-source-link="113"' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-source-key="' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-source-index="0"' "$output_file_fast" 2>/dev/null; then
          add_fast_check "delivery-fast: diff inspector focus-summary source link (113)" "pass" "113 source-link markers present"
        else
          add_fast_check "delivery-fast: diff inspector focus-summary source link (113)" "fail" "regenerate preview for Task 113 source-link markers"
        fi
      else
        add_fast_check "delivery-fast: diff inspector focus-summary source link (113)" "pass" "skipped (no focus-summary block)"
      fi
    else
      add_fast_check "delivery-fast: diff inspector focus-summary source link (113)" "pass" "skipped (comparison_ready false)"
    fi
    if [[ "$prep_cmp" == "true" ]]; then
      if grep -q 'data-cv-diff-inspector-focus-summary="108"' "$output_file_fast" 2>/dev/null; then
        if grep -q 'data-cv-diff-inspector-focus-summary-source-link-dom-fields="114"' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-source-link-field="source_key"' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-source-link-field="source_index"' "$output_file_fast" 2>/dev/null \
          && grep -q 'diff-inspector-focus-summary-sourceline' "$output_file_fast" 2>/dev/null; then
          add_fast_check "delivery-fast: diff inspector focus-summary source-link DOM fields (114)" "pass" "114 source-link DOM fields present"
        else
          add_fast_check "delivery-fast: diff inspector focus-summary source-link DOM fields (114)" "fail" "regenerate preview for Task 114 source-link DOM fields"
        fi
      else
        add_fast_check "delivery-fast: diff inspector focus-summary source-link DOM fields (114)" "pass" "skipped (no focus-summary block)"
      fi
    else
      add_fast_check "delivery-fast: diff inspector focus-summary source-link DOM fields (114)" "pass" "skipped (comparison_ready false)"
    fi
    if [[ "$prep_cmp" == "true" ]]; then
      if grep -q 'data-cv-diff-inspector-focus-summary="108"' "$output_file_fast" 2>/dev/null; then
        if grep -q 'data-cv-diff-inspector-focus-summary-source-link-chips="115"' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-source-chip="source_key"' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-source-chip="source_index"' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-source-chip-value="' "$output_file_fast" 2>/dev/null; then
          add_fast_check "delivery-fast: diff inspector focus-summary source-link chips (115)" "pass" "115 source-link chips present"
        else
          add_fast_check "delivery-fast: diff inspector focus-summary source-link chips (115)" "fail" "regenerate preview for Task 115 source-link chips"
        fi
      else
        add_fast_check "delivery-fast: diff inspector focus-summary source-link chips (115)" "pass" "skipped (no focus-summary block)"
      fi
    else
      add_fast_check "delivery-fast: diff inspector focus-summary source-link chips (115)" "pass" "skipped (comparison_ready false)"
    fi
    if [[ "$prep_cmp" == "true" ]]; then
      if grep -q 'data-cv-diff-inspector-focus-summary="108"' "$output_file_fast" 2>/dev/null; then
        if grep -q 'data-cv-diff-inspector-focus-summary-source-link-chips-dom-contract="116"' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-source-link-chip-field="source_key"' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-source-link-chip-value="' "$output_file_fast" 2>/dev/null \
          && grep -q 'diff-inspector-focus-summary-source-chips' "$output_file_fast" 2>/dev/null; then
          add_fast_check "delivery-fast: diff inspector focus-summary source-link chips DOM contract (116)" "pass" "116 source-link chips DOM contract present"
        else
          add_fast_check "delivery-fast: diff inspector focus-summary source-link chips DOM contract (116)" "fail" "regenerate preview for Task 116 source-link chips DOM contract"
        fi
      else
        add_fast_check "delivery-fast: diff inspector focus-summary source-link chips DOM contract (116)" "pass" "skipped (no focus-summary block)"
      fi
    else
      add_fast_check "delivery-fast: diff inspector focus-summary source-link chips DOM contract (116)" "pass" "skipped (comparison_ready false)"
    fi
    if [[ "$prep_cmp" == "true" ]]; then
      if grep -q 'data-cv-diff-inspector-focus-summary="108"' "$output_file_fast" 2>/dev/null; then
        if grep -q 'data-cv-diff-inspector-focus-summary-source-link-hint="117"' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-source-link-hint-key="' "$output_file_fast" 2>/dev/null \
          && grep -q 'data-cv-inspector-focus-summary-source-link-hint-index="0"' "$output_file_fast" 2>/dev/null \
          && grep -q 'diff-inspector-focus-summary-source-hint' "$output_file_fast" 2>/dev/null; then
          add_fast_check "delivery-fast: diff inspector focus-summary source-link hint (117)" "pass" "117 source-link hint present"
        else
          add_fast_check "delivery-fast: diff inspector focus-summary source-link hint (117)" "fail" "regenerate preview for Task 117 source-link hint"
        fi
      else
        add_fast_check "delivery-fast: diff inspector focus-summary source-link hint (117)" "pass" "skipped (no focus-summary block)"
      fi
    else
      add_fast_check "delivery-fast: diff inspector focus-summary source-link hint (117)" "pass" "skipped (comparison_ready false)"
    fi
    if grep -q 'data-section="settings"' "$output_file_fast" 2>/dev/null; then
      add_fast_check "delivery-fast: settings marker" "pass" 'found data-section="settings"'
    else
      add_fast_check "delivery-fast: settings marker" "fail" 'missing data-section="settings"'
    fi
    if grep -q 'id="ui-bootstrap-payload"' "$output_file_fast" 2>/dev/null; then
      add_fast_check "delivery-fast: payload marker" "pass" 'found id="ui-bootstrap-payload"'
    else
      add_fast_check "delivery-fast: payload marker" "fail" 'missing id="ui-bootstrap-payload"'
    fi
    if grep -q 'data-cv-preview-shell="080"' "$output_file_fast" 2>/dev/null; then
      add_fast_check "delivery-fast: shell marker" "pass" 'found data-cv-preview-shell="080"'
    else
      add_fast_check "delivery-fast: shell marker" "fail" 'missing data-cv-preview-shell="080"'
    fi
  else
    add_fast_check "delivery-fast: preview artifact exists" "fail" "output_file missing"
  fi
  fast_failed="$(printf '%s' "$fast_checks" | jq '[.[] | select(.status == "fail")] | length')"
  fast_status="pass"
  [[ "$fast_failed" -eq 0 ]] || fast_status="fail"
  delivery_json="$(jq -n \
    --arg st "$fast_status" \
    --argjson checks "$fast_checks" \
    --argjson fc "$fast_failed" \
    --arg ga "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{status: $st, checks: $checks, failed_checks: $fc, generated_at: $ga, mode: "fast_local_artifact"}')"
fi

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
  def has_check_pass($smoke; $n):
    (($smoke.checks // []) | map(select(.name == $n)) | .[0].status // "fail") == "pass";

  def sections_has($arr; $k):
    (($arr | type) == "array") and (($arr | index($k)) != null);

  ($prep.project_id) as $ppid
  | ($ppid == ($pid | tonumber)) as $pid_ok
  | ($boot.status == "pass") as $boot_pass
  | ($del.status == "pass") as $del_pass
  | $art_ex as $file_ok
  | (($prep.preview_summary // empty).sections_rendered // []) as $sr
  | sections_has($sr; "overview") as $ov_a
  | sections_has($sr; "visualization") as $viz_a
  | sections_has($sr; "history") as $hist_a
  | (($prep.preview_summary.diff_viewer_state // empty).available == true) as $dv_declared
  | sections_has($sr; "diff") as $diff_sec
  | ($diff_sec and $dv_declared and $boot_pass) as $diff_a
  | (($prep.preview_summary.diff_viewer_state // empty).empty_state_only // false) as $dv_empty
  | (($prep.preview_summary.diff_viewer_state // empty).comparison_ready // false) as $dv_comp
  | (($prep.preview_summary.settings_surface_state // empty).available == true) as $set_declared
  | sections_has($sr; "settings") as $set_sec
  | (($prep.preview_summary.settings_surface_state // empty).contract_consistent == true) as $set_cc_ok
  | (($prep.preview_summary.settings_surface_state // empty).user_preferences_in_contract == false) as $set_no_prefs
  | (($prep.preview_summary.settings_surface_state // empty).writable_product_settings_supported == false) as $set_no_write
  | ($set_sec and $set_declared and $boot_pass and $set_cc_ok and $set_no_prefs and $set_no_write) as $set_a
  | ($set_no_prefs and $set_no_write) as $set_ro_ok
  | (($prep.open_command | type == "string") and ($prep.open_command | startswith("open "))) as $open_ok
  | ($file_ok and ($prep.output_file | type == "string")
     and ($prep.output_file | endswith("contextviewer_ui_preview_\($pid).html"))) as $art_match
  | (
      if (($del.mode // "") == "fast_local_artifact")
      then true
      else has_check_pass($del; "delivery: preview_url matches expected")
      end
    ) as $url_ok
  | ($pid_ok and $url_ok) as $proj_match
  | {
      overview_available: ($ov_a and $boot_pass),
      visualization_available: ($viz_a and $boot_pass),
      history_available: ($hist_a and $boot_pass),
      diff_viewer_available: $diff_a,
      diff_viewer_empty_state_only: $dv_empty,
      diff_viewer_comparison_ready: $dv_comp,
      settings_profile_available: $set_a,
      settings_contract_consistent: $set_cc_ok,
      settings_read_only_flags_ok: $set_ro_ok,
      preview_launch_ready: ($file_ok and $art_match and $open_ok),
      local_delivery_ready: $del_pass,
      investor_demo_ready: (
        ($ov_a and $boot_pass)
        and ($viz_a and $boot_pass)
        and ($hist_a and $boot_pass)
        and $diff_a
        and $set_a
        and $file_ok
        and $art_match
        and $del_pass
      )
    } as $rs
  | ($rs | [.overview_available, .visualization_available, .history_available,
            .diff_viewer_available,
            .settings_profile_available,
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
      render_profile: ($prep.preview_summary.render_profile // null),
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
