# OSS Documentation Templates

Reusable OSS documentation templates with one-command setup and multi-language support. Based on
industry best practices (GitHub CLI, AWS CLI, Contributor Covenant).

## 🚀 Quick Start

### Basic Templates (Language-Independent)

```bash
# Clone this repository
git clone https://github.com/tackeyy/oss-docs-templates.git ~/templates/oss-docs

# Apply base templates only (CODE_OF_CONDUCT, issue/PR templates)
bash ~/templates/oss-docs/apply-templates.sh \
  ~/dev/your-project \
  your-project-name \
  your-github-username \
  your-repo-name \
  --conduct-contact=conduct@example.com
```

### With Language-Specific Configuration

```bash
# Apply with Node.js lint configuration
bash ~/templates/oss-docs/apply-templates.sh \
  ~/dev/your-project \
  your-project-name \
  your-github-username \
  your-repo-name \
  --lang=node \
  --description-ja="プロジェクトの短い説明" \
  --conduct-contact=conduct@example.com

# Supported languages: node, go, swift, shell, python
```

See [QUICK_START.md](QUICK_START.md) for detailed instructions.

### Options

| Option | Description |
|--------|-------------|
| `--conduct-contact=<email-or-url>` | Where Code of Conduct reports go. **Required** when CODE_OF_CONDUCT.md is written |
| `--lang=<node\|go\|swift\|shell\|python>` | Add language-specific templates |
| `--license=<apache-2.0\|mit>` | Create LICENSE (also sets `license` in the Node package.json) |
| `--copyright-holder=<name>` | Copyright holder for LICENSE (default: repo owner) |
| `--code-owners="<@user @org/team ...>"` | Owners in `.github/CODEOWNERS` (default: `@<repo-owner>`) |
| `--readme-lang=<en\|ja>` | Language of your main README (default: `en`). With `ja`, README.ja.md is not added and the Japanese Code of Conduct is used |
| `--contact-email=<email>` / `--contact-handle=<handle>` | Optional extra contacts listed in SECURITY.md |
| `--description-ja=<text>` | Short Japanese description for README.ja.md |
| `--update-actions` | With `--lang=node` only: replace an existing `.github/workflows/ci.yml` (the previous file is kept as `ci.yml.pre-cost-optimization`) and, when those files exist, rename `lint.yml` to `lint.yml.disabled` and `release.yml` to `release.yml.disabled`. Existing workflows for go, swift, shell, and python are not replaced; without `--force` they are skipped |
| `--force` | Overwrite files that already exist. **By default, existing files are kept** |
| `--dry-run` | Show what would be created, overwritten, or skipped without writing anything |

## 📦 What's Included

### Base Templates (Always Applied)

