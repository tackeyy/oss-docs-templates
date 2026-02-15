# Contributing Guide Proposal for Zoomy

このドキュメントは、zoomyプロジェクトをOSSとして他のコントリビューターが参加しやすくするために必要なドキュメントと、そのベストプラクティスをまとめたものです。

---

## 📋 推奨ドキュメント一覧

### 必須ドキュメント (Priority: High)

| ドキュメント | 目的 | 配置場所 |
|------------|------|---------|
| **CONTRIBUTING.md** | コントリビューションの総合ガイド | プロジェクトルート |
| **CODE_OF_CONDUCT.md** | 行動規範 | プロジェクトルート |
| **Issue Template** | Issue作成時の標準フォーマット | `.github/ISSUE_TEMPLATE/` |
| **PR Template** | Pull Request作成時の標準フォーマット | `.github/PULL_REQUEST_TEMPLATE.md` |
| **Testing Guide** | テスト戦略とテスト作成方法 | `docs/TESTING.md` |

### 推奨ドキュメント (Priority: Medium)

| ドキュメント | 目的 | 配置場所 |
|------------|------|---------|
| **Architecture Guide** | システム設計とアーキテクチャ | `docs/ARCHITECTURE.md` |
| **Development Setup** | 開発環境セットアップ詳細 | `docs/DEVELOPMENT.md` |
| **Release Process** | リリースプロセスと手順 | `docs/RELEASE.md` |
| **Security Policy** | セキュリティ脆弱性の報告方法 | `SECURITY.md` |

---

## 📚 各ドキュメントの構成とベストプラクティス

### 1. CONTRIBUTING.md

**目的**: コントリビューターが最初に読むべき包括的なガイド

**推奨構成**:

```markdown
# Contributing to Zoomy

## 🙏 Welcome!
[プロジェクトへの歓迎メッセージ]

## 📖 Table of Contents
- How to Contribute
- Development Setup
- Coding Standards
- Testing Requirements
- Submitting Changes
- Code Review Process
- Community Guidelines

## 🚀 How to Contribute

### Ways to Contribute
- 🐛 Report bugs
- 💡 Suggest features
- 📝 Improve documentation
- 🔧 Submit bug fixes
- ✨ Add new features (with prior approval)

### Before You Start
1. Check existing issues/PRs to avoid duplication
2. For new features, open an issue first to discuss
3. Read our [Testing Guide](docs/TESTING.md)
4. Ensure you understand our [Code of Conduct](CODE_OF_CONDUCT.md)

## 💻 Development Setup

### Prerequisites
- Node.js 18+ / npm 9+
- Zoom Server-to-Server OAuth credentials

### Setup Steps
```bash
# Clone repository
git clone https://github.com/tackeyy/zoomy.git
cd zoomy

# Install dependencies
npm install

# Copy environment template
cp .env.example .env
# Edit .env with your Zoom credentials

# Run tests
npm test

# Build
npm run build
```

## 📐 Coding Standards

### TypeScript Style
- Use strict TypeScript mode
- Prefer `const` over `let`
- Use descriptive variable names
- Avoid `any` type (use `unknown` if needed)

### Commit Messages
Format: `<type>: <subject>`

Types:
- `feat:` New feature
- `fix:` Bug fix
- `test:` Test additions/changes
- `docs:` Documentation changes
- `refactor:` Code refactoring
- `chore:` Maintenance tasks

Examples:
```
feat: add support for recurring meetings
fix: correct timezone conversion in formatDate
test: add validation tests for update command
docs: update README with new --json flag
```

## 🧪 Testing Requirements

**All code contributions MUST include tests.**

### Test Types
1. **Unit Tests**: For individual functions/modules
2. **Validation Tests**: For CLI input validation
3. **Output Tests**: For CLI output formatting
4. **Error Handling Tests**: For error scenarios

### Running Tests
```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run with coverage (future)
npm run test:coverage
```

### Test Writing Guidelines
- Follow Arrange/Act/Assert pattern
- One assertion per test (when possible)
- Use descriptive test names: `should reject invalid ISO 8601 datetime`
- Mock external dependencies (fetch, process.env)
- See [Testing Guide](docs/TESTING.md) for details

### Test Coverage Expectations
- New features: 100% coverage for new code
- Bug fixes: Add regression test reproducing the bug
- Refactoring: Maintain or improve existing coverage

## 📝 Submitting Changes

### Pull Request Process

1. **Create a branch**
   ```bash
   git checkout -b feat/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

