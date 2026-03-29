# Диагностика зацикливания Codex на AI Task 090/091 и рекомендации

## 1. Полная картина проекта

**ContextViewer** — система визуализации AI-проектного контекста (contextJSON). Архитектура построена на шаблоне "Project OS" — строгая иерархия: architecture > plans > ai_tasks > code. Вся работа ведется через нумерованные AI-задачи, каждая с acceptance criteria, Cursor-промтом и manual-тестами.

**Текущее состояние:** Stage 9 (Secondary Flows & Release Readiness), задачи 084–089 закрыты. Task 090 частично закрыт (fast/full split для верификаторов). Task 091 (benchmark harness + runtime hygiene) — **точка зацикливания**.

**Финал проекта:** полностью contract-backed preview/dashboard система с diff-viewer, settings, history, visualization workspace, оркестрированная через shell-скрипты с JSON-выводом, gate-driven transition между стадиями.

---

## 2. Корневая причина зацикливания

Проблема не в логике кода — она в **архитектуре самих тестов и структуре задачи**.

### 2.1. Матрёшка вложенных вызовов

```
run_stage9_validation_runtime_benchmark.sh (334 строки)
  └─ ensure_stage9_validation_runtime_hygiene.sh (×3: pre, between, post)
  └─ get_stage9_completion_gate_report.sh (613 строк) ×2 (fast + full)
       └─ ensure_stage9_validation_runtime_hygiene.sh
       └─ verify_stage9_diff_viewer_contracts.sh (186)
       └─ verify_stage9_settings_profile_contracts.sh (186)
       └─ get_stage8_ui_preview_readiness_report.sh (495)
            └─ verify_stage8_ui_preview_delivery.sh (381)
            └─ start_ui_preview_server.sh (225)
            └─ render_ui_bootstrap_preview.sh (2204!)
       └─ verify_stage8_ui_demo_handoff_bundle.sh (382)
       └─ verify_stage9_secondary_flows_readiness_gate.sh (429)
```

**Итого:** benchmark запускает ~12–18 дочерних процессов, каждый с python3-обёрткой для timeout, каждый с child_timeout_s=420 (7 минут!). Суммарный worst-case = **42+ минут** на один прогон benchmark. Codex с его ограничениями по времени и контексту физически не может дождаться результата.

### 2.2. Реальные зависимости от инфраструктуры

Скрипты требуют: `psql` (Neon PostgreSQL), `curl` (HTTP-эндпоинты), запуск `python3 -m http.server`, живую базу данных с реальным `project_id`. В CI/Codex-среде:
- Neon DB может быть недоступен → timeout на DNS/connection
- HTTP-сервер не стартует или порт занят → висящий процесс
- Гигиена портов (lsof/pgrep) может не сработать

### 2.3. Задача 091 слишком "толстая"

AI Task 091 совмещает 4 независимых deliverable:
1. Runtime hygiene скрипт
2. Модификация трех существующих верификаторов
3. Benchmark harness
4. Closure evidence (доказательство ускорения)

Codex пытается одновременно написать код, запустить тесты, получить benchmark-доказательство — и зацикливается, потому что benchmark зависит от инфраструктуры, которой нет.

---

## 3. Рекомендации по решению

### Стратегия А: Декомпозиция задачи (обязательно)

**Разбить AI Task 091 на 3 микро-задачи:**

**091a — Runtime Hygiene Script (только код, без запуска тяжелых тестов)**
```
Acceptance: файл создан, --help выводит usage,
unit-тест: bash ensure_stage9_validation_runtime_hygiene.sh --port 9999 --no-clean
возвращает JSON с status "ok" (на пустой среде).
Timeout на тест: 10 секунд.
```

**091b — Verifier Integration (обновить 3 скрипта для hygiene preflight)**
```
Acceptance: каждый скрипт принимает STAGE9_HYGIENE_SKIP=1.
Тест: STAGE9_HYGIENE_SKIP=1 bash verify_stage9_completion_gate.sh --project-id 1 --mode fast
должен вернуть JSON (допустим fail по контракту, но не hang/crash).
Timeout: 30 секунд.
```

