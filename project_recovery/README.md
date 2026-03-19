# Recovery Layer

This project uses the recovery system inherited from the template repository.

Recovery is NOT standalone logic.
It inherits:
- command model
- architecture update procedure
- archive-first sync workflow
- contextJSON runtime rules
- response format rules

Project-specific adaptation:
- contextJSON = core runtime source
- system-definition.md = canonical source of truth
- AGENT.md = root-level execution rules
- recovery restores full system via ordered loading

Recovery guarantees:
- full state reconstruction
- no dependency on chat history
- compatibility with inherited template operating system
