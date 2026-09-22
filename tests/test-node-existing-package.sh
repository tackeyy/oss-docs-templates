#!/bin/bash
# 既存の package.json を持つ repo に Node テンプレートを適用したときの検査。
# 適用スクリプトは既存の package.json を保持するので、生成する CI が
# その package.json に無い npm script を必須で呼ぶと、CI が必ず失敗する。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-node-existing.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

target="$TEST_ROOT/project"
mkdir -p "$target"
printf '{\n  "name": "existing",\n  "scripts": { "test": "echo ok" }\n}\n' >"$target/package.json"
out="$(bash "$SCRIPT_DIR/apply-templates.sh" "$target" p owner repo --lang=node --conduct-contact=conduct@example.org 2>&1)"
ci="$target/.github/workflows/ci.yml"

# 1) 既存 package.json は保持される
grep -Fq '"name": "existing"' "$target/package.json" || fail "existing package.json must be preserved"

# 2) CI の npm script 呼び出しは、すべて --if-present 付きである
#    （既存 package.json にどの script があるかは適用先ごとに違うため）
while IFS= read -r line; do
  case "$line" in
    *"--if-present"*) ;;
    *) fail "ci.yml calls an npm script without --if-present: $line" ;;
  esac
done < <(grep -E 'run: npm run ' "$ci")
grep -Eq 'run: npm run lint:md' "$ci" || fail "ci.yml must still run lint:md when present"

# 3) 不足している lint 用 script は適用時に明示される（黙ってスキップしない）
for script in lint:md lint:yaml; do
  echo "$out" | grep -Fq "$script" || fail "apply output must mention missing script $script"
done

# 4) 既存の ci.yml を残す場合は、生成した ci.yml を前提にした警告を出さない（古い ci.yml がそのまま動くため）
t2="$TEST_ROOT/project-with-ci"
mkdir -p "$t2/.github/workflows"
printf '{\n  "name": "existing"\n}\n' >"$t2/package.json"
printf 'name: legacy\n' >"$t2/.github/workflows/ci.yml"
out2="$(bash "$SCRIPT_DIR/apply-templates.sh" "$t2" p owner repo --lang=node --conduct-contact=conduct@example.org 2>&1)"
grep -Fxq 'name: legacy' "$t2/.github/workflows/ci.yml" || fail "existing ci.yml must be kept"
! echo "$out2" | grep -Fq "CI will skip" || fail "must not warn about the generated ci.yml when the existing ci.yml is kept"
! echo "$out2" | grep -Fq "required by ci.yml" || fail "must not claim the kept ci.yml needs package-lock.json"
# --update-actions で差し替える場合は警告する
out3="$(bash "$SCRIPT_DIR/apply-templates.sh" "$t2" p owner repo --lang=node --conduct-contact=conduct@example.org --update-actions 2>&1)"
echo "$out3" | grep -Fq "CI will skip" || fail "must warn when --update-actions replaces ci.yml"

echo "All node existing-package tests passed."