**091c — Benchmark Harness (только скрипт + dry-run)**
```
Acceptance: скрипт создан, --help работает.
Тест: запуск с несуществующим project-id → JSON с status=fail
и blocker_class=contract_logic, exit ≠ 0.
Timeout: 30 секунд.
Closure evidence: отдельный ручной прогон вне Codex.
```

### Стратегия Б: Изменить acceptance criteria для Codex-задач

**Текущая проблема:** acceptance criteria включают end-to-end прогон на живом стеке. Codex не имеет доступа к Neon DB и HTTP-серверу.

**Новое правило для AGENTS.md:**
```markdown
## 8.2 CODEX EXECUTION BOUNDARY

Codex-agent acceptance criteria must be verifiable WITHOUT:
- live database connections (Neon/PostgreSQL)
- running HTTP servers
- network-dependent child processes

Acceptable Codex acceptance patterns:
- file existence + syntax checks (bash -n, jq --slurp /dev/null)
- CLI argument validation (--help, missing args, invalid args → correct exit codes)
- dry-run / mock-mode outputs
- JSON schema shape validation on static fixtures
- unit-level script behavior (STAGE9_HYGIENE_SKIP=1, mock project-id)

Full integration validation (live DB, HTTP, benchmark timing) must be
explicitly marked as "manual validation" or "CI validation" and excluded
from the Codex acceptance gate.
```

### Стратегия В: Промт-инженерия для Codex

**Проблема текущих промтов:** слишком абстрактное описание задачи + acceptance criteria, которые требуют полной интеграции.

**Шаблон промта для Codex, который ломает цикл:**

```markdown
# Codex Task: [название]

## SCOPE LOCK
You are modifying ONLY these files:
- [точный список файлов]

You must NOT:
- run any script that requires psql, curl to external DB, or HTTP server startup
- attempt end-to-end validation
- modify files outside the scope list

## IMPLEMENTATION STEPS (exact order)
1. Read file X (lines A–B)
2. Add function Y after line Z
3. Update usage() to document new --mode flag
4. [каждый шаг максимально конкретный]

## VALIDATION (Codex-safe, max 30 seconds total)
```bash
# Step 1: syntax check
bash -n code/ui/ensure_stage9_validation_runtime_hygiene.sh

# Step 2: help text includes new flag
bash code/ui/ensure_stage9_validation_runtime_hygiene.sh --help 2>&1 | grep -q "clean"

# Step 3: skip mode returns JSON
STAGE9_HYGIENE_SKIP=1 bash code/ui/ensure_stage9_validation_runtime_hygiene.sh | jq -e '.status == "ok"'

# Step 4: invalid args → exit 2
bash code/ui/ensure_stage9_validation_runtime_hygiene.sh --mode bogus 2>/dev/null; [ $? -eq 2 ]
```

## EXIT CRITERIA
All 4 validation commands pass with exit 0. Nothing else required.
```

### Стратегия Г: Добавить timeout ceiling в AGENTS.md

```markdown
## 8.3 VALIDATION TIMEOUT POLICY

- Codex validation commands: max 30 seconds each, max 120 seconds total
- Manual validation commands: max 300 seconds each
- Benchmark/integration: explicitly bounded, not part of Codex acceptance
- Any command exceeding its ceiling is a BLOCKED condition, not a retry loop
- If a test exceeds ceiling: stop, classify as env/infra blocker, report, move on
```

### Стратегия Д: Mock-layer для offline-валидации

Создать `code/test_fixtures/` с:
```
mock_completion_gate_report_ready.json    — эталонный JSON для ready_for_stage_transition
mock_completion_gate_report_not_ready.json
mock_hygiene_ok.json
mock_diff_verify_pass.json
```

Тогда Codex может валидировать JSON-shape парсинг и jq-фильтры по фикстурам, а не по живому стеку.

**Промт для создания fixture-задачи:**
```markdown
Create static JSON test fixtures in code/test_fixtures/ that represent
canonical outputs of each Stage 9 verifier script. Use these fixtures
to validate jq parsing logic, JSON shape contracts, and blocker
classification without running live infrastructure.

Files to create:
- mock_hygiene_ok.json (status: "ok", ports_checked: [8787], ...)
- mock_completion_report_ready.json (full shape per get_stage9_completion_gate_report.sh)
- mock_completion_report_not_ready.json (status: "not_ready", blockers: [...])
- mock_benchmark_pass.json (fast_seconds < full_seconds, status: pass)

Validation: jq -e '.status' < each fixture must succeed.
```

