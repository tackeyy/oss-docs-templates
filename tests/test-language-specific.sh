#!/bin/bash
# 言語共通の base に npm 前提の物が混ざっていないかを検査する。
# Go や Swift などを選んだ repo に npm の dependabot 設定や changeset の説明が配られると、
# dependabot が失敗したり、存在しないリリース手順を案内したりする。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLY="$SCRIPT_DIR/apply-templates.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-lang.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

gen() {
  local name="$1"
  shift
  mkdir -p "$TEST_ROOT/$name"
  bash "$APPLY" "$TEST_ROOT/$name" p owner repo "$@" >/dev/null
  echo "$TEST_ROOT/$name"
}

ecosystems() {
  sed -nE 's/.*package-ecosystem: "?([a-z-]+)"?.*/\1/p' "$1/.github/dependabot.yml" | sort | tr '\n' ' '
}

# language -> expected dependabot ecosystems (github-actions is always present) and test command
check_lang() {
  local lang="$1" expected="$2" test_cmd="$3" dir
  dir="$(gen "$lang" --lang="$lang")"
  [ "$(ecosystems "$dir")" = "$expected" ] || fail "$lang: dependabot ecosystems are '$(ecosystems "$dir")', expected '$expected'"
  grep -Fq -- "$test_cmd" "$dir/.github/PULL_REQUEST_TEMPLATE.md" || fail "$lang: PR template must mention '$test_cmd'"
  ! grep -Eq '\{\{[A-Z_]+\}\}' "$dir/.github/PULL_REQUEST_TEMPLATE.md" || fail "$lang: PR template has an unreplaced placeholder"
  if [ "$lang" = node ]; then
    [ -f "$dir/.changeset/README.md" ] || fail "node: changeset README must be generated"
  else
    [ ! -e "$dir/.changeset" ] || fail "$lang: changeset files must not be generated"
    ! grep -Fq "npm" "$dir/.github/PULL_REQUEST_TEMPLATE.md" || fail "$lang: PR template must not mention npm"
  fi
}

check_lang node "github-actions npm " "npm test"
check_lang go "github-actions gomod " "go test ./..."
check_lang python "github-actions pip " "pytest"
check_lang swift "github-actions swift " "swift test"
check_lang shell "github-actions " "bats tests/"

# 言語指定なし: GitHub Actions の更新だけ、npm 前提物なし
dir="$(gen none)"
[ "$(ecosystems "$dir")" = "github-actions " ] || fail "no --lang: dependabot must only cover github-actions"
[ ! -e "$dir/.changeset" ] || fail "no --lang: changeset files must not be generated"
! grep -Fq "npm" "$dir/.github/PULL_REQUEST_TEMPLATE.md" || fail "no --lang: PR template must not mention npm"
! grep -Eq '\{\{[A-Z_]+\}\}' "$dir/.github/PULL_REQUEST_TEMPLATE.md" || fail "no --lang: PR template has an unreplaced placeholder"

# changeset の説明は実在するリリース方式を指す（存在しない release.yml を案内しない）
node_dir="$TEST_ROOT/node"
! grep -Fq "release.yml" "$node_dir/.changeset/README.md" || fail "changeset README must not refer to a non-existent release.yml"
grep -Fq "ci.yml" "$node_dir/.changeset/README.md" || fail "changeset README must point to the release job in ci.yml"

echo "All language-specific tests passed."
