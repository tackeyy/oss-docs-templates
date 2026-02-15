# Testing Guide for {{PROJECT_NAME}}

This document describes the testing strategy, guidelines, and best practices for {{PROJECT_NAME}}.

## 🎯 Testing Philosophy

- **Test actual behavior** not internal implementation
- **Test error cases** as thoroughly as success cases
- **Keep tests simple** and easy to understand
- **Use real scripts** not mocked versions when possible

## 📚 Testing Framework

{{PROJECT_NAME}} uses:
- `bats` - Bash Automated Testing System
- `shellcheck` - Static analysis tool for shell scripts

## 🏗️ Test Structure

### Directory Layout

```
{{REPO_NAME}}/
├── scripts/
│   ├── main.sh
│   └── utils.sh
└── tests/
    ├── test_main.bats
    └── test_utils.bats
```

### Installing bats

```bash
# macOS
brew install bats-core

# Ubuntu/Debian
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local

# Or use npm
npm install -g bats
```

## ✍️ Writing Tests

### Basic Test Example

```bash
#!/usr/bin/env bats

@test "function returns success" {
    run main_function
    [ "$status" -eq 0 ]
}

@test "function produces expected output" {
    run echo "Hello"
    [ "$output" = "Hello" ]
}
```

### Testing Script Output

```bash
@test "script displays help message" {
    run ./script.sh --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}
```

### Testing Error Conditions

```bash
@test "script fails with invalid input" {
    run ./script.sh --invalid-option
    [ "$status" -ne 0 ]
    [[ "$output" =~ "Error:" ]]
}
```

### Using Setup and Teardown

```bash
setup() {
    # Create temp directory
    TEST_DIR="$(mktemp -d)"
    TEST_FILE="$TEST_DIR/test.txt"
}

teardown() {
    # Clean up
    rm -rf "$TEST_DIR"
}

@test "creates file" {
    ./script.sh create "$TEST_FILE"
    [ -f "$TEST_FILE" ]
}
```

## 🏃 Running Tests

### Basic Commands

```bash
# Run all tests
bats tests/

# Run specific test file
bats tests/test_main.bats

# Run with verbose output
bats -t tests/

# Run with timing
bats --timing tests/

# Run specific test
bats tests/test_main.bats -f "specific test name"
```

### ShellCheck

```bash
# Check all shell scripts
shellcheck *.sh scripts/*.sh

# Check with specific shell
shellcheck -s bash script.sh

# Exclude specific warnings
shellcheck -e SC2086 script.sh
```

## ✅ Test Checklist

Before submitting a PR, ensure:

- [ ] All bats tests pass: `bats tests/`
- [ ] ShellCheck passes: `shellcheck *.sh`
- [ ] Scripts have proper shebangs
- [ ] Error handling is tested
- [ ] Edge cases are covered
- [ ] Scripts are executable: `chmod +x`

## 🎯 Best Practices

1. **Test return codes** - verify `$status` for success/failure
2. **Test output** - check `$output` for expected messages
3. **Use `run`** - captures output and status correctly
4. **Clean up** - use teardown to remove temp files
5. **Test error messages** - ensure errors are informative
6. **Use temp directories** - avoid polluting file system
7. **Test with different inputs** - boundary conditions, empty strings
8. **Mock external commands** - when necessary for isolation

## 🔧 Advanced Testing

### Mocking External Commands

```bash
# Create mock in test
@test "handles git command" {
    git() {
        echo "mocked git"
        return 0
    }
    export -f git

    run ./script.sh
    [[ "$output" =~ "mocked git" ]]
}
```

### Testing with Different Shells

```bash
# Test with bash
bash script.sh

# Test with sh
sh script.sh

# Test with zsh
zsh script.sh
```

### Parallel Testing

```bash
# Run tests in parallel (if supported)
bats --jobs 4 tests/
```

## 📊 Common Assertions

```bash
# Status checks
[ "$status" -eq 0 ]          # Success
[ "$status" -ne 0 ]          # Failure
[ "$status" -eq 1 ]          # Specific exit code

# Output checks
[ "$output" = "exact match" ]
[[ "$output" =~ "pattern" ]]
[ -z "$output" ]              # Empty output
[ -n "$output" ]              # Non-empty output

# File checks
[ -f "$file" ]                # File exists
[ -d "$dir" ]                 # Directory exists
[ -x "$script" ]              # Executable
[ ! -e "$file" ]              # Does not exist
```

## 📚 Resources

- [Bats Documentation](https://bats-core.readthedocs.io/)
- [ShellCheck Wiki](https://github.com/koalaman/shellcheck/wiki)
- [Bash Guide](https://mywiki.wooledge.org/BashGuide)

---

**Questions?** Open an issue or refer to [CONTRIBUTING.md](../CONTRIBUTING.md)
