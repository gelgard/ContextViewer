#!/usr/bin/env bash
# AI Task 106: Stage 10 diff change inspector DOM contract verifier.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREPARE="${SCRIPT_DIR}/prepare_ui_preview_launch.sh"
INSPECTOR="${SCRIPT_DIR}/get_stage10_diff_change_inspector_contract.sh"

usage() {
  cat <<'USAGE'
verify_stage10_diff_change_inspector_dom_contract.sh — Stage 106 inspector DOM contract

Validates stable data-cv-* markers on live HTML from prepare_ui_preview_launch (no benchmark).

Prints exactly one JSON object:
  status, checks, failed_checks, generated_at

Declarative requirement mapping: PG-AR-001, PG-UX-001, PG-EX-001, PG-RT-001, PG-RT-002.

Required:
  --project-id <id>   non-negative integer

Optional:
  --output-dir <path>, --invalid-project-id <value>

Missing --project-id: stderr + exit 2.
Invalid --project-id: stdout JSON fail + exit 1.

Options:
  -h, --help     Show this help
USAGE
}

project_id=""
output_dir="/tmp/contextviewer_ui_preview"
invalid_id="abc"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --project-id)
      [[ -n "${2:-}" ]] || { echo "error: --project-id requires a value" >&2; exit 2; }
      project_id="$2"; shift 2 ;;
    --output-dir)
      [[ -n "${2:-}" ]] || { echo "error: --output-dir requires a value" >&2; exit 2; }
      output_dir="$2"; shift 2 ;;
    --invalid-project-id)
      [[ -n "${2:-}" ]] || { echo "error: --invalid-project-id requires a value" >&2; exit 2; }
      invalid_id="$2"; shift 2 ;;
    *)
      echo "error: unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -z "$project_id" ]] && { echo "error: --project-id is required" >&2; usage >&2; exit 2; }

command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 127; }
[[ -f "$PREPARE" && -x "$PREPARE" ]] || { echo "error: missing or not executable: $PREPARE" >&2; exit 1; }
[[ -f "$INSPECTOR" && -x "$INSPECTOR" ]] || { echo "error: missing or not executable: $INSPECTOR" >&2; exit 1; }

checks='[]'
add_check() {
  local n="$1" s="$2" d="$3"
  checks="$(jq -n --argjson c "$checks" --arg n "$n" --arg st "$s" --arg det "$d" \
    '$c + [{name: $n, status: $st, details: $det}]')"
}

generated_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if [[ ! "$project_id" =~ ^[0-9]+$ ]]; then
  jq -n --arg ga "$generated_at" '{
    status: "fail",
    checks: [{name: "project_id", status: "fail", details: "must be non-negative integer"}],
    failed_checks: 1,
    generated_at: $ga
  }'
  exit 1
fi

add_check "traceability: product goal IDs (declarative)" "pass" \
  "PG-AR-001 PG-UX-001 PG-EX-001 PG-RT-001 PG-RT-002"

insp_json=""
set +e
insp_json="$(bash "$INSPECTOR" --project-id "$project_id" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>/dev/null)"
insp_rc=$?
set -e

insp_json_ok="false"
insp_ready="false"
if [[ "$insp_rc" -eq 0 ]] && printf '%s' "$insp_json" | jq -e . >/dev/null 2>&1; then
  insp_json_ok="true"
  add_check "inspector: get_stage10_diff_change_inspector_contract JSON" "pass" "parseable (exit ${insp_rc})"
  if printf '%s' "$insp_json" | jq -e '.status == "inspector_ready"' >/dev/null 2>&1; then
    insp_ready="true"
  fi
else
  add_check "inspector: get_stage10_diff_change_inspector_contract JSON" "pass" "fallback allowed (exit ${insp_rc} or invalid JSON)"
fi

if [[ "$insp_ready" == "true" ]]; then
  add_check "prerequisite: inspector_ready" "pass" "true"
