#!/bin/bash
# workflow テンプレートの Action 参照が commit SHA で固定されていることを検査する。
# branch やタグの参照は、参照先が更新されると CI の中身が変わる（OpenSSF Scorecard: Pinned-Dependencies）。
# SHA の横に版をコメントで残し、dependabot（github-actions）がその版を追って SHA を更新できるようにする。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

files=()
while IFS= read -r f; do files+=("$f"); done < <(
  find "$SCRIPT_DIR/base" "$SCRIPT_DIR/lang-configs" "$SCRIPT_DIR/.github/workflows" \
    -type f \( -name '*.yml' -o -name '*.yaml' \) -path '*workflows*' 2>/dev/null | sort
)
[ "${#files[@]}" -gt 0 ] || fail "no workflow files found"

count=0
for f in "${files[@]}"; do
  while IFS= read -r line; do
    count=$((count + 1))
    ref="$(echo "$line" | sed -E 's/.*uses:[[:space:]]*//')"
    echo "$ref" | grep -Eq '^[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+@[0-9a-f]{40}[[:space:]]+#[[:space:]]+v?[0-9]+\.[0-9]+\.[0-9]+$' \
      || fail "${f#"$SCRIPT_DIR"/}: action is not pinned to a commit SHA with a version comment: $ref"
  done < <(grep -E '^[[:space:]]*(-[[:space:]]+)?uses:' "$f" || true)
done
[ "$count" -gt 0 ] || fail "no 'uses:' lines were checked"

# changesets/action v2 は入力名が変わり、トークンは入力で渡す（v1 の名前は無視される）
ci="$SCRIPT_DIR/lang-configs/node/workflows/ci.yml"
for legacy in 'publish:' 'title:' 'commit:'; do
  ! grep -Eq "^[[:space:]]+${legacy}[[:space:]]" "$ci" || fail "node ci.yml uses the changesets/action v1 input '$legacy'"
done
for input in 'publish-script:' 'pr-title:' 'commit-message:' 'github-token:'; do
  grep -Eq "^[[:space:]]+${input}[[:space:]]" "$ci" || fail "node ci.yml must pass the changesets/action v2 input '$input'"
done

echo "All actions pinned tests passed ($count references)."
