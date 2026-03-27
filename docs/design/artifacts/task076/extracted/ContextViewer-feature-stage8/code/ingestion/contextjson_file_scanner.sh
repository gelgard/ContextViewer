#!/usr/bin/env bash
# AI Task 010: ContextJSON file scanner (stdin JSON array → validated split + latest valid).
set -euo pipefail

usage() {
  cat <<'USAGE'
ContextJSON file scanner

Reads a JSON array from stdin (e.g. output of github_contextjson_connector.sh). Each
element should have: name, path, size, sha, download_url.

Validates each item's name against: json_YYYY-MM-DD_HH-MM-SS.json

Writes one JSON object to stdout:
  valid_files      — array of { name, path, sha, size, timestamp }
  invalid_files    — array of { name, path, reason }
  latest_valid_file — object with max timestamp among valid_files, or null

The timestamp field is the YYYY-MM-DD_HH-MM-SS portion extracted from the filename.

Dependencies:
  jq

Examples:
  ./github_contextjson_connector.sh | ./contextjson_file_scanner.sh

  curl -s ... | jq . | ./contextjson_file_scanner.sh

Options:
  -h, --help      Show this help and exit
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi
if [[ -n "${1:-}" ]]; then
  echo "error: unknown option: $1" >&2
  usage >&2
  exit 2
fi

command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 127; }

jq '
  def filename_pattern: "^json_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}\\.json$";

  def scan_item:
    . as $item |
    if ($item | type) != "object" then
      {
        valid: false,
        invalid_entry: {
          name: null,
          path: null,
          reason: "item must be a JSON object"
        }
      }
    elif (($item.name // "") | type) != "string" then
      {
        valid: false,
        invalid_entry: {
          name: $item.name,
          path: ($item.path // null),
          reason: "missing or invalid name (expected string)"
        }
      }
    elif ($item.name | test(filename_pattern)) then
      {
        valid: true,
        valid_entry: {
          name: $item.name,
          path: ($item.path // null),
          sha: $item.sha,
          size: $item.size,
          timestamp: (
            $item.name
            | capture("^json_(?<ts>[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2})\\.json$")
            | .ts
          )
        }
      }
    else
      {
        valid: false,
        invalid_entry: {
          name: $item.name,
          path: ($item.path // null),
          reason: "filename does not match json_YYYY-MM-DD_HH-MM-SS.json"
        }
      }
    end;

  if type != "array" then
    error("stdin must be a JSON array")
  else
    map(scan_item)
    | reduce .[] as $x (
        { valid_files: [], invalid_files: [] };
        if $x.valid then
          .valid_files += [$x.valid_entry]
        else
          .invalid_files += [$x.invalid_entry]
        end
      )
    | .latest_valid_file = (
        if (.valid_files | length) == 0 then
          null
        else
          (.valid_files | max_by(.timestamp))
        end
      )
  end
'
