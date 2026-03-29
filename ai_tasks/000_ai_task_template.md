# AI Task XXX — {{TASK_NAME}}

## Stage
{{STAGE}}

## Substage
{{SUBSTAGE}}

## Goal
{{GOAL}}

## Why This Matters
{{WHY_THIS_TASK_EXISTS}}

## Goal Alignment
Requirement IDs (from `docs/plans/product_goal_traceability_matrix.md`):
- {{REQ_ID_1}}

## Files to Create / Update
Create:
- {{FILE_TO_CREATE_1}}

Update:
- {{FILE_TO_UPDATE_1}}

## Requirements
- {{REQUIREMENT_1}}

## Acceptance Criteria
- {{CRITERIA_1}}
- {{CRITERIA_2}}
- {{CRITERIA_3}}

## Manual Test (exact commands)

### Codex Acceptance Gate (offline, Layer 1+2)
Duration: < 10 seconds total. No DB. No HTTP. No network.
Required env: STAGE9_HYGIENE_SKIP=1 (for any script with hygiene preflight)
```bash
# Layer 1 — Unit (syntax + CLI contract)
bash -n {{PRIMARY_SCRIPT}}
bash {{PRIMARY_SCRIPT}} --help 2>&1 | grep -q "{{HELP_KEYWORD}}"
bash {{PRIMARY_SCRIPT}} 2>/dev/null; [ $? -eq 2 ]
bash {{PRIMARY_SCRIPT}} --mode bogus 2>/dev/null; [ $? -ne 0 ]

# Layer 2 — Contract (JSON shape, offline fixtures)
# STAGE9_HYGIENE_SKIP=1 bash {{PRIMARY_SCRIPT}} | jq -e '.status'
# jq -e '{{SHAPE_CHECK}}' code/test_fixtures/{{FIXTURE_FILE}}
```
Expected: all commands exit 0 or expected non-zero as noted above.

### Integration Gate (Layer 3)
Executor: user. Duration: ~60 seconds. Requires live DB + running stack.
```bash
export PROJECT_ID={{PROJECT_ID_PLACEHOLDER}}
export STAGE9_GATE_TIMEOUT_S=60

# Step 1: port cleanup
lsof -t -i:8787 | xargs kill 2>/dev/null || true

# Step 2: {{INTEGRATION_STEP_DESCRIPTION}}
{{INTEGRATION_COMMAND}}
```
Expected: {{INTEGRATION_EXPECTED_OUTPUT}}

### Visual (Layer 4)
Executor: user. Applies only when task touches HTML preview.
```bash
# A. HTML structure check (< 5 seconds, no browser)
grep -q 'render_profile="{{EXPECTED_RENDER_PROFILE}}"' /tmp/contextviewer_ui_preview/index.html
grep -q 'data-section="overview"' /tmp/contextviewer_ui_preview/index.html
grep -q 'data-section="{{EXPECTED_SECTION}}"' /tmp/contextviewer_ui_preview/index.html

# B. Open in browser
open /tmp/contextviewer_ui_preview/index.html
```
Send back: screenshot OR confirm:
- [ ] render_profile = "{{EXPECTED_RENDER_PROFILE}}"
- [ ] {{EXPECTED_SECTION}} section is visible
- [ ] No layout breakage visible

## What to send back for validation
- Layer 1+2: Codex gate output (pass/fail per command)
- Layer 3: JSON output of {{PRIMARY_INTEGRATION_SCRIPT}} (status field + blockers array)
- Layer 4 (if UI task): screenshot or confirmed checklist
