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

## Validation Budget
- Layer 1 + Layer 2 target: {{LAYER12_BUDGET}} (hard ceiling: 60s total)
- Layer 3 target: {{LAYER3_BUDGET}} (hard ceiling: 120s)
- Full closure target: {{FULL_CLOSURE_BUDGET}} (hard ceiling: 10 minutes)

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

## Acceptance Model
- Primary acceptance gate: {{PRIMARY_ACCEPTANCE_GATE}}
- Diagnostics policy: separate and non-blocking unless this task explicitly declares otherwise
- Artifact-first rule: higher-level validation must consume existing JSON artifacts instead of recomputing heavy child paths

## Manual Test (exact commands)

### Codex Acceptance Gate (offline, Layer 1+2)
Duration target: < 30 seconds total. No DB. No HTTP. No network.
Required env: `STAGE9_HYGIENE_SKIP=1` for any script with hygiene preflight.
```bash
# Layer 1 — Unit / CLI
bash -n {{PRIMARY_SCRIPT}}
bash {{PRIMARY_SCRIPT}} --help 2>&1 | grep -q "{{HELP_KEYWORD}}"
bash {{PRIMARY_SCRIPT}} 2>/dev/null; [ $? -eq {{MISSING_ARG_EXIT}} ]
bash {{PRIMARY_SCRIPT}} --mode bogus 2>/dev/null; [ $? -ne 0 ]

# Layer 2 — Contract / Fixture
# STAGE9_HYGIENE_SKIP=1 bash {{PRIMARY_SCRIPT}} --project-id {{OFFLINE_PROJECT_ID}} | jq -e '.status'
# jq -e '{{SHAPE_CHECK}}' code/test_fixtures/{{FIXTURE_FILE}}
```
Expected: all commands exit 0 or expected non-zero as noted above.

### Integration Gate (Layer 3)
Executor: user or CI. This is the single primary live acceptance gate.
Duration target: < 60 seconds. Requires live DB / localhost stack when applicable.
```bash
export PROJECT_ID={{PROJECT_ID_PLACEHOLDER}}
export STAGE9_GATE_TIMEOUT_S=60

# Optional stale-process cleanup for heavy UI tasks
lsof -t -i:8787 | xargs kill 2>/dev/null || true

{{PRIMARY_INTEGRATION_COMMAND}}
```
Expected: {{INTEGRATION_EXPECTED_OUTPUT}}

### Visual (Layer 4)
Executor: user. Include only if the task touches UI / HTML preview.
```bash
# A. HTML structure check (< 5 seconds, no browser)
grep -q 'render_profile="{{EXPECTED_RENDER_PROFILE}}"' {{VISUAL_HTML_PATH}}
grep -q 'data-section="{{EXPECTED_SECTION_1}}"' {{VISUAL_HTML_PATH}}
grep -q 'data-section="{{EXPECTED_SECTION_2}}"' {{VISUAL_HTML_PATH}}

# B. Manual browser open
open {{VISUAL_HTML_PATH}}
```
Send back:
- screenshot OR
- confirmed checklist:
  - [ ] render_profile matches
  - [ ] required sections are visible
  - [ ] no obvious layout breakage

### Diagnostics (optional, non-blocking)
Run only when:
- the primary acceptance gate failed, or
- the user explicitly requested diagnostics, or
- the task itself is explicitly about benchmark / diagnostic behavior
```bash
{{DIAGNOSTIC_COMMAND_1}}
{{DIAGNOSTIC_COMMAND_2}}
```
Expected: diagnostics only; must not replace primary acceptance evidence.

## What to send back for validation
- Layer 1+2: pass/fail per offline Codex acceptance command
- Layer 3: JSON output of {{PRIMARY_INTEGRATION_SCRIPT}} with status/blockers
- Layer 4 (if UI task): screenshot or confirmed checklist
- Diagnostics (if run): exact command + exact stdout/stderr