| File | Purpose | Customization |
|------|---------|---------------|
| **CODE_OF_CONDUCT.md** | Community standards (Contributor Covenant 3.0; Japanese translation with `--readme-lang=ja`) | ⭐ Low |
| **.github/ISSUE_TEMPLATE/** | Bug, feature, and question forms. Blank issues are disabled; vulnerability reports go to private vulnerability reporting. Labels are GitHub's defaults (`bug`, `enhancement`, `question`) | ⭐⭐ Medium |
| **.github/PULL_REQUEST_TEMPLATE.md** | PR checklist, plus a warning not to paste real data or tokens and to report vulnerabilities privately | ⭐⭐ Medium |
| **SECURITY.md** | Vulnerability reporting through GitHub private vulnerability reporting (extra contacts optional) | ⭐⭐ Medium |
| **.github/CODEOWNERS** | Review owners for every pull request (`--code-owners`; use a team for organizations) | ⭐ Low |
| **.github/dependabot.yml** | Weekly updates for GitHub Actions, plus the package ecosystem of `--lang` (npm, gomod, pip, swift). Minor and patch updates are grouped; major updates are a separate group. Labels are omitted so Dependabot creates its defaults | ⭐ Low |
| **.github/workflows/security.yml** | Secret scanning with the gitleaks CLI (pinned version and checksum) on push to `main` or `master`, and on pull requests targeting `main` or `master`. The scan fails when the workspace is not a git repository | ⭐ Low |
| **LICENSE** (with `--license=apache-2.0\|mit`) | License file with year/holder auto-filled (`--copyright-holder` to override) | ⭐ Low |

### Language-Specific Templates (Optional)

| Language | Files Included | Linter/Formatter |
|----------|----------------|------------------|
| **Node.js** | CONTRIBUTING.md, TESTING.md, package.json (scripts: `lint`, `lint:md`, `lint:yaml`, `lint:sh` only), package-lock.json, tsconfig.json, vitest.config.ts, .markdownlint.json, .yamllint.yml, .changeset/README.md, .github/workflows/ci.yml | markdownlint, yamllint, shellcheck. Typecheck, Vitest, and changesets are not installed; add the dependencies and scripts yourself |
| **Go** | CONTRIBUTING.md, TESTING.md, .golangci.yml | golangci-lint |
| **Swift** | CONTRIBUTING.md, TESTING.md, .swiftlint.yml | SwiftLint |
| **Shell** | CONTRIBUTING.md, TESTING.md, .shellcheckrc | shellcheck, shfmt, bats |
| **Python** | CONTRIBUTING.md, TESTING.md, pyproject.toml | ruff, mypy, pytest |

All language configs include GitHub Actions workflow for automated linting on PR.

## 📚 Documentation

- **[QUICK_START.md](QUICK_START.md)** - Get started in 3 steps
- **[USAGE_EXAMPLES.md](USAGE_EXAMPLES.md)** - Project-specific examples and troubleshooting
- **[CONTRIBUTING_GUIDE_PROPOSAL.md](CONTRIBUTING_GUIDE_PROPOSAL.md)** - Research-based best practices reference
- **[GitHub Actions cost controls](docs/GITHUB_ACTIONS_COST_OPTIMIZATION.md)** - Quality-preserving CI optimization policy

## ✨ Features

- **One-command setup** - Apply all templates with a single script
- **Language-specific configs** - Tailored CONTRIBUTING.md and lint setup for 5 languages
- **Automatic customization** - Project name and repository auto-replacement
- **GitHub Actions ready** - Automated lint checks on every PR
- **Cost-efficient CI** - Consolidated jobs, dependency caching, short-lived failure artifacts, and grouped dependency updates
- **Industry standards** - Based on GitHub CLI, AWS CLI, Contributor Covenant
- **Explicit reporting contacts** - The Code of Conduct reporting contact is required (`--conduct-contact`); nothing personal is filled in by default
- **Safe on existing repositories** - Existing files are kept unless you pass `--force`; `--dry-run` shows the plan first

## 🎯 Use Cases

### Node.js/TypeScript Project

```bash
bash ~/templates/oss-docs/apply-templates.sh \
  ~/dev/my-cli my-cli tackeyy my-cli --lang=node \
  --conduct-contact=conduct@example.com

cd ~/dev/my-cli
npm ci
npm run lint
```

`npm run lint` runs `lint:md` and `lint:sh`, and it succeeds immediately after apply to an empty directory.
`lint:sh` is `find … | xargs -0 -r shellcheck`. With no `*.sh` files, `-r` keeps GNU xargs
from starting shellcheck. BSD xargs accepts `-r` and already skips empty input.
Before `npm run typecheck`, `npm test`, or `npm run build`, add those scripts and their
dependencies. The generated package.json does not include them. Before `npm run lint:yaml`,
install yamllint (`pip install yamllint`). CI installs it before that step. `lint:yaml` is
separate from `npm run lint`.

### Go Project

```bash
bash ~/templates/oss-docs/apply-templates.sh \
  ~/dev/my-go-app my-go-app tackeyy my-go-app --lang=go \
  --conduct-contact=conduct@example.com

# Existing Go module only. The template does not create go.mod.
# `go mod download` and `golangci-lint run` fail when go.mod is absent.
cd ~/dev/my-go-app
go mod download
golangci-lint run
```

### Python Project

```bash
bash ~/templates/oss-docs/apply-templates.sh \
  ~/dev/my-python-app my-python-app tackeyy my-python-app --lang=python \
  --conduct-contact=conduct@example.com

cd ~/dev/my-python-app
pip install ruff mypy pytest
ruff check .
```

### Swift Project

```bash
bash ~/templates/oss-docs/apply-templates.sh \
  ~/dev/my-swift-app my-swift-app tackeyy my-swift-app --lang=swift \
  --conduct-contact=conduct@example.com

cd ~/dev/my-swift-app
swiftlint
```

### Shell Script Project

```bash
bash ~/templates/oss-docs/apply-templates.sh \
  ~/dev/my-scripts my-scripts tackeyy my-scripts --lang=shell \
  --conduct-contact=conduct@example.com

# The template does not add any `*.sh` files.
# `shellcheck *.sh` fails when the project has no shell scripts; run it only after you add some.
cd ~/dev/my-scripts
shellcheck *.sh
```

## 🛠️ How It Works

The `apply-templates.sh` script:

1. **Copies base templates** - CODE_OF_CONDUCT.md, SECURITY.md and .github templates (language-independent). Files that already exist are skipped unless `--force` is given
2. **Copies language-specific files** (if --lang specified):
   - CONTRIBUTING.md tailored for the language
   - TESTING.md with language-specific test framework docs
   - Lint configuration files (.golangci.yml, .swiftlint.yml, etc.)
   - GitHub Actions workflow for automated linting
3. **Replaces placeholders** - Automatically substitutes project name and repository info
4. **Provides next steps** - Shows language-specific setup instructions

## 📋 Customization Checklist

After applying templates, review and customize:

- [ ] **CONTRIBUTING.md** (if applied with --lang)
  - [ ] Development setup instructions
  - [ ] Project-specific coding standards
  - [ ] Test and build commands
- [ ] **docs/TESTING.md** (if applied with --lang)
  - [ ] Test directory structure
  - [ ] Test execution commands
  - [ ] Coverage requirements
- [ ] **CODE_OF_CONDUCT.md**
  - [ ] Reporting contact (`--conduct-contact`)
- [ ] **SECURITY.md**
  - [ ] Enable private vulnerability reporting (Settings > Security)
  - [ ] Optional extra contacts (`--contact-email` / `--contact-handle`)
- [ ] **.github/CODEOWNERS**
  - [ ] Owners (organizations need a team such as `@org/maintainers`)
- [ ] **.github templates**
  - [ ] Issue labels (templates use GitHub's defaults `bug`, `enhancement`, and `question`; create any other label in the repository before adding it to a template)
  - [ ] PR checklist items
  - [ ] Required checks match the generated workflow job names

## 🌍 Language Support Details

### Node.js (+ MCP SDK Support)
- ✅ Generated `package.json` scripts are only `lint`, `lint:md`, `lint:yaml`, and `lint:sh`. The only devDependency is `markdownlint-cli2`. `lint` runs `lint:md` and `lint:sh`.
- ✅ Copied config, not installed tools: `tsconfig.json` (Node 24, ESM, NodeNext, compatible with `@modelcontextprotocol/sdk`) and `vitest.config.ts`. `typescript` and `vitest` are not dependencies, and there is no `typecheck`, `test`, or `build` script until you add them.
- ✅ Package manager: npm (`npm ci` with the generated package-lock.json)
- ✅ Runtime: Node.js 24 LTS + npm 11 (`engines.node` is `>=24`)
- ✅ CI (`ci.yml`): `npm run typecheck`, `npm run lint:md`, `npm run lint:yaml`, `npm run test`, and `npm run build` all use `--if-present`. The generated package.json includes `lint:md` and `lint:yaml`, so those two run; `typecheck`, `test`, and `build` are skipped until you add the scripts. Shellcheck is not an npm script: the `ludeeus/action-shellcheck` step runs on every CI run, with or without a matching script.
- ✅ Gated release job: changesets-based npm publish with [trusted publishing](https://docs.npmjs.com/trusted-publishers) (OIDC, no npm token). It runs only on a push to `main`, after the quality job succeeds, and only when `package.json` has a `release` script, `.changeset/config.json` exists, and the package is not `"private": true`. The generated package.json is `"private": true` and has no `release` script. The template copies `.changeset/README.md`, not `.changeset/config.json`.

### Go
- ✅ Linter: golangci-lint (includes errcheck, gosimple, govet, staticcheck, etc.)
- ✅ Test framework: Go testing package
- ✅ Coverage: Built-in go test -cover

### Swift
- ✅ Linter: SwiftLint
- ✅ Test framework: XCTest
- ✅ UI Testing: XCUITest

### Shell
- ✅ Linter: shellcheck, shfmt
- ✅ Test framework: bats (Bash Automated Testing System)
- ✅ Supports: bash, zsh, sh

### Python
- ✅ Linter: ruff (fast Python linter)
- ✅ Type checker: mypy
- ✅ Test framework: pytest
- ✅ Python versions: 3.10+

## 📖 Best Practices Reference

This template is based on extensive research of OSS best practices:

- [GitHub CLI Contributing Guide](https://github.com/cli/cli/blob/trunk/.github/CONTRIBUTING.md)
- [AWS CLI Contributing](https://github.com/aws/aws-cli/blob/develop/CONTRIBUTING.md)
- [Contributor Covenant 3.0](https://www.contributor-covenant.org/version/3/0/)
- [How to Build a CONTRIBUTING.md](https://contributing.md/)
- [GitHub PR Template Best Practices](https://graphite.com/guides/comprehensive-checklist-github-pr-template)

See [CONTRIBUTING_GUIDE_PROPOSAL.md](CONTRIBUTING_GUIDE_PROPOSAL.md) for comprehensive research and recommendations.

## 🤝 Contributing

Improvements and suggestions are welcome! Feel free to:

- Open an issue for bugs or feature requests
- Submit a pull request with improvements
- Share your experience using these templates

## 📄 License

These templates are provided as-is for public use. Derived from the [zoomy](https://github.com/tackeyy/zoomy) project.

## 🔗 Links

- **Repository**: https://github.com/tackeyy/oss-docs-templates
- **Source Project**: [zoomy](https://github.com/tackeyy/zoomy) - Zoom CLI tool
- **Contact**: X (Twitter) [@3chhe](https://x.com/3chhe)

---

**Made with ❤️ for the open source community**
