# 使用例

## 基本的な使い方

### 例1: 新しいCLIツールプロジェクト

```bash
# プロジェクトを作成
mkdir ~/dev/awesome-cli
cd ~/dev/awesome-cli

# テンプレートを適用
bash ~/dev/templates/oss-docs/apply-templates.sh \
  ~/dev/awesome-cli \
  awesome-cli \
  tackeyy \
  awesome-cli \
  --lang=node \
  --conduct-contact=conduct@example.com
```

**実行結果（抜粋）:**
```
Applying OSS documentation templates...
Target: /Users/username/dev/awesome-cli
Project: awesome-cli
Repository: your-username/awesome-cli

Copying base templates...
✓ create: CODE_OF_CONDUCT.md
✓ create: .github/PULL_REQUEST_TEMPLATE.md
✓ create: SECURITY.md

✅ Templates applied successfully!
```

既存のファイルは上書きせず `- skip (exists): <path>` と表示します。

### 例2: 既存プロジェクトに適用

```bash
cd ~/dev/existing-project

# テンプレートを適用
bash ~/dev/templates/oss-docs/apply-templates.sh \
  ~/dev/existing-project \
  existing-project \
  your-username \
  existing-project \
  --conduct-contact=conduct@example.com
```

## プロジェクトタイプ別のカスタマイズ

### Python プロジェクト

```bash
cd ~/dev/python-project
bash ~/dev/templates/oss-docs/apply-templates.sh . python-project tackeyy python-project --lang=python --conduct-contact=conduct@example.com
```

### Go プロジェクト

```bash
cd ~/dev/go-project

bash ~/dev/templates/oss-docs/apply-templates.sh . go-project tackeyy go-project --lang=go --conduct-contact=conduct@example.com
```

### Shell プロジェクト

```bash
cd ~/dev/shell-project
bash ~/dev/templates/oss-docs/apply-templates.sh . shell-project tackeyy shell-project --lang=shell --conduct-contact=conduct@example.com
```

## 高度な使い方

### 複数プロジェクトに一括適用

```bash
#!/bin/bash
# batch-apply.sh

PROJECTS=(
  "~/dev/project-a:project-a:your-username:project-a"
  "~/dev/project-b:project-b:your-username:project-b"
  "~/dev/project-c:project-c:your-username:project-c"
)

for project in "${PROJECTS[@]}"; do
  IFS=':' read -r dir name owner repo <<< "$project"
  echo "Applying to $name..."
  bash ~/dev/templates/oss-docs/apply-templates.sh "$dir" "$name" "$owner" "$repo" --conduct-contact=conduct@example.com
  echo ""
done
```

### カスタムテンプレートの作成

プロジェクトタイプごとに独自のテンプレートを作成:

```bash
# Python用テンプレートディレクトリ作成
cp -r ~/dev/templates/oss-docs ~/dev/templates/oss-docs-python

# カスタマイズ
cd ~/dev/templates/oss-docs-python
# lang-configs/python/ 配下のテンプレートを編集
# ...その他のカスタマイズ
```

## トラブルシューティング

### エラー: "Directory does not exist"

```bash
# ディレクトリを作成してから実行
mkdir -p ~/dev/new-project
bash ~/dev/templates/oss-docs/apply-templates.sh ~/dev/new-project new-project owner repo --conduct-contact=conduct@example.com
```

### エラー: "Permission denied"

```bash
# スクリプトに実行権限を付与
chmod +x ~/dev/templates/oss-docs/apply-templates.sh
```

### 既存のファイルを上書きしたくない / 上書きしたい

既存のファイルは既定で上書きしません。`- skip (exists): <path>` と表示されたものは、元の内容のまま残っています。

```bash
# 何が作成・上書き・スキップされるかを、書き込まずに確認する
bash ~/dev/templates/oss-docs/apply-templates.sh ~/dev/your-project ... --conduct-contact=conduct@example.com --dry-run

# 既存のファイルもテンプレートで上書きする（事前に git で差分を確認できる状態にしておく）
bash ~/dev/templates/oss-docs/apply-templates.sh ~/dev/your-project ... --conduct-contact=conduct@example.com --force
git diff
```

## ベストプラクティス

### 1. 段階的な適用

```bash
# まずテスト用ブランチで試す
git checkout -b add-oss-docs
bash ~/dev/templates/oss-docs/apply-templates.sh ...

# カスタマイズして確認
git diff

# 問題なければコミット
git add .
git commit -m "docs: add OSS contribution guidelines"
```

### 2. プロジェクト固有のカスタマイズを記録

```bash
# カスタマイズ手順をドキュメント化
cat > docs/TEMPLATE_CUSTOMIZATION.md <<EOF
# Template Customization Log

## Applied
- Date: $(date)
- Template version: v1.0
- Script: apply-templates.sh

## Customizations
1. Replaced Vitest with pytest
2. Updated development setup for Python 3.11
3. Added pre-commit hooks documentation
EOF
```

### 3. 定期的な更新

```bash
# テンプレートの最新版を確認
cd ~/dev/templates/oss-docs
git pull

# 変更があればテンプレートを更新
# lang-configs/<language>/CONTRIBUTING.md や TESTING.md を編集

# 既存プロジェクトに差分を反映（選択的に）
cd ~/dev/your-project
diff ~/dev/templates/oss-docs/lang-configs/node/CONTRIBUTING.md CONTRIBUTING.md
```

## チェックリスト

テンプレート適用後の確認項目:

- [ ] `CONTRIBUTING.md` のプロジェクト名が正しい
- [ ] セットアップ手順が動作する
- [ ] テストコマンドが正しい
- [ ] リポジトリURLが正しい
- [ ] Issue/PRテンプレートのラベルが適切
- [ ] `CODE_OF_CONDUCT.md` の連絡先が正しい
- [ ] `README.md` にContributingセクションを追加した
- [ ] テンプレートをコミットした

```bash
# 最終確認
git status
git add .
git commit -m "docs: add OSS contribution guidelines from template"
git push
```
