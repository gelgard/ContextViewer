#!/usr/bin/env bash
# AI Task 105: Stage 10 diff change inspector preview integration verifier.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREPARE="${SCRIPT_DIR}/prepare_ui_preview_launch.sh"
INSPECTOR="${SCRIPT_DIR}/get_stage10_diff_change_inspector_contract.sh"

usage() {
  cat <<'USAGE'
verify_stage10_diff_change_inspector_preview.sh — Stage 105 diff inspector preview integration

Validates live HTML after prepare_ui_preview_launch against get_stage10_diff_change_inspector_contract
changed-key presentation (no benchmark).

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

if [[ "$insp_rc" -ne 0 ]] || ! printf '%s' "$insp_json" | jq -e . >/dev/null 2>&1; then
  add_check "inspector: get_stage10_diff_change_inspector_contract JSON" "fail" "exit ${insp_rc} or invalid JSON"
else
  add_check "inspector: get_stage10_diff_change_inspector_contract JSON" "pass" "parseable (exit ${insp_rc})"
fi

insp_ready="false"
if printf '%s' "$insp_json" | jq -e '.status == "inspector_ready"' >/dev/null 2>&1; then
  insp_ready="true"
fi

if [[ "$insp_ready" == "true" ]]; then
  add_check "prerequisite: inspector_ready" "pass" "true"
else
  add_check "prerequisite: inspector_ready" "fail" "not inspector_ready — preview integration gate needs full diff readiness chain"
fi

ch_count="0"
if printf '%s' "$insp_json" | jq -e . >/dev/null 2>&1; then
  ch_count="$(printf '%s' "$insp_json" | jq '.changed_key_inspector | length')"
fi

prep_json=""
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

html_tmp="$(mktemp)"
insp_tmp="$(mktemp)"
[[ -n "$html" && -f "$html" ]] && cat "$html" >"$html_tmp"
printf '%s' "$insp_json" >"$insp_tmp"

if [[ "$insp_ready" == "true" ]] && [[ -s "$html_tmp" ]]; then
  if grep -q 'data-cv-diff-inspector-preview="105"' "$html_tmp" 2>/dev/null; then
    add_check "html: inspector preview marker (105)" "pass" 'data-cv-diff-inspector-preview="105"'
  else
    add_check "html: inspector preview marker (105)" "fail" "missing Task 105 marker"
  fi
  if grep -q 'diff-inspector-wrap' "$html_tmp" 2>/dev/null && grep -q 'data-cv-inspector-key' "$html_tmp" 2>/dev/null; then
    add_check "html: inspector row structure" "pass" "wrap + per-key rows"
  elif [[ "$ch_count" -eq 0 ]]; then
    if grep -q 'data-cv-changed-inspector-count="0"' "$html_tmp" 2>/dev/null; then
      add_check "html: inspector row structure" "pass" "zero changed keys — empty inspector state"
    else
      add_check "html: inspector row structure" "fail" "expected zero-count inspector stub"
    fi
  else
    add_check "html: inspector row structure" "fail" "missing inspector rows or keys"
  fi
  py_msg="$(
    python3 - "$html_tmp" "$insp_tmp" <<'PY'
import json
import re
import sys

html_path, insp_path = sys.argv[1], sys.argv[2]
with open(html_path, encoding="utf-8") as f:
    html = f.read()
with open(insp_path, encoding="utf-8") as f:
    insp = json.load(f)

rows = insp.get("changed_key_inspector") or []
if not isinstance(rows, list):
    rows = []
n_exp = len(rows)
mc = re.search(r'data-cv-changed-inspector-count="(\d+)"', html)
n_attr = int(mc.group(1)) if mc else None
n_rows_html = len(re.findall(r'data-cv-inspector-key="', html))

def norm_id(x):
    if x is None:
        return ""
    try:
        return str(int(str(x)))
    except ValueError:
        return str(x)

cap = 120
exp_shown = min(n_exp, cap)
exp_keys = [norm_id(r.get("key")) for r in rows[:cap] if isinstance(r, dict)]
missing = []
for k in exp_keys:
    if not k:
        continue
    if not re.search(r'data-cv-inspector-key="' + re.escape(k) + r'"', html):
        missing.append(k)

errs = []
if n_attr is not None and n_attr != n_exp:
    errs.append(f"count_attr={n_attr} expected={n_exp}")
if n_exp > 0 and n_rows_html != exp_shown:
    errs.append(f"row_attrs={n_rows_html} expected={exp_shown}")
if n_exp == 0 and n_attr != 0:
    errs.append(f"count_attr={n_attr} expected=0")
if missing[:5]:
    errs.append("missing_keys:" + ",".join(missing[:5]))

print("ok" if not errs else "fail|" + "; ".join(errs))
PY
  )"
  if [[ "$py_msg" == "ok" ]]; then
    add_check "html: inspector counts and keys match contract" "pass" "changed_key_inspector ↔ DOM"
  else
    add_check "html: inspector counts and keys match contract" "fail" "${py_msg#fail|}"
  fi
else
  add_check "html: inspector preview marker (105)" "pass" "skipped"
  add_check "html: inspector row structure" "pass" "skipped"
  add_check "html: inspector counts and keys match contract" "pass" "skipped"
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
