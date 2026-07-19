# GitHub Actionsコスト最適化方針

## エグゼクティブサマリー

このテンプレートは、lint、型検査、テスト、build、coverage、secret scanを削らず、同じruntime setupの重複とjob単位の
分数切り上げを減らす。新規生成時の通常workflowは、Node.jsで7 jobから1 job、Goで2 jobから1 job、ShellとSwiftで
それぞれ複数jobから1 jobへ統合する。Pythonは対応4バージョンを維持しながら、lintと型検査をPython 3.9のmatrix実行へ
統合する。

## 品質を維持する不変条件

- 既存のlint、型検査、テスト、build、coverage、secret scanを残す
- Pythonの対応バージョン3.9、3.10、3.11、3.12を全て検証する
- Goのrace detectorを維持する
- Swiftのcoverage生成を維持する
- 失敗したcommitをreleaseやdeployへ進めない
- workflow変更は`tests/test-workflow-templates.sh`で生成結果を検証する

## job構成の変更

| 言語 | 変更前 | 変更後 | 維持する検査 |
|---|---:|---:|---|
| Node.js | 7 job | 1 job | typecheck、Markdown、YAML、ShellCheck、test、build |
| Go | 2 job | 1 job | golangci-lint、race test、coverage |
| Python | 6実行 | 4実行 | ruff、mypy、4バージョンのtest、coverage |
| Shell | 3 job | 1 job | ShellCheck、shfmt、Bats |
| Swift | 2 job | 1 job | SwiftLint、test、coverage |
| 共通security | 1 job | 1 job | 全履歴に対するgitleaks |

Node.jsのrelease workflowはpublish権限と中断安全性が異なるため、通常CIへ統合しない。

## 実装済みの節約策

### setupとjobの統合

- 同じruntimeを使う短い検査を1 jobへまとめる
- Node.jsのcheckout、`setup-node`、`npm ci`を1回にする
- Goのcheckoutと`setup-go`を1回にする
- ShellとSwiftのcheckoutを1回にする
- 全workflowで古いrunを`concurrency`によりキャンセルする
- 全jobに`timeout-minutes`を設定する

### cacheとartifact

- npm、pip、Go moduleの公式`setup-*` cacheを使う
- Swift Package Managerの`.build`をXcode 15単位でcacheする
- Python coverageは代表バージョンの3.9からだけ送信する
- Node.js coverage artifactは失敗時だけ1日保持する

### Dependabot

- npmのminor・patch更新を1 PRへまとめる
- GitHub Actions更新を1 PRへまとめる
- 通常のversion updateへ7日のcooldownを設定する
- security updateにはcooldownを適用しない

### token権限

通常CIは`contents: read`だけを付与する。release workflowだけはpublishに必要な書き込み権限を維持する。

## 共通テンプレートへ入れていない施策

以下は対象リポジトリの構成やGitHub設定が分からないまま適用すると、必要な検査をskipする可能性があるため共通化しない。

- `paths`、`paths-ignore`による起動制限
- PRで成功したcommitのmain側CI省略
- Draft PRの重いCI省略
- `ubuntu-slim`へのrunner変更
- branch protectionとMerge Queueの自動設定
- Docker imageのbuild、scan、push統合

これらは生成先でbranch protection、required checks、変更パス、release経路を確認してから個別に適用する。

## 適用後の確認

新規リポジトリでは、利用する言語に応じて次のcheckをbranch protectionへ登録する。

- Node.js: `CI / Quality`
- Go: `Lint / Go Quality`
- Python: `Lint / Python 3.9`、`3.10`、`3.11`、`3.12`
- Shell: `Lint / Shell Quality`
- Swift: `Lint / Swift Quality`
- 全言語: `Security / Secret Scan (gitleaks)`

テンプレートは既存リポジトリの古いworkflowを自動削除しない。既存リポジトリへ再適用する場合は、required check名を更新してから旧workflowを手動で削除する。

## 公式仕様

- [GitHub Actions runner pricing](https://docs.github.com/en/billing/reference/actions-runner-pricing)
- [Concurrency](https://docs.github.com/en/actions/concepts/workflows-and-actions/concurrency)
- [Dependency caching](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching)
- [Dependabot options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference)
- [Protected branches](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
