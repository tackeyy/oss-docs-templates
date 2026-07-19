#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-workflows.XXXXXX")"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_contains() {
  local file="$1"
  local pattern="$2"
  grep -Fq -- "$pattern" "$file" || fail "$file does not contain: $pattern"
}

assert_not_exists() {
  local file="$1"
  [ ! -e "$file" ] || fail "$file should not exist"
}

assert_job_count() {
  local file="$1"
  local expected="$2"
  local actual

  actual="$({
    awk '
      /^jobs:$/ { in_jobs = 1; next }
      in_jobs && /^[^ ]/ { in_jobs = 0 }
      in_jobs && /^  [A-Za-z0-9_-]+:$/ { count++ }
      END { print count + 0 }
    ' "$file"
  })"

  [ "$actual" = "$expected" ] || fail "$file has $actual jobs; expected $expected"
}

generate_templates() {
  local language="$1"
  local target="$TEST_ROOT/$language"

  mkdir -p "$target"
  bash "$SCRIPT_DIR/apply-templates.sh" \
    "$target" \
    "test-$language" \
    "test-owner" \
    "test-$language" \
    "--lang=$language" >/dev/null
}

for language in node go python shell swift; do
  generate_templates "$language"
  assert_job_count "$TEST_ROOT/$language/.github/workflows/security.yml" 1
  assert_contains "$TEST_ROOT/$language/.github/workflows/security.yml" "cancel-in-progress: true"
  assert_contains "$TEST_ROOT/$language/.github/workflows/security.yml" "actions/checkout@v6"
  assert_contains "$TEST_ROOT/$language/.github/workflows/security.yml" "gitleaks/gitleaks-action@v3"
done

node_ci="$TEST_ROOT/node/.github/workflows/ci.yml"
assert_not_exists "$TEST_ROOT/node/.github/workflows/lint.yml"
assert_job_count "$node_ci" 1
assert_contains "$node_ci" "npm run typecheck"
assert_contains "$node_ci" "npm run lint:md"
assert_contains "$node_ci" "npm run lint:yaml"
assert_contains "$node_ci" "ludeeus/action-shellcheck"
assert_contains "$node_ci" "npm test"
assert_contains "$node_ci" "npm run build"
assert_contains "$node_ci" "if: failure()"
assert_contains "$node_ci" "retention-days: 1"

go_lint="$TEST_ROOT/go/.github/workflows/lint.yml"
assert_job_count "$go_lint" 1
assert_contains "$go_lint" "golangci/golangci-lint-action"
assert_contains "$go_lint" "go test -race"
assert_contains "$go_lint" "cache: true"
assert_contains "$go_lint" "codecov/codecov-action"

python_lint="$TEST_ROOT/python/.github/workflows/lint.yml"
assert_job_count "$python_lint" 1
assert_contains "$python_lint" "python-version: ['3.9', '3.10', '3.11', '3.12']"
assert_contains "$python_lint" "ruff check ."
assert_contains "$python_lint" "mypy ."
assert_contains "$python_lint" "pytest --cov"
assert_contains "$python_lint" "cache: 'pip'"
assert_contains "$python_lint" "matrix.python-version == '3.9'"

shell_lint="$TEST_ROOT/shell/.github/workflows/lint.yml"
assert_job_count "$shell_lint" 1
assert_contains "$shell_lint" "ludeeus/action-shellcheck"
assert_contains "$shell_lint" "shfmt -d -i 2 ."
assert_contains "$shell_lint" "bats tests/"

swift_lint="$TEST_ROOT/swift/.github/workflows/lint.yml"
assert_job_count "$swift_lint" 1
assert_contains "$swift_lint" "norio-nomura/action-swiftlint"
assert_contains "$swift_lint" "swift test --enable-code-coverage"
assert_contains "$swift_lint" "actions/cache@v4"
assert_contains "$swift_lint" "codecov/codecov-action"

dependabot="$TEST_ROOT/node/.github/dependabot.yml"
assert_contains "$dependabot" "minor-and-patch"
assert_contains "$dependabot" "github-actions"
assert_contains "$dependabot" "default-days: 7"

echo "All workflow template tests passed."
