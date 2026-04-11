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
  your-repo-name
```

### With Language-Specific Configuration

```bash
# Apply with Node.js lint configuration
bash ~/templates/oss-docs/apply-templates.sh \
  ~/dev/your-project \
  your-project-name \
  your-github-username \
  your-repo-name \
  --lang=node

# Supported languages: node, go, swift, shell, python
```

See [QUICK_START.md](QUICK_START.md) for detailed instructions.

## 📦 What's Included

### Base Templates (Always Applied)

| File | Purpose | Customization |
|------|---------|---------------|
| **CODE_OF_CONDUCT.md** | Community standards (Contributor Covenant v2.1) | ⭐ Low |
| **.github/ISSUE_TEMPLATE/** | Bug report, feature request, question templates | ⭐⭐ Medium |
| **.github/PULL_REQUEST_TEMPLATE.md** | PR checklist and guidelines | ⭐⭐ Medium |
| **SECURITY.md** | Vulnerability reporting policy and response process | ⭐⭐ Medium |
| **.changeset/README.md** | Changesets versioning guide | ⭐ Low |
| **.github/dependabot.yml** | Automated dependency updates (npm + GitHub Actions, weekly) | ⭐ Low |

### Language-Specific Templates (Optional)

| Language | Files Included | Linter/Formatter |
|----------|----------------|------------------|
| **Node.js** | CONTRIBUTING.md, TESTING.md, package.json, tsconfig.json, vitest.config.ts, .markdownlint.json, .yamllint.yml, .github/workflows/ci.yml, .github/workflows/release.yml | markdownlint, yamllint, shellcheck, TypeScript, Vitest, changesets |
| **Go** | CONTRIBUTING.md, TESTING.md, .golangci.yml | golangci-lint |
| **Swift** | CONTRIBUTING.md, TESTING.md, .swiftlint.yml | SwiftLint |
| **Shell** | CONTRIBUTING.md, TESTING.md, .shellcheckrc | shellcheck, shfmt, bats |
| **Python** | CONTRIBUTING.md, TESTING.md, pyproject.toml | ruff, mypy, pytest |

All language configs include GitHub Actions workflow for automated linting on PR.

## 📚 Documentation

- **[QUICK_START.md](QUICK_START.md)** - Get started in 3 steps
- **[USAGE_EXAMPLES.md](USAGE_EXAMPLES.md)** - Project-specific examples and troubleshooting
- **[CONTRIBUTING_GUIDE_PROPOSAL.md](CONTRIBUTING_GUIDE_PROPOSAL.md)** - Research-based best practices reference

## ✨ Features

- **One-command setup** - Apply all templates with a single script
- **Language-specific configs** - Tailored CONTRIBUTING.md and lint setup for 5 languages
- **Automatic customization** - Project name and repository auto-replacement
- **GitHub Actions ready** - Automated lint checks on every PR
- **Industry standards** - Based on GitHub CLI, AWS CLI, Contributor Covenant
- **Privacy-conscious** - Contact via X (Twitter) [@3chhe](https://x.com/3chhe) instead of email

## 🎯 Use Cases

### Node.js/TypeScript Project

```bash
bash ~/templates/oss-docs/apply-templates.sh \
  ~/dev/my-cli my-cli tackeyy my-cli --lang=node

cd ~/dev/my-cli
npm install
npm run lint
```

### Go Project

```bash
bash ~/templates/oss-docs/apply-templates.sh \
  ~/dev/my-go-app my-go-app tackeyy my-go-app --lang=go

cd ~/dev/my-go-app
go mod download
golangci-lint run
```

### Python Project

```bash
bash ~/templates/oss-docs/apply-templates.sh \
  ~/dev/my-python-app my-python-app tackeyy my-python-app --lang=python

cd ~/dev/my-python-app
pip install ruff mypy pytest
ruff check .
```

### Swift Project

```bash
bash ~/templates/oss-docs/apply-templates.sh \
  ~/dev/my-swift-app my-swift-app tackeyy my-swift-app --lang=swift

cd ~/dev/my-swift-app
swiftlint
```

### Shell Script Project

```bash
bash ~/templates/oss-docs/apply-templates.sh \
  ~/dev/my-scripts my-scripts tackeyy my-scripts --lang=shell

cd ~/dev/my-scripts
shellcheck *.sh
```

## 🛠️ How It Works

The `apply-templates.sh` script:

1. **Copies base templates** - CODE_OF_CONDUCT.md and .github templates (language-independent)
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
  - [ ] Contact information (currently: X [@3chhe](https://x.com/3chhe))
- [ ] **.github templates**
  - [ ] Issue labels (if different from defaults)
  - [ ] PR checklist items

## 🌍 Language Support Details

### Node.js (+ MCP SDK Support)
- ✅ Linters: markdownlint, yamllint, shellcheck, eslint (optional)
- ✅ Test framework: Jest/Vitest (vitest.config.ts included)
- ✅ Package manager: npm/yarn/pnpm
- ✅ TypeScript: tsconfig.json for Node 22 + ESM + NodeNext (compatible with `@modelcontextprotocol/sdk`)
- ✅ CI workflow: typecheck + lint + test + build (ci.yml)
- ✅ Release workflow: changesets-based npm publish (release.yml)

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
- ✅ Python versions: 3.9+

## 📖 Best Practices Reference

This template is based on extensive research of OSS best practices:

- [GitHub CLI Contributing Guide](https://github.com/cli/cli/blob/trunk/.github/CONTRIBUTING.md)
- [AWS CLI Contributing](https://github.com/aws/aws-cli/blob/develop/CONTRIBUTING.md)
- [Contributor Covenant v2.1](https://www.contributor-covenant.org/)
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