2. **Make your changes**
   - Write code
   - Add tests
   - Update documentation if needed

3. **Ensure quality**
   ```bash
   npm test          # All tests pass
   npm run build     # Build succeeds
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

5. **Push and create PR**
   ```bash
   git push origin feat/your-feature-name
   # Create PR via GitHub UI or gh CLI
   ```

6. **Fill out PR template**
   - Describe what changed and why
   - Link related issues
   - Provide testing evidence
   - Check all applicable boxes

### PR Requirements
✅ All tests pass
✅ Code follows project style
✅ Commit messages follow convention
✅ Documentation updated (if applicable)
✅ PR description completed

### What to Expect
- Initial review within 2-3 business days
- Feedback and requested changes
- Approval and merge once requirements met

## 👀 Code Review Process

### For Contributors
- Be responsive to feedback
- Ask questions if feedback is unclear
- Push updates to the same branch
- Be patient and respectful

### Review Criteria
Reviewers check for:
- ✅ Functionality: Does it work as intended?
- ✅ Tests: Are they comprehensive and passing?
- ✅ Code Quality: Is it readable and maintainable?
- ✅ Documentation: Is it clear and up-to-date?
- ✅ Performance: Are there any obvious issues?
- ✅ Security: Are there any vulnerabilities?

## 🤝 Community Guidelines

- Be respectful and welcoming
- Follow our [Code of Conduct](CODE_OF_CONDUCT.md)
- Ask questions in [GitHub Discussions]
- Report security issues privately (see [SECURITY.md])

## 📬 Getting Help

- 💬 **Questions**: Open a [GitHub Discussion]
- 🐛 **Bugs**: Open an [Issue](https://github.com/tackeyy/zoomy/issues/new?template=bug_report.md)
- 💡 **Feature Requests**: Open an [Issue](https://github.com/tackeyy/zoomy/issues/new?template=feature_request.md)

## 🙌 Recognition

All contributors are recognized in:
- GitHub Contributors page
- Release notes (for significant contributions)

Thank you for contributing to Zoomy! 🎉
```

---

### 2. CODE_OF_CONDUCT.md

**目的**: コミュニティの行動規範を明確にし、安全な環境を保証する

