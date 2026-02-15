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
  awesome-cli
```

**実行結果:**
```
Applying OSS documentation templates...
Target: /Users/tackeyy/dev/awesome-cli
Project: awesome-cli
Repository: tackeyy/awesome-cli

✓ CODE_OF_CONDUCT.md copied
✓ CONTRIBUTING.md copied and customized
✓ docs/TESTING.md copied and customized
✓ .github templates copied and customized

✅ Templates applied successfully!
```

### 例2: 既存プロジェクトに適用

```bash
cd ~/dev/existing-project

# テンプレートを適用
bash ~/dev/templates/oss-docs/apply-templates.sh \
  ~/dev/existing-project \
  existing-project \
  your-username \
  existing-project
```

## プロジェクトタイプ別のカスタマイズ

### Python プロジェクト

テンプレート適用後、以下を手動で置換:

```bash
cd ~/dev/python-project

# CONTRIBUTING.md
sed -i '' 's/npm install/pip install -r requirements.txt/g' CONTRIBUTING.md
sed -i '' 's/npm test/pytest/g' CONTRIBUTING.md
sed -i '' 's/npm run build/python setup.py build/g' CONTRIBUTING.md
sed -i '' 's/Node.js 18+/Python 3.9+/g' CONTRIBUTING.md

# docs/TESTING.md
sed -i '' 's/Vitest/pytest/g' docs/TESTING.md
sed -i '' 's/npm test/pytest/g' docs/TESTING.md
sed -i '' 's/\.test\.ts/_test.py/g' docs/TESTING.md
```

### Go プロジェクト

```bash
cd ~/dev/go-project

# CONTRIBUTING.md
sed -i '' 's/npm install/go mod download/g' CONTRIBUTING.md
sed -i '' 's/npm test/go test .\/\.\.\./g' CONTRIBUTING.md
sed -i '' 's/npm run build/go build/g' CONTRIBUTING.md
sed -i '' 's/Node.js 18+/Go 1.21+/g' CONTRIBUTING.md

# docs/TESTING.md
sed -i '' 's/Vitest/Go testing package/g' docs/TESTING.md
sed -i '' 's/npm test/go test .\/\.\.\./g' docs/TESTING.md
sed -i '' 's/\.test\.ts/_test.go/g' docs/TESTING.md
```

### Rust プロジェクト

```bash
cd ~/dev/rust-project

# CONTRIBUTING.md
sed -i '' 's/npm install/cargo build/g' CONTRIBUTING.md
sed -i '' 's/npm test/cargo test/g' CONTRIBUTING.md
sed -i '' 's/npm run build/cargo build --release/g' CONTRIBUTING.md
sed -i '' 's/Node.js 18+/Rust 1.70+/g' CONTRIBUTING.md

# docs/TESTING.md
sed -i '' 's/Vitest/Rust built-in test framework/g' docs/TESTING.md
sed -i '' 's/npm test/cargo test/g' docs/TESTING.md
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
  bash ~/dev/templates/oss-docs/apply-templates.sh "$dir" "$name" "$owner" "$repo"
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
sed -i '' 's/npm install/pip install -r requirements.txt/g' CONTRIBUTING.template.md
sed -i '' 's/npm test/pytest/g' CONTRIBUTING.template.md
# ...その他のカスタマイズ
```

## トラブルシューティング

### エラー: "Directory does not exist"

```bash
# ディレクトリを作成してから実行
mkdir -p ~/dev/new-project
bash ~/dev/templates/oss-docs/apply-templates.sh ~/dev/new-project new-project owner repo
```

### エラー: "Permission denied"

```bash
# スクリプトに実行権限を付与
chmod +x ~/dev/templates/oss-docs/apply-templates.sh
```

### 既存のファイルを上書きしたくない

```bash
# バックアップを作成
cd ~/dev/your-project
cp CONTRIBUTING.md CONTRIBUTING.md.backup

# テンプレートを適用
bash ~/dev/templates/oss-docs/apply-templates.sh ~/dev/your-project ...

# 差分を確認してマージ
diff CONTRIBUTING.md.backup CONTRIBUTING.md
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
cd ~/dev/zoomy
git pull

# 変更があればテンプレートを更新
cp CONTRIBUTING.md ~/dev/templates/oss-docs/CONTRIBUTING.template.md
cp docs/TESTING.md ~/dev/templates/oss-docs/TESTING.template.md

# 既存プロジェクトに差分を反映（選択的に）
cd ~/dev/your-project
diff ~/dev/templates/oss-docs/CONTRIBUTING.template.md CONTRIBUTING.md
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
