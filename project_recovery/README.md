# Recovery Layer

This project uses template-based recovery system.

Recovery is NOT standalone logic.
It inherits:

- command model
- architecture update procedure
- archive-first sync workflow
- contextJSON runtime rules

Project-specific adaptation:

- contextJSON = core runtime
- system-definition.md = canonical source
- recovery restores full system via ordered loading

Recovery guarantees:

- full state reconstruction
- no dependency on chat history
- compatibility with template OS
