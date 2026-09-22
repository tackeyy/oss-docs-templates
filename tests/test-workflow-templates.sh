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

assert_not_contains() {
  local file="$1"
  local pattern="$2"
  ! grep -Fq -- "$pattern" "$file" || fail "$file unexpectedly contains: $pattern"
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
    "--lang=$language" \
    --conduct-contact=conduct@example.org >/dev/null
}

for language in node go python shell swift; do
  generate_templates "$language"
  assert_job_count "$TEST_ROOT/$language/.github/workflows/security.yml" 1
  assert_contains "$TEST_ROOT/$language/.github/workflows/security.yml" "cancel-in-progress: true"
  assert_contains "$TEST_ROOT/$language/.github/workflows/security.yml" "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1"
  assert_contains "$TEST_ROOT/$language/.github/workflows/security.yml" "gitleaks\" git --redact"
done

node_ci="$TEST_ROOT/node/.github/workflows/ci.yml"
assert_not_exists "$TEST_ROOT/node/.github/workflows/lint.yml"
assert_not_exists "$TEST_ROOT/node/.github/workflows/release.yml"
assert_job_count "$node_ci" 2
assert_contains "$node_ci" "actions/setup-node@820762786026740c76f36085b0efc47a31fe5020 # v7.0.0"
assert_contains "$node_ci" "node-version: '24'"
assert_contains "$node_ci" "actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1"
assert_not_contains "$node_ci" "actions/checkout@v4"
assert_not_contains "$node_ci" "actions/setup-node@v4"
assert_not_contains "$node_ci" "actions/upload-artifact@v4"
assert_contains "$node_ci" "npm run typecheck --if-present"
assert_contains "$node_ci" "npm run lint:md"
assert_contains "$node_ci" "npm run lint:yaml"
assert_contains "$node_ci" "ludeeus/action-shellcheck"
assert_contains "$node_ci" "npm run test --if-present"
assert_contains "$node_ci" "npm run build --if-present"
assert_contains "$node_ci" "if: failure()"
assert_contains "$node_ci" "retention-days: 1"
assert_contains "$node_ci" "release-configured:"
assert_contains "$node_ci" "steps.release-config.outputs.configured"
assert_contains "$node_ci" "needs: quality"
assert_contains "$node_ci" "github.event_name == 'push'"
assert_contains "$node_ci" "needs.quality.outputs.release-configured == 'true'"
assert_contains "$node_ci" "changesets/action@ae32849d5ba541f9ae29e40e22a623bc13562f51 # v2.1.2"
test -f "$TEST_ROOT/node/package-lock.json" || fail "Node template must generate package-lock.json"
assert_contains "$TEST_ROOT/node/package.json" '"node": ">=24"'

go_lint="$TEST_ROOT/go/.github/workflows/lint.yml"
assert_job_count "$go_lint" 1
assert_contains "$go_lint" "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1"
assert_contains "$go_lint" "actions/setup-go@924ae3a1cded613372ab5595356fb5720e22ba16 # v6.5.0"
assert_contains "$go_lint" "golangci/golangci-lint-action"
assert_contains "$go_lint" "go test -race"
assert_contains "$go_lint" "cache: true"
assert_contains "$go_lint" "codecov/codecov-action"

python_lint="$TEST_ROOT/python/.github/workflows/lint.yml"
assert_job_count "$python_lint" 1
assert_contains "$python_lint" "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1"
assert_contains "$python_lint" "actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0"
assert_contains "$python_lint" "python-version: ['3.9', '3.10', '3.11', '3.12']"
assert_contains "$python_lint" "ruff check ."
assert_contains "$python_lint" "mypy ."
assert_contains "$python_lint" "pytest --cov"
assert_contains "$python_lint" "cache: 'pip'"
assert_contains "$python_lint" "matrix.python-version == '3.9'"

shell_lint="$TEST_ROOT/shell/.github/workflows/lint.yml"
assert_job_count "$shell_lint" 1
assert_contains "$shell_lint" "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1"
assert_contains "$shell_lint" "ludeeus/action-shellcheck"
assert_contains "$shell_lint" "shfmt -d -i 2 ."
assert_contains "$shell_lint" "bats tests/"

swift_lint="$TEST_ROOT/swift/.github/workflows/lint.yml"
assert_job_count "$swift_lint" 1
assert_contains "$swift_lint" "actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1"
assert_contains "$swift_lint" "actions/cache@55cc8345863c7cc4c66a329aec7e433d2d1c52a9 # v6.1.0"
assert_contains "$swift_lint" "norio-nomura/action-swiftlint"
assert_contains "$swift_lint" "swift test --enable-code-coverage"
assert_contains "$swift_lint" "codecov/codecov-action"

dependabot="$TEST_ROOT/node/.github/dependabot.yml"
assert_contains "$dependabot" "minor-and-patch"
assert_contains "$dependabot" "github-actions"
assert_contains "$dependabot" "default-days: 7"

migration_target="$TEST_ROOT/node-migration"
mkdir -p "$migration_target/.github/workflows"
printf '%s\n' "legacy-ci" >"$migration_target/.github/workflows/ci.yml"
printf '%s\n' "legacy-lint" >"$migration_target/.github/workflows/lint.yml"
printf '%s\n' "legacy-release" >"$migration_target/.github/workflows/release.yml"
bash "$SCRIPT_DIR/apply-templates.sh" \
  "$migration_target" \
  "test-node-migration" \
  "test-owner" \
  "test-node-migration" \
  --lang=node \
  --conduct-contact=conduct@example.org \
  --update-actions >/dev/null
assert_not_contains "$migration_target/.github/workflows/ci.yml" "legacy-ci"
assert_not_exists "$migration_target/.github/workflows/lint.yml"
assert_not_exists "$migration_target/.github/workflows/release.yml"
assert_contains "$migration_target/.github/workflows/ci.yml.pre-cost-optimization" "legacy-ci"
assert_contains "$migration_target/.github/workflows/lint.yml.disabled" "legacy-lint"
assert_contains "$migration_target/.github/workflows/release.yml.disabled" "legacy-release"

echo "All workflow template tests passed."
