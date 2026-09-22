#!/bin/bash
# 既存ファイルの扱いを検査する。
# 既存 repo に適用したとき、その repo 独自の CONTRIBUTING.md や SECURITY.md などを
# 確認なしに上書きすると、独自の方針が消える。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLY="$SCRIPT_DIR/apply-templates.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-overwrite.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# テンプレートが生成しうるファイルに、既存の独自内容を置く
EXISTING=(
  CODE_OF_CONDUCT.md
  CONTRIBUTING.md
  SECURITY.md
  README.ja.md
  pyproject.toml
  docs/TESTING.md
  .github/PULL_REQUEST_TEMPLATE.md
  .github/ISSUE_TEMPLATE/bug_report.yml
  .github/dependabot.yml
  .github/workflows/security.yml
  .github/workflows/lint.yml
  .changeset/README.md
)

seed() {
  local target="$1"
  local f
  for f in "${EXISTING[@]}"; do
    mkdir -p "$target/$(dirname "$f")"
    printf 'ORIGINAL %s\n' "$f" >"$target/$f"
  done
  # 利用者自身の .template ファイルと、置換変数の文字列を含む利用者の workflow
  printf 'mine\n' >"$target/.github/own.yml.template"
  printf 'name: {{PROJECT_NAME}}\n' >"$target/.github/workflows/own.yml"
}

assert_original() {
  local target="$1" f
  for f in "${EXISTING[@]}"; do
    grep -Fxq "ORIGINAL $f" "$target/$f" || fail "$f must be preserved"
  done
  [ -f "$target/.github/own.yml.template" ] || fail "user's own .template file must not be deleted"
  grep -Fq '{{PROJECT_NAME}}' "$target/.github/workflows/own.yml" || fail "placeholders in files not written by the script must not be replaced"
}

# 1) 既定: 既存ファイルは保持し、スキップを表示する
t="$TEST_ROOT/default"
seed "$t"
out="$(bash "$APPLY" "$t" p owner repo --lang=python 2>&1)"
assert_original "$t"
echo "$out" | grep -Fq "skip (exists): CONTRIBUTING.md" || fail "skipped files must be reported"
[ -f "$t/.github/ISSUE_TEMPLATE/feature_request.yml" ] || fail "missing files must still be created"

# 2) --dry-run: 既存があっても無くても、何も書き込まない
t="$TEST_ROOT/dry-existing"
seed "$t"
before="$(cd "$t" && find . -type f -exec shasum {} + | sort)"
out="$(bash "$APPLY" "$t" p owner repo --lang=node --license=mit --dry-run 2>&1)"
after="$(cd "$t" && find . -type f -exec shasum {} + | sort)"
[ "$before" = "$after" ] || fail "--dry-run must not change any file"
echo "$out" | grep -Fq "would create: LICENSE" || fail "--dry-run must list files it would create"
echo "$out" | grep -Fq "skip (exists): SECURITY.md" || fail "--dry-run must list files it would skip"

t="$TEST_ROOT/dry-empty"
mkdir -p "$t"
bash "$APPLY" "$t" p owner repo --lang=node --dry-run >/dev/null 2>&1
[ -z "$(ls -A "$t")" ] || fail "--dry-run on an empty directory must not create anything"

# 3) --force: 既存ファイルを上書きする（利用者の他のファイルには触れない）
t="$TEST_ROOT/force"
seed "$t"
out="$(bash "$APPLY" "$t" p owner repo --lang=python --force 2>&1)"
! grep -Fxq "ORIGINAL CONTRIBUTING.md" "$t/CONTRIBUTING.md" || fail "--force must overwrite CONTRIBUTING.md"
! grep -Fxq "ORIGINAL pyproject.toml" "$t/pyproject.toml" || fail "--force must overwrite pyproject.toml"
echo "$out" | grep -Fq "overwrite: CONTRIBUTING.md" || fail "--force must report overwritten files"
[ -f "$t/.github/own.yml.template" ] || fail "--force must not delete user's own .template file"
grep -Fq '{{PROJECT_NAME}}' "$t/.github/workflows/own.yml" || fail "--force must not touch files the templates do not provide"

# 4) --force は Node の package.json / package-lock.json にも効く
t="$TEST_ROOT/node-force"
mkdir -p "$t"
printf '{"name": "ORIGINAL"}\n' >"$t/package.json"
bash "$APPLY" "$t" p owner repo --lang=node >/dev/null 2>&1
grep -Fq '"name": "ORIGINAL"' "$t/package.json" || fail "existing package.json must be kept without --force"
[ ! -e "$t/package-lock.json" ] || fail "package-lock.json must not be created next to a kept package.json"
bash "$APPLY" "$t" p owner repo --lang=node --force >/dev/null 2>&1
! grep -Fq '"name": "ORIGINAL"' "$t/package.json" || fail "--force must overwrite package.json"
grep -Fq '"lint:md"' "$t/package.json" || fail "--force must write the template package.json"
[ -f "$t/package-lock.json" ] || fail "--force must write package-lock.json with the template package.json"

# 5) --dry-run --update-actions は、動かしていない退避を完了と表示しない
t="$TEST_ROOT/dry-update-actions"
mkdir -p "$t/.github/workflows"
printf 'legacy-ci\n' >"$t/.github/workflows/ci.yml"
printf 'legacy-lint\n' >"$t/.github/workflows/lint.yml"
printf 'legacy-release\n' >"$t/.github/workflows/release.yml"
before="$(cd "$t" && find . -type f -exec shasum {} + | sort)"
out="$(bash "$APPLY" "$t" p owner repo --lang=node --update-actions --dry-run 2>&1)"
after="$(cd "$t" && find . -type f -exec shasum {} + | sort)"
[ "$before" = "$after" ] || fail "--dry-run --update-actions must not change any file"
! echo "$out" | grep -Fq "✓" || fail "--dry-run must not report completed actions (✓): $(echo "$out" | grep -F "✓")"
echo "$out" | grep -Fq "would run: mv" || fail "--dry-run must show the planned move of legacy workflows"
! echo "$out" | grep -Fq "applied successfully" || fail "--dry-run must not claim that templates were applied"

echo "All overwrite tests passed."
