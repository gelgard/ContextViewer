# Integration Boundaries

## External Integrations
- GitHub public repository as the read-only source of contextJSON snapshots
- Neon PostgreSQL as the planned persistence layer for projects, snapshots, and import logs

## Internal Boundaries
- UI must not bypass service layer
- domain layer stays pure where possible
- contracts must be explicit
