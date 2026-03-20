#!/usr/bin/env bash
# AI Task 009: Stage 3 GitHub ContextJSON connector (read-only).
# Lists JSON files under repository path "contextJSON" via GitHub Contents API.
set -euo pipefail

usage() {
  cat <<'USAGE'
GitHub ContextJSON connector (read-only)

Uses the GitHub Contents API to list files at path "contextJSON" and prints a
normalized JSON array of *.json file entries to stdout.

Required environment:
  GITHUB_OWNER    Repository owner (user or organization)
  GITHUB_REPO     Repository name

Optional environment:
  GITHUB_BRANCH   Branch, tag, or commit SHA (default: main)
  GITHUB_TOKEN    OAuth / personal access token (optional; higher rate limits)

Output (stdout):
  JSON array of objects with fields: name, path, size, sha, download_url

Dependencies:
  curl, jq

Examples:
  export GITHUB_OWNER=octocat GITHUB_REPO=Hello-World
  ./github_contextjson_connector.sh

  export GITHUB_OWNER=octocat GITHUB_REPO=Hello-World GITHUB_BRANCH=develop
  ./github_contextjson_connector.sh

  export GITHUB_TOKEN=ghp_xxx
  ./github_contextjson_connector.sh

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

command -v curl >/dev/null 2>&1 || { echo "error: curl is required" >&2; exit 127; }
command -v jq >/dev/null 2>&1 || { echo "error: jq is required" >&2; exit 127; }

OWNER="${GITHUB_OWNER:-}"
REPO="${GITHUB_REPO:-}"
BRANCH="${GITHUB_BRANCH:-main}"

if [[ -z "$OWNER" || -z "$REPO" ]]; then
  echo "error: GITHUB_OWNER and GITHUB_REPO must be set" >&2
  usage >&2
  exit 1
fi

URL="https://api.github.com/repos/${OWNER}/${REPO}/contents/contextJSON?ref=${BRANCH}"

hdrs=(
  -H "Accept: application/vnd.github+json"
  -H "X-GitHub-Api-Version: 2022-11-28"
  -H "User-Agent: ContextViewer-ContextJSON-Connector"
)
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  hdrs+=( -H "Authorization: Bearer ${GITHUB_TOKEN}" )
fi

tmp="$(mktemp)"
cleanup() { rm -f "$tmp"; }
trap cleanup EXIT

http_code="$(
  curl -sS -o "$tmp" -w '%{http_code}' \
    "${hdrs[@]}" \
    "$URL"
)"

if [[ "$http_code" != "200" ]]; then
  echo "error: GitHub API GET contents/contextJSON failed (HTTP ${http_code})" >&2
  cat "$tmp" >&2 || true
  exit 1
fi

# API returns an array for a directory; a single object if path is one file.
jq '
  (if type == "array" then . else [.] end)
  | map(select(.type == "file"))
  | map(select(.name | test("\\.json$"; "i")))
  | map({
      name: .name,
      path: .path,
      size: .size,
      sha: .sha,
      download_url: .download_url
    })
' <"$tmp"