**推奨**: [Contributor Covenant](https://www.contributor-covenant.org/) の採用

```markdown
# Code of Conduct

## Our Pledge

We pledge to make participation in our community a harassment-free experience for everyone.

## Our Standards

Examples of behavior that contributes to a positive environment:
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community

Unacceptable behavior includes:
- Harassment or discriminatory comments
- Personal or political attacks
- Public or private harassment
- Publishing others' private information

## Enforcement

Instances of abusive behavior may be reported to [メール]. All complaints will be reviewed and investigated.

Project maintainers have the right to remove, edit, or reject contributions that do not align with this Code of Conduct.

## Attribution

This Code of Conduct is adapted from the [Contributor Covenant](https://www.contributor-covenant.org/), version 2.1.
```

---

### 3. Issue Templates

**場所**: `.github/ISSUE_TEMPLATE/`

#### 3.1 Bug Report (`bug_report.yml`)

```yaml
name: 🐛 Bug Report
description: Report a bug or unexpected behavior
labels: ["bug", "needs-triage"]
body:
  - type: markdown
    attributes:
      value: |
        Thanks for reporting! Please fill out the sections below.

  - type: textarea
    id: description
    attributes:
      label: Describe the bug
      description: A clear description of what the bug is
      placeholder: |
        When I run `zoomy create --start 2026-02-20T10:00:00 --duration 60`, I get...
    validations:
      required: true

  - type: textarea
    id: reproduction
    attributes:
      label: Steps to reproduce
      description: Steps to reproduce the behavior
      placeholder: |
        1. Run `zoomy create ...`
        2. Observe error message
        3. ...
    validations:
      required: true

  - type: textarea
    id: expected
    attributes:
      label: Expected behavior
      description: What you expected to happen
      placeholder: Meeting should be created successfully
    validations:
      required: true

  - type: textarea
    id: actual
    attributes:
      label: Actual behavior
      description: What actually happened
      placeholder: Error message shown, meeting not created
    validations:
      required: true

  - type: input
    id: version
    attributes:
      label: Zoomy version
      description: Run `zoomy --version`
      placeholder: "1.0.0"
    validations:
      required: true

  - type: input
    id: node
    attributes:
      label: Node.js version
      description: Run `node --version`
      placeholder: "v20.10.0"
    validations:
      required: true

  - type: input
    id: os
    attributes:
      label: Operating System
      description: e.g., macOS 14.2, Ubuntu 22.04, Windows 11
      placeholder: "macOS 14.2"
    validations:
      required: true

  - type: textarea
    id: additional
    attributes:
      label: Additional context
      description: Any other context, screenshots, or logs
    validations:
      required: false
```

#### 3.2 Feature Request (`feature_request.yml`)

```yaml
name: 💡 Feature Request
description: Suggest a new feature or enhancement
labels: ["enhancement", "needs-discussion"]
body:
  - type: markdown
    attributes:
      value: |
        Thank you for suggesting a feature! Please provide details below.

  - type: textarea
    id: problem
    attributes:
      label: Problem statement
      description: What problem does this feature solve?
      placeholder: |
        Currently, there's no way to...
        This makes it difficult to...
    validations:
      required: true

  - type: textarea
    id: solution
    attributes:
      label: Proposed solution
      description: How would you like this to work?
      placeholder: |
        Add a new command `zoomy export` that...
    validations:
      required: true

  - type: textarea
    id: alternatives
    attributes:
      label: Alternatives considered
      description: What other solutions have you considered?
    validations:
      required: false

  - type: textarea
    id: additional
    attributes:
      label: Additional context
      description: Any other context, mockups, or examples
    validations:
      required: false
```

#### 3.3 Question (`question.yml`)

```yaml
name: ❓ Question
description: Ask a question about using Zoomy
labels: ["question"]
body:
  - type: markdown
    attributes:
      value: |
        Have a question? We're here to help!

  - type: textarea
    id: question
    attributes:
      label: Your question
      description: What would you like to know?
    validations:
      required: true

  - type: textarea
    id: context
    attributes:
      label: Context
      description: Any additional context or what you've tried so far
    validations:
      required: false
```

---

### 4. Pull Request Template

**場所**: `.github/PULL_REQUEST_TEMPLATE.md`

```markdown
## Description

<!-- Provide a brief summary of your changes -->

## Related Issues

<!-- Link to related issues using #issue_number -->
Closes #

## Type of Change

<!-- Check all that apply -->
- [ ] 🐛 Bug fix (non-breaking change fixing an issue)
- [ ] ✨ New feature (non-breaking change adding functionality)
- [ ] 💥 Breaking change (fix or feature causing existing functionality to break)
- [ ] 📝 Documentation update
- [ ] 🧪 Test improvement
- [ ] ♻️ Refactoring (no functional changes)
- [ ] 🔧 Configuration/tooling change

## Testing

<!-- Describe how you tested your changes -->

### Test Coverage
- [ ] Unit tests added/updated
- [ ] All tests pass locally (`npm test`)
- [ ] Manual testing performed

### Test Evidence
<!-- Paste test output or describe manual testing steps -->
```bash
# Example test output
$ npm test
✓ All 160 tests passed
```

## Checklist

- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code where necessary
- [ ] I have updated the documentation (README, etc.)
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix/feature works
- [ ] New and existing tests pass locally
- [ ] My commit messages follow the conventional format

## Screenshots (if applicable)

<!-- Add screenshots for UI changes -->

## Additional Notes

<!-- Any additional information reviewers should know -->
```

---

### 5. Testing Guide

**場所**: `docs/TESTING.md`

```markdown
# Testing Guide

## Overview

Zoomy uses [Vitest](https://vitest.dev/) as its testing framework. All code contributions must include comprehensive tests.

## Test Philosophy

- **Write tests first** when fixing bugs (TDD approach)
- **100% coverage** for new features
- **No breaking changes** without tests proving backward compatibility
- **Fast execution** - unit tests should run in milliseconds

## Test Structure

### Directory Layout

```
src/
  __tests__/
    api.test.ts              # Zoom API integration tests
    auth.test.ts             # OAuth token management tests
    cli-output.test.ts       # CLI output formatting tests
    cli-validation.test.ts   # CLI input validation tests
    config.test.ts           # Configuration loading tests
    error-handling.test.ts   # Error handling flow tests
    errors.test.ts           # Error class tests
    index.test.ts            # Core logic tests (formatDate, buildTopic)
```

### Naming Conventions

- Test files: `*.test.ts`
- Test suites: `describe("ModuleName - functionality", () => {})`
- Test cases: `it("should do something specific", () => {})`

## Test Categories

### 1. Unit Tests

Test individual functions in isolation.

**Example** (from `index.test.ts`):
```typescript
describe("formatDate", () => {
  it("should format date with yyyy/MM/dd HH:mm pattern in Asia/Tokyo timezone", async () => {
    const date = new Date("2026-02-10T10:00:00Z");
    const format = "yyyy/MM/dd HH:mm";
    const timezone = "Asia/Tokyo";

    const { formatDate } = await import("../index.js");
    const result = formatDate(date, format, timezone);

    expect(result).toBe("2026/02/10 19:00");
  });
});
```

### 2. Validation Tests

Test input validation logic for CLI commands.

**Example** (from `cli-validation.test.ts`):
```typescript
describe("CLI Validation - create command", () => {
  it("should reject duration exceeding 1440 minutes", () => {
    const duration = 1441;

    expect(duration > 1440).toBe(true);
  });
});
```

### 3. Output Tests

Test CLI output formatting (text and JSON).

**Example** (from `cli-output.test.ts`):
```typescript
describe("CLI Output - create command", () => {
  let stdoutSpy: ReturnType<typeof vi.spyOn>;

  beforeEach(() => {
    stdoutSpy = vi.spyOn(process.stdout, "write").mockImplementation(() => true);
  });

  afterEach(() => {
    stdoutSpy.mockRestore();
  });

  it("should output text format for successful meeting creation", () => {
    // ... test implementation
    expect(stdoutSpy).toHaveBeenCalledWith("Meeting created!\n");
  });
});
```

### 4. Error Handling Tests

Test error scenarios and exit codes.

**Example** (from `error-handling.test.ts`):
```typescript
describe("Error Handling", () => {
  it("should handle ValidationError with exit code 2", () => {
    const error = new ValidationError("--start must be valid");

    // Verify error type and exit code
    expect(error instanceof ValidationError).toBe(true);
  });
});
```

## Writing Good Tests

### Follow AAA Pattern

```typescript
it("should do something", () => {
  // Arrange: Set up test data
  const input = "test";

  // Act: Execute the function
  const result = myFunction(input);

  // Assert: Verify the result
  expect(result).toBe("expected");
});
```

### One Assertion Per Test (When Possible)

❌ Bad:
```typescript
it("should validate multiple things", () => {
  expect(result.id).toBe(123);
  expect(result.name).toBe("test");
  expect(result.valid).toBe(true);
});
```

✅ Good:
```typescript
it("should return correct ID", () => {
  expect(result.id).toBe(123);
});

it("should return correct name", () => {
  expect(result.name).toBe("test");
});

it("should mark result as valid", () => {
  expect(result.valid).toBe(true);
});
```

### Use Descriptive Test Names

❌ Bad:
```typescript
it("works", () => {});
it("test 1", () => {});
```

✅ Good:
```typescript
it("should reject invalid ISO 8601 datetime format", () => {});
it("should cache token and reuse on second call", () => {});
```

### Mock External Dependencies

Always mock:
- `fetch` (API calls)
- `process.env` (environment variables)
- `process.stdout.write` (output)
- `process.stderr.write` (errors)
- `process.exit` (exit codes)

**Example**:
```typescript
beforeEach(() => {
  vi.resetModules();
  globalThis.fetch = vi.fn();
});

afterEach(() => {
  globalThis.fetch = originalFetch;
});
```

### Test Edge Cases

Always test:
- ✅ Valid input (happy path)
- ✅ Invalid input (error cases)
- ✅ Boundary values (0, max, min)
- ✅ Empty values (null, undefined, "")
- ✅ Special characters
- ✅ Extreme inputs (very long strings, large numbers)

## Running Tests

### Basic Commands

```bash
# Run all tests
npm test

# Run in watch mode (development)
npm run test -- --watch

# Run specific file
npm test src/__tests__/api.test.ts

# Run tests matching pattern
npm test -- --grep "validation"
```

### Debugging Tests

```bash
# Run with verbose output
npm test -- --reporter=verbose

# Run single test file with Node debugger
node --inspect-brk node_modules/.bin/vitest run src/__tests__/api.test.ts
```

## Test Coverage Requirements

| Category | Requirement |
|----------|-------------|
| **New Features** | 100% coverage |
| **Bug Fixes** | Regression test required |
| **Refactoring** | Maintain existing coverage |
| **Overall Project** | Target: 95%+ |

### Checking Coverage (Future)

```bash
# Generate coverage report
npm run test:coverage

# View HTML report
open coverage/index.html
```

## Common Testing Patterns

### Testing API Functions

```typescript
import { vi, beforeEach, afterEach } from "vitest";

const mockResponse = {
  ok: true,
  status: 200,
  json: () => Promise.resolve({ id: 123 }),
} as Response;

beforeEach(() => {
  vi.resetModules();
  globalThis.fetch = vi.fn().mockResolvedValue(mockResponse);
});

afterEach(() => {
  globalThis.fetch = originalFetch;
});
```

### Testing Environment Variables

```typescript
beforeEach(() => {
  vi.resetModules();
  process.env = { ...originalEnv };
  process.env["ZOOM_ACCOUNT_ID"] = "test-account";
});

afterEach(() => {
  process.env = originalEnv;
});
```

### Testing Error Messages

```typescript
it("should throw ValidationError with specific message", async () => {
  await expect(someFunction()).rejects.toThrow(
    "--duration must not exceed 1440 minutes"
  );
});
```

## Best Practices

### DO ✅

- Write tests before or alongside code
- Use `vi.resetModules()` to ensure test isolation
- Mock external dependencies
- Test both success and failure paths
- Use meaningful test descriptions
- Keep tests simple and focused

### DON'T ❌

- Skip writing tests ("I'll add them later")
- Test implementation details (test behavior, not internals)
- Write tests that depend on other tests
- Use real external APIs in tests
- Leave commented-out test code
- Write flaky tests (tests that sometimes fail)

## Troubleshooting

### "Module not found" errors

```bash
# Ensure you're using dynamic imports with .js extension
const { myFunction } = await import("../myModule.js");
```

### "Tests pass locally but fail in CI"

- Check for timezone differences
- Ensure all mocks are properly restored
- Use `vi.resetModules()` between tests

### "Tests are slow"

- Avoid unnecessary async operations
- Mock heavy dependencies
- Use `vi.useFakeTimers()` for time-dependent tests

## Resources

- [Vitest Documentation](https://vitest.dev/)
- [Vitest API Reference](https://vitest.dev/api/)
- [Testing Best Practices](https://opensource.guide/best-practices/)

## Questions?

If you have questions about testing:
1. Check existing test files for examples
2. Ask in [GitHub Discussions]
3. Open an issue with the `question` label
```

---

## 🎯 実装ロードマップ

### Phase 1: 基本ドキュメント (Week 1)
- [ ] CONTRIBUTING.md 作成
- [ ] CODE_OF_CONDUCT.md 作成
- [ ] PR Template 作成
- [ ] Basic Issue Templates 作成

### Phase 2: 詳細ガイド (Week 2)
- [ ] docs/TESTING.md 作成
- [ ] docs/DEVELOPMENT.md 作成
- [ ] GitHub Actions for automated checks

### Phase 3: 改善と拡張 (Week 3+)
- [ ] SECURITY.md 作成
- [ ] docs/ARCHITECTURE.md 作成
- [ ] Contributing workflow diagram
- [ ] First-time contributor guide

---

## 📊 参考リソース

### ベストプラクティス
- [How to Contribute to Open Source](https://opensource.guide/how-to-contribute/)
- [How to Build a CONTRIBUTING.md](https://contributing.md/how-to-build-contributing-md/)
- [GitHub CLI Contributing Guide](https://github.com/cli/cli/blob/trunk/.github/CONTRIBUTING.md)
- [Best Practices for Reviewing Open Source Contributions](https://graphite.com/guides/best-practices-reviewing-open-source-contributions)

### Issue/PR Templates
- [GitHub PR Template Examples](https://everhour.com/blog/github-pr-template/)
- [Comprehensive Checklist: GitHub PR Template](https://graphite.com/guides/comprehensive-checklist-github-pr-template)
- [Best Practices for Using GitHub Issues](https://rewind.com/blog/best-practices-for-using-github-issues/)

### Testing Documentation
- [Best Practices for Open Source Software Testing](https://www.linkedin.com/advice/0/how-do-you-design-implement-open-source-testing)
- [10up Open Source Best Practices](https://10up.github.io/Open-Source-Best-Practices/)
- [Best Practices for Maintainers](https://opensource.guide/best-practices/)

---

## 🚀 次のステップ

1. **レビュー**: このプロポーザルをレビューし、プロジェクトに合わせて調整
2. **実装**: Phase 1 から順次実装
3. **テスト**: 実際に外部コントリビューターからフィードバックを収集
4. **改善**: フィードバックに基づいてドキュメントを継続的に改善

---

**Note**: このプロポーザルは業界のベストプラクティスに基づいていますが、プロジェクトの規模、目標、コミュニティに応じてカスタマイズすることをお勧めします。
