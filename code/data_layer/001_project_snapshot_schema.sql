-- AI Task 004: Project Entity And Snapshot Schema
-- Stage 2 Data Layer (base entities only)
-- AI Task 006 extension: JSON structure validation rule

CREATE TABLE IF NOT EXISTS projects (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    github_url TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS snapshots (
    id BIGSERIAL PRIMARY KEY,
    -- Keep historical snapshots protected: project deletion is restricted when snapshots exist.
    project_id BIGINT NOT NULL REFERENCES projects(id) ON DELETE RESTRICT,
    file_name TEXT NOT NULL CHECK (
        file_name ~ '^json_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}\.json$'
    ),
    "timestamp" TIMESTAMP GENERATED ALWAYS AS (
        make_timestamp(
            substring(file_name FROM '^json_(\d{4})-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}\.json$')::INT,
            substring(file_name FROM '^json_\d{4}-(\d{2})-\d{2}_\d{2}-\d{2}-\d{2}\.json$')::INT,
            substring(file_name FROM '^json_\d{4}-\d{2}-(\d{2})_\d{2}-\d{2}-\d{2}\.json$')::INT,
            substring(file_name FROM '^json_\d{4}-\d{2}-\d{2}_(\d{2})-\d{2}-\d{2}\.json$')::INT,
            substring(file_name FROM '^json_\d{4}-\d{2}-\d{2}_\d{2}-(\d{2})-\d{2}\.json$')::INT,
            substring(file_name FROM '^json_\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-(\d{2})\.json$')::INT
        )
    ) STORED,
    content_hash TEXT NOT NULL,
    raw_json JSONB NOT NULL,
    is_valid BOOLEAN NOT NULL,
    import_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT snapshots_project_file_name_unique UNIQUE (project_id, file_name),
    CONSTRAINT snapshots_content_hash_unique UNIQUE (content_hash)
);

CREATE OR REPLACE FUNCTION prevent_snapshot_update()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    RAISE EXCEPTION 'snapshots are immutable and cannot be updated';
END;
$$;

CREATE OR REPLACE FUNCTION contextjson_has_required_sections(payload JSONB)
RETURNS BOOLEAN
LANGUAGE sql
IMMUTABLE
AS $$
    SELECT
        jsonb_typeof(payload) = 'object'
        AND payload ? 'project'
        AND payload ? 'system'
        AND payload ? 'progress'
        AND payload ? 'roadmap'
        AND payload ? 'changes_since_previous'
        AND jsonb_typeof(payload->'project') = 'object'
        AND jsonb_typeof(payload->'system') = 'object'
        AND jsonb_typeof(payload->'progress') = 'object'
        AND jsonb_typeof(payload->'roadmap') = 'array'
        AND jsonb_typeof(payload->'changes_since_previous') = 'array';
$$;

DROP TRIGGER IF EXISTS snapshots_no_update ON snapshots;

CREATE TRIGGER snapshots_no_update
BEFORE UPDATE ON snapshots
FOR EACH ROW
EXECUTE FUNCTION prevent_snapshot_update();

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'snapshots_is_valid_matches_json_structure'
    ) THEN
        ALTER TABLE snapshots
        ADD CONSTRAINT snapshots_is_valid_matches_json_structure
        CHECK (is_valid = contextjson_has_required_sections(raw_json)) NOT VALID;
    END IF;
END;
$$;
