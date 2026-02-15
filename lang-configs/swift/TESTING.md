# Testing Guide for {{PROJECT_NAME}}

This document describes the testing strategy, guidelines, and best practices for {{PROJECT_NAME}}.

## 🎯 Testing Philosophy

- **Test behavior, not implementation**
- **Write tests first** when fixing bugs
- **Keep tests simple and readable**
- **Use XCTest framework** for unit tests
- **Use XCUITest** for UI tests

## 📚 Testing Framework

{{PROJECT_NAME}} uses:
- `XCTest` - Unit testing framework
- `XCUITest` - UI testing framework
- `Quick/Nimble` - BDD-style testing (optional)

## 🏗️ Test Structure

### Directory Layout

```
{{REPO_NAME}}/
├── Sources/
│   └── {{REPO_NAME}}/
│       ├── Models/
│       │   └── User.swift
│       └── Services/
│           └── AuthService.swift
└── Tests/
    └── {{REPO_NAME}}Tests/
        ├── ModelTests/
        │   └── UserTests.swift
        └── ServiceTests/
            └── AuthServiceTests.swift
```

### Naming Convention

- Test files: `*Tests.swift`
- Test classes: `final class UserTests: XCTestCase`
- Test functions: `func testFunctionName()`

## ✍️ Writing Tests

### Basic Test Example

```swift
import XCTest
@testable import {{REPO_NAME}}

final class UserTests: XCTestCase {
    func testUserInitialization() {
        // Arrange
        let name = "John Doe"
        let email = "john@example.com"

        // Act
        let user = User(name: name, email: email)

        // Assert
        XCTAssertEqual(user.name, name)
        XCTAssertEqual(user.email, email)
    }
}
```

### Async Test Example

```swift
func testAsyncFetch() async throws {
    let service = UserService()
    let user = try await service.fetchUser(id: "123")
    XCTAssertNotNil(user)
}
```

### Test Setup and Teardown

```swift
final class ServiceTests: XCTestCase {
    var service: UserService!

    override func setUp() {
        super.setUp()
        service = UserService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    func testServiceMethod() {
        // Test code
    }
}
```

## 🏃 Running Tests

### Command Line

```bash
# Run all tests
swift test

# Run specific test
swift test --filter UserTests

# Run with parallel execution
swift test --parallel

# Generate code coverage
swift test --enable-code-coverage
```

### Xcode

- **Run all tests**: ⌘+U
- **Run single test**: Click diamond icon next to test method
- **View coverage**: ⌘+9 → Coverage tab

## 📊 Test Coverage

### Coverage Requirements

- **Overall**: 70%+ coverage required
- **New features**: 80%+ coverage required
- **Critical paths**: 90%+ coverage required
- **Bug fixes**: Must include regression test

### View Coverage in Xcode

1. Enable coverage: Scheme → Test → Options → Code Coverage
2. Run tests: ⌘+U
3. View report: ⌘+9 → Coverage

## 🎭 Mocking

### Protocol-based Mocking

```swift
protocol UserRepository {
    func fetchUser(id: String) async throws -> User
}

final class MockUserRepository: UserRepository {
    var mockUser: User?
    var shouldThrowError = false

    func fetchUser(id: String) async throws -> User {
        if shouldThrowError {
            throw NSError(domain: "test", code: -1)
        }
        return mockUser ?? User(name: "Mock", email: "mock@example.com")
    }
}
```

## 🖼️ UI Testing

### Basic UI Test

```swift
import XCUITest

final class LoginUITests: XCTestCase {
    func testLoginFlow() {
        let app = XCUIApplication()
        app.launch()

        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("user@example.com")

        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("password123")

        app.buttons["Login"].tap()

        XCTAssertTrue(app.staticTexts["Welcome"].exists)
    }
}
```

## ✅ Test Checklist

Before submitting a PR, ensure:

- [ ] All tests pass: `swift test`
- [ ] Coverage is adequate
- [ ] SwiftLint passes: `swiftlint`
- [ ] Tests follow naming conventions
- [ ] Async code uses proper async/await
- [ ] UI tests are stable and not flaky
- [ ] Edge cases are tested
- [ ] Error cases are tested

## 🎯 Best Practices

1. **Use descriptive test names** - explain what's being tested
2. **One assertion concept per test** - keep tests focused
3. **Use setUp/tearDown** for common initialization
4. **Test edge cases** - empty strings, nil values, boundary conditions
5. **Avoid test interdependencies** - tests should run independently
6. **Keep tests fast** - mock slow operations
7. **Use XCTUnwrap** instead of force unwrapping
8. **Test error handling** - use XCTAssertThrowsError

## 📚 Resources

- [XCTest Documentation](https://developer.apple.com/documentation/xctest)
- [Swift Testing Best Practices](https://swift.org/documentation/articles/testing.html)
- [SwiftLint Rules](https://github.com/realm/SwiftLint/blob/main/Rules.md)

---

**Questions?** Open an issue or refer to [CONTRIBUTING.md](../CONTRIBUTING.md)
