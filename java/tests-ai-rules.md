
# Unit tests AI Rules

## Rules

- In every test, the assertion must be the last statement.
- Test cases must be as short as possible.
- Every test must assert at least once.
- All fields of the result of the tested method must be asserted.
- All calls to methods of external classes must be mocked and asserted.
- Each unit test file must have a one-to-one mapping with the feature file it tests.
- Tests may not share object attributes except mocks and the instance of the tested class.
- Tests may not use setUp() or tearDown() idioms.
- Tests may not use static literals or other shared constants.
- Tests may not test functionality irrelevant to their stated purpose.
- Objects must not provide functionality used only by tests.
- Tests may not assert on side effects such as logging output.
- Tests may not check the behavior of setters, getters, or constructors.
- Tests must not clean up after themselves; instead, they must prepare a clean state at the start.
- The best tests consist of a single statement.
- Tests should use Hamcrest matchers if available. For simple assertions, use JUnit assertions.
- Each test must verify only one specific behavioral pattern of the object it tests.
- Tests must use random values as inputs.
- Tests are not allowed to print any log messages.
- Tests must not wait indefinitely for any event; they must always stop waiting on a timeout.
- Tests must verify object behavior in multi-threaded, concurrent environments.
- Tests must retry potentially flaky code blocks.
- Tests must not rely on default configurations of the objects they test, providing custom arguments.
- Tests should inline small fixtures instead of loading them from files.
- Tests may create supplementary fixture objects to avoid code duplication.
- Tests must be isolated from each other.
- Any mutation of project code must lead to corresponding test failure.
- Tests must not use constants from Project code.
- Tests must not use Thread.sleep() construction.
- Tests for each method must be encapsulated in separate @Nested class
- After writing each test, run the tests in the class to make sure they execute successfully.
- If the tested class uses MapStruct mappers, then create the mappers vis `Mappers.getMapper(class);`.
- Leave blank lines between logical constructs in tests to make them easier to read.

## Naming

- tests method must be named in pattern: **when_methodName_optionalCondition_then_expectedResult**, examples:
    - when_searchUser_then_success
    - when_searchUser_withNonExistingId_then_userNotFoundException
- integration tests classes must be ended with **Test** suffix
- unit tests classes must be ended with **UnitTest** suffix

## Coverage

- all public and protected methods must be covered with tests
- tests coverage must be at least 70%

---

Most of the rules were taken from Yegor Bugayenko: https://github.com/yegor256/prompt