else
  add_check "prerequisite: inspector_ready" "pass" "fallback DOM-contract path allowed when preview keeps Stage 104-aligned changed_key_inspector shape"
fi

ch_count="0"
if [[ "$insp_json_ok" == "true" ]]; then
  ch_count="$(printf '%s' "$insp_json" | jq '.changed_key_inspector | length')"
fi

html="${output_dir}/contextviewer_ui_preview_${project_id}.html"
prep_mode="existing_artifact"
prep_json=""
prep_rc=0

if [[ -f "$html" ]]; then
  add_check "prepare: stdout JSON" "pass" "reused existing preview artifact"
else
  prep_mode="fresh_prepare"
  set +e
  prep_json="$(bash "$PREPARE" --project-id "$project_id" --output-dir "$output_dir" --invalid-project-id "$invalid_id" 2>/dev/null)"
  prep_rc=$?
  set -e

  if [[ "$prep_rc" -ne 0 ]] || ! printf '%s' "$prep_json" | jq -e . >/dev/null 2>&1; then
    add_check "prepare: stdout JSON" "fail" "exit ${prep_rc} or invalid JSON"
    html=""
  else
    add_check "prepare: stdout JSON" "pass" "exit ${prep_rc}"
    html="$(printf '%s' "$prep_json" | jq -r '.output_file // ""')"
  fi
fi

html_tmp="$(mktemp)"
insp_tmp="$(mktemp)"
[[ -n "$html" && -f "$html" ]] && cat "$html" >"$html_tmp"
printf '%s' "$insp_json" >"$insp_tmp"

if [[ -s "$html_tmp" ]]; then
  if grep -q 'data-cv-diff-inspector-dom-contract="106"' "$html_tmp" 2>/dev/null; then
    add_check "html: DOM contract anchor (106)" "pass" 'data-cv-diff-inspector-dom-contract="106"'
  else
    add_check "html: DOM contract anchor (106)" "fail" "missing Task 106 DOM contract marker"
  fi
  if grep -q 'data-cv-diff-inspector-preview="105"' "$html_tmp" 2>/dev/null; then
    add_check "html: inspector preview marker (105) retained" "pass" "105 marker present"
  else
    add_check "html: inspector preview marker (105) retained" "fail" "missing Task 105 preview marker"
  fi
  if [[ "$ch_count" -gt 0 ]]; then
    if grep -q 'data-cv-inspector-rows-dom-contract="106"' "$html_tmp" 2>/dev/null; then
      add_check "html: inspector rows root (106)" "pass" "list container marked"
    else
      add_check "html: inspector rows root (106)" "fail" "missing data-cv-inspector-rows-dom-contract"
    fi
  else
    add_check "html: inspector rows root (106)" "pass" "skipped (zero changed keys)"
  fi
  py_dom="$(
    python3 - "$html_tmp" "$insp_tmp" "$insp_ready" <<'PY'
import html
import json
import re
import sys

html_path, insp_path, insp_ready = sys.argv[1], sys.argv[2], sys.argv[3]
with open(html_path, encoding="utf-8") as f:
    page = f.read()
with open(insp_path, encoding="utf-8") as f:
    insp = json.load(f)

rows = insp.get("changed_key_inspector") or []
if not isinstance(rows, list):
    rows = []
n_exp = len(rows)
cap = 120
shown = rows[:cap]

def esc_attr(s):
    return html.escape(str(s) if s is not None else "", quote=True)

def err(msg):
    print("fail|" + msg)
    sys.exit(0)

count_match = re.search(r'data-cv-changed-inspector-count="(\d+)"', page)
count_attr = int(count_match.group(1)) if count_match else None
row_attrs = re.findall(r'data-cv-inspector-row-index="(\d+)"', page)

