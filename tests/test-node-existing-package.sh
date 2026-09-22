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

echo "All node existing-package tests passed."
