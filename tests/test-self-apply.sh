#!/bin/bash
# repo 自身の .github が、このリポジトリへ apply-templates.sh を適用した
# 生成物とバイト単位で一致することを検査する。
# テンプレートだけ直して repo 自身が古いままだと、配る設定と自分の設定がずれ、
# 検査が空回りする。生成物が 0 件のときも失敗する。
# .github 配下にシンボリックリンクが 1 つでもあれば、生成物側・repo 側とも失敗する
# （テンプレートは symlink を生成しない）。ファイルの列挙は通常ファイルのみ。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPLY="$SCRIPT_DIR/apply-templates.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/oss-docs-self-apply.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

# このリポジトリ固有で、apply-templates.sh は生成しない。
# workflows/ci.yml はこのリポジトリ自身の CI。
# python-tools-requirements.txt は CI が入れる Python ツールの版とハッシュの固定。
# 生成物に無い .github のファイルは、この一覧に無ければ失敗する。一覧はここだけ。
REPO_ONLY=(
  ".github/workflows/ci.yml"
  ".github/python-tools-requirements.txt"
)

is_repo_only() {
  local path="$1"
  local allowed
  for allowed in "${REPO_ONLY[@]}"; do
    if [ "$allowed" = "$path" ]; then
      return 0
    fi
  done
  return 1
}

list_github_files() {
  local root="$1"
  (cd "$root" && find .github -type f | sort)
}

# find -type f は symlink を省き、cmp はリンク先をたどる。
# テンプレートは symlink を生成しないので、1 つでもあれば失敗させる。
assert_no_github_symlinks() {
  local root="$1"
  local side="$2"
  local link
  while IFS= read -r link; do
    [ -n "$link" ] || continue
    fail "$side .github contains a symlink: $link"
  done < <(cd "$root" && find .github -type l | sort)
}

target="$TEST_ROOT/applied"
mkdir -p "$target"
git -C "$target" init -q
bash "$APPLY" "$target" oss-docs-templates tackeyy oss-docs-templates \
  --conduct-contact=conduct@example.invalid >/dev/null \
  || fail "apply-templates.sh must succeed"

assert_no_github_symlinks "$target" "generated"
assert_no_github_symlinks "$SCRIPT_DIR" "repo"

generated=()
while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  generated+=("$rel")
done < <(list_github_files "$target")
[ "${#generated[@]}" -gt 0 ] || fail "generated .github has no files; the check would pass without comparing anything"

for rel in "${generated[@]}"; do
  [ -f "$SCRIPT_DIR/$rel" ] || fail "repo is missing generated file: $rel"
  cmp -s "$target/$rel" "$SCRIPT_DIR/$rel" || fail "repo .github does not match generated file: $rel"
done

while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  if is_repo_only "$rel"; then
    continue
  fi
  [ -f "$target/$rel" ] || fail "repo has a .github file that apply-templates.sh does not generate: $rel"
done < <(list_github_files "$SCRIPT_DIR")

echo "All self-apply tests passed."