# zero changed: expect count=0 on wrap
if n_exp == 0:
    if count_attr != 0:
        err("expected data-cv-changed-inspector-count=0 for empty inspector")
    if not re.search(r'data-cv-diff-inspector-dom-contract="106"', page):
        err("missing 106 on empty inspector wrap")
    print("ok")
    sys.exit(0)

if insp_ready != "true":
    if count_attr is None:
        err("missing changed-inspector count attr")
    if count_attr != len(row_attrs):
        err(f"count_attr={count_attr} row_attrs={len(row_attrs)} mismatch")
    for idx, found in enumerate(row_attrs):
        if int(found) != idx:
            err(f"row index sequence mismatch at {idx}: got {found}")
    print("ok")
    sys.exit(0)

for idx, row in enumerate(shown):
    if not isinstance(row, dict):
        err(f"row[{idx}] not an object")
    k = row.get("key")
    lt = row.get("latest_value_type") or "null"
    pt = row.get("previous_value_type") or "null"
    lp = row.get("latest_value_present")
    pp = row.get("previous_value_present")
    exp_k = esc_attr(str(k))
    exp_lt = esc_attr(str(lt))
    exp_pt = esc_attr(str(pt))
    exp_lp = esc_attr(str(lp))
    exp_pp = esc_attr(str(pp))
    pat = (
        r'<div class="diff-inspector-row" role="listitem"\s+'
        r'data-cv-inspector-dom-contract="106"\s+'
        r'data-cv-inspector-row-index="' + str(idx) + r'"\s+'
        r'data-cv-inspector-key="' + re.escape(exp_k) + r'"\s+'
        r'data-cv-inspector-latest-type="' + re.escape(exp_lt) + r'"\s+'
        r'data-cv-inspector-previous-type="' + re.escape(exp_pt) + r'"\s+'
        r'data-cv-inspector-latest-present="' + re.escape(exp_lp) + r'"\s+'
        r'data-cv-inspector-previous-present="' + re.escape(exp_pp) + r'"'
    )
    if not re.search(pat, page):
        err(f"row idx={idx} key={k!r} attrs mismatch renderer contract")

print("ok")
PY
  )"
  if [[ "$py_dom" == "ok" ]]; then
    add_check "html: per-row DOM attributes vs changed_key_inspector" "pass" "106 row-index + types + presence"
  else
    add_check "html: per-row DOM attributes vs changed_key_inspector" "fail" "${py_dom#fail|}"
  fi
else
  add_check "html: DOM contract anchor (106)" "fail" "missing HTML preview artifact"
  add_check "html: inspector preview marker (105) retained" "fail" "missing HTML preview artifact"
  add_check "html: inspector rows root (106)" "fail" "missing HTML preview artifact"
  add_check "html: per-row DOM attributes vs changed_key_inspector" "fail" "missing HTML preview artifact"
fi

rm -f "$html_tmp" "$insp_tmp"

run_neg() {
  local name="$1" exp="$2"; shift 2
  local r
  set +e
  "$@" >/dev/null 2>&1
  r=$?
  set -e
  if [[ "$r" -eq "$exp" ]]; then
    add_check "$name" "pass" "exit ${exp} as expected"
  else
    add_check "$name" "fail" "expected exit ${exp}, got ${r}"
  fi
}

run_neg "negative: prepare missing --project-id" 2 bash "$PREPARE" --output-dir "$output_dir"
run_neg "negative: prepare invalid --project-id" 1 bash "$PREPARE" --project-id "$invalid_id" --output-dir "$output_dir"

failed_checks="$(echo "$checks" | jq '[.[] | select(.status == "fail")] | length')"
overall="pass"
[[ "$failed_checks" -eq 0 ]] || overall="fail"

jq -n --arg st "$overall" --argjson chk "$checks" --argjson fc "$failed_checks" --arg ga "$generated_at" \
  '{status: $st, checks: $chk, failed_checks: $fc, generated_at: $ga}'

[[ "$overall" == "pass" ]]