---

## 4. Исправление response format / context engineering

### 4.1. В AGENTS.md раздел 11 (Response Format Rules) добавить:

```markdown
- Cursor prompt for Codex must include:
  - exact timeout per validation command (in seconds)
  - explicit STAGE9_HYGIENE_SKIP=1 or equivalent mock flags
  - NO commands that require live DB or HTTP server unless marked "(manual only)"
  - validation commands must be copy-paste runnable in an isolated shell
```

### 4.2. В шаблоне AI Task добавить новую секцию:

```markdown
## Codex Validation Profile
Execution environment: offline (no DB, no HTTP, no network)
Max single command timeout: 30s
Max total validation timeout: 120s
Required env flags: STAGE9_HYGIENE_SKIP=1
Mock data: code/test_fixtures/mock_*.json (if applicable)
```

### 4.3. Cursor prompt structure — антициклический паттерн:

```markdown
## ANTI-LOOP RULES (for Codex)
1. If a validation command takes > 30 seconds: STOP. Mark as infra-blocker.
2. If the same validation fails 2 times with identical output: STOP.
   Report the exact error, do not retry.
3. If a command requires psql/curl to an external endpoint and it times out:
   classify as env_network, skip, mark in output.
4. Never re-run a full integration test hoping it will pass.
   Only re-run after a code change that addresses the specific failure.
```

---

## 5. Конкретный план выхода из текущего тупика

### Шаг 1: Зафиксировать текущее состояние
Task 090 уже закрыт (fast/full split работает). Скрипты 091 уже созданы (`ensure_stage9_validation_runtime_hygiene.sh`, `run_stage9_validation_runtime_benchmark.sh`).

### Шаг 2: Закрыть 091 по offline-критериям
```bash
# Все эти команды должны пройти за < 30 секунд каждая:

# 1. Syntax
bash -n code/ui/ensure_stage9_validation_runtime_hygiene.sh
bash -n code/ui/run_stage9_validation_runtime_benchmark.sh

# 2. Help text
bash code/ui/ensure_stage9_validation_runtime_hygiene.sh --help | grep -q "clean"
bash code/ui/run_stage9_validation_runtime_benchmark.sh --help | grep -q "benchmark"

# 3. Skip hygiene
STAGE9_HYGIENE_SKIP=1 bash code/ui/ensure_stage9_validation_runtime_hygiene.sh | jq -e '.status == "ok"'

# 4. Bad CLI args
bash code/ui/run_stage9_validation_runtime_benchmark.sh 2>/dev/null; [ $? -eq 2 ]
bash code/ui/run_stage9_validation_runtime_benchmark.sh --project-id abc 2>/dev/null; [ $? -eq 2 ]

# 5. README updated
grep -q "runtime_hygiene" code/data_layer/README.md
grep -q "benchmark" code/data_layer/README.md
```

### Шаг 3: Benchmark closure evidence — отдельно, вручную
Запустить на вашей машине с доступом к Neon:
```bash
STAGE9_GATE_TIMEOUT_S=120 bash code/ui/run_stage9_validation_runtime_benchmark.sh \
  --project-id <ваш_id> --port 8787 --fast-port 8787 --full-port 8788
```
Результат JSON → вложить как closure evidence в task validation.

---

## 6. Сводка изменений в системе

| Что менять | Где | Зачем |
|---|---|---|
| Codex execution boundary | AGENTS.md §8.2 | Разделить offline/online валидацию |
| Timeout policy | AGENTS.md §8.3 | Предотвратить бесконечные ожидания |
| Task decomposition rule | AGENTS.md §8 | Макс 1 deliverable = 1 скрипт на задачу |
| Mock fixtures | code/test_fixtures/ | Offline contract validation |
| Cursor prompt anti-loop | AGENTS.md §11 | Явный стоп после 2 идентичных failure |
| Codex Validation Profile | AI Task template | Среда, timeout, mock-флаги |
