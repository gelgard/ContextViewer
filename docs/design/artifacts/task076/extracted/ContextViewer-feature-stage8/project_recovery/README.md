# Recovery Layer

This project uses the recovery system inherited from the template repository.

Recovery is NOT standalone logic.
It inherits:
- command model
- architecture update procedure
- workspace-first sync workflow (archive fallback only when workspace is unavailable)
- contextJSON runtime rules
- response format rules

Project-specific adaptation:
- contextJSON = core runtime source
- system-definition.md = canonical source of truth
- AGENTS.md = root-level execution rules
- recovery restores full system via ordered loading

Recovery guarantees:
- full state reconstruction
- no dependency on chat history
- compatibility with inherited template operating system
