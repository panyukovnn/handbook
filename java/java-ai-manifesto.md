# Manifesto: Java AI Rules for code generation

version: 1.14

- Prepare checkbox plan for every new feature, before realization, and ask user about its correctness.
- Code must be as simple as possible for understanding.
- The existing code structure must not be changed without a strong reason.
- Minor inconsistencies and typos in the existing code may be fixed.
- Every bug must be reproduced by a unit test before being fixed.
- Every new feature must be covered by a unit test before it is implemented.
- Always keep backward compatibility of external API and database structure.
- If any rule from this manifesto or instructions was not followed, or if LLM identifies missing information in instructions or user prompts needed for clearer task understanding, LLM must propose additions to AGENTS.md and instructions in AGENTS-addition.md file.
- If possible, use the appropriate skill of the agent.
- A step-by-step implementation plan and the implementation specification for every task MUST live inside the project (default location: `docs/tasks/<TASK-ID>.md`) BEFORE any code is written; implementing a task from a verbal description without a committed plan is forbidden.
- Task execution (locally or in the container) MUST be launched via the `implement-plan` skill against the plan stored in the project; improvising in bypass of this skill is forbidden.
- If an executable `claude-task` script exists in the project root, all task work MUST be performed through it (`./claude-task <path-to-plan>`) instead of running Claude directly on the host — this guarantees an isolated environment and a unified set of working rules.
- If the JetBrains MCP server is available, after editing or creating any `.java` file the agent MUST invoke the JetBrains "reformat file" action for that file.

## Code Style

- Lines MUST NOT exceed 250 characters.
- Method length MUST NOT exceed 20 lines; only trivial easy-to-read methods MAY exceed this limit.
- Class length MUST NOT exceed 250 lines.
- Methods with more than 7 arguments MUST group arguments into a dedicated wrapper type (prefer an inner record/static class).
- If the project already uses classic DTO classes, records MUST NOT replace them; records MAY be used in projects, that have already adopted records widely, or as inner static aggregators for arguments/return values.
- Enum constants MUST be in UPPER_SNAKE_CASE and each value MUST be on a new line.
- Enums with fields MUST use @Getter and @RequiredArgsConstructor.
- Long expressions MUST be wrapped with line breaks before operators and after commas in argument lists.
- Wrapped lines MUST either align with the previous expression start or be indented by 8 spaces.
- A blank line MUST appear before every return statement.
- A blank line MUST appear after closing braces (unless it is the end of a method).
- A blank line MUST appear before each control construct (if/for/try/etc.).
- A blank line MUST appear between methods, after the class declaration, and after the import block.
- A blank line MUST NOT appear between class fields declaration and class constants declaration. 
- Extra blank lines between consecutive fields MUST NOT be added.
- Complex boolean expressions and long call chains MUST be extracted into clearly named variables or methods.
- Curly braces MUST be used for all single-line statements.
- Classic switch statements MUST end each case with break.
- On Java 21+, modern switch expressions with exhaustiveness and pattern matching MUST be preferred; a default or exhaustive handling MUST be present.
- The var keyword MUST NOT be used in production code, if it is not already used in project.
- If var is adopted by project convention, var MUST be used only where the type is obvious (object creation/builder) and MUST NOT be used for method results or Stream API chains.
- Constants used fewer than two times MUST NOT be extracted unless extraction clearly improves readability.
- Shared constants used across modules MUST be placed in util package classes grouped by meaning, MUST have a private constructor, and MUST contain no state or logic.
- Field order MUST be: static first, then non-static.
- Field access order MUST be: private, package-private, protected, public.
- Method order MUST be: public, protected, package-private, private.
- Functional call chains MUST be split across lines (one step per line where practical).
- In equals comparisons, the left operand MUST be a known non-null value (e.g., a constant or enum literal).
- Javadoc and comments MUST be written in Russian.
- Classes and interfaces MUST NOT be documented; methods/fields with non-obvious logic MUST be documented; @Override methods MUST NOT be documented.
- Private methods MUST be documented when needed to clarify the contract.
- Empty method implementations MUST contain an explicit comment stating no implementation is required.
- Comments explaining intentionally non-obvious logic MUST be present; superfluous comments MUST be avoided.
- Multi-line string literals SHOULD use Java 17 text blocks (`"""`) instead of concatenating single-line strings with `+` and line breaks, where the project's Java version allows it.
- SQL keywords MUST be UPPERCASE; SQL MUST be formatted multi-line and readably.
- Error and log messages must always be a single sentence, with no periods inside.
- Code MUST NOT contain magic numbers, all values, which may be dynamicly changed must be written in application.yml
- Create `impl` package for service interfaces implementation classes.
- Methods MUST never return `null`; if returning `null` is unavoidable, the method MUST be annotated with `@Nullable` from `jakarta.annotation`.
- Methods SHOULD avoid checking incoming arguments for validity, except methods in utility classes.
- If `null` is passed as an argument, this argument MUST be annotated with `@Nullable`.
- Reflection on object internals is prohibited.
- Exception messages must include as much context as possible.
- Direct DB modifications (DROP/DELETE schema, table, column), editing Liquibase checksums, and any destructive DB operations MUST NOT be performed without explicit and unambiguous user instruction specifying the exact object; if the target schema/table is not specified, LLM MUST ask for clarification before proceeding.

## Naming

- Names MUST be specific, self-explanatory, and answer what/why/how; 
- Digits in names MUST NOT be used, except repetitive objects in tests.
- HTTP endpoint paths MUST be kebab-case.
- URL path params and query params MUST be camelCase.
- JSON field names MUST be camelCase.
- JSON enum values MUST be UPPER_SNAKE_CASE.
- Package names MUST be lowercase without underscores or hyphens; compound words MUST be concatenated.
- The base package MUST start with the project group-id and end with the microservice name.
- Abbreviations in package names MUST NOT be used (use controller, exception, not ctrl, ex).
- Subpackages MUST reflect logical grouping; one nesting level SHOULD be used for simple groupings; deeper levels MUST be justified by clear necessity.
- Project code MUST be organized into conventional packages (e.g., aspect, client, config, controller, dto, exception, listener, mapper, model, property, repository, scheduler, service with domain, util, webfilter).
- Method names MUST be camelCase and begin with a verb that reflects the action.
- Variables and fields MUST be camelCase; constants MUST be UPPER_SNAKE_CASE.
- Names MUST be nouns for data holders; boolean field names MUST NOT start with is/has.
- Names MUST NOT be based on current literal content; names MUST reflect purpose/role of containing data.
- Collection variables MUST use plural nouns; time-interval variables MUST include time units (e.g., ttlHours).
- Enum constant names MUST be UPPER_SNAKE_CASE with one value per line.
- Class and interface names MUST be PascalCase, be domain nouns, be unique project-wide, and reflect purpose.
- Entity class names MUST match DB table names; when conflicts occur, the Entity suffix MAY be used.
- Exception class names MUST end with the Exception suffix.
- Enum type names MUST NOT end with Enum; record type names MUST NOT end with Record.
- Class names MUST NOT be vague/common words (Helper, Manager, Service, Scheduler) and MUST NOT clash with framework/library class names (Controller, Validator, KafkaListener, etc.).
- Configuration file names (YML/properties/XML) MUST be kebab-case; YAML files SHOULD use the .yml extension consistently within the project.
- Liquibase migration and SQL file names MUST be snake_case.
- Properties keys in YAML MUST be kebab-case or camelCase consistently; related settings MUST be grouped under a common prefix; units MUST be included in names where applicable; each group MUST have its own @ConfigurationProperties class.
- Database identifiers MUST be snake_case and MUST avoid SQL/DB reserved words and generic terms.
- Table names MUST be nouns (singular preferred unless team conventions differ).
- Many-to-many join tables MUST be named table1_table2 with logical or alphabetical order; the second table name MAY be plural when appropriate.
- Column names MUST be nouns reflecting stored data; foreign keys MUST follow `<table>_id` naming.
- Indexes and constraints MUST follow the prefix_table_column1_column2 pattern; allowed prefixes: pkey_, key_, excl_, idx_, fkey_, check_.

# Project knowledge protocol

- Treat AGENTS.md as the canonical, agent-agnostic source of persistent project instructions. Agent-specific files such as CLAUDE.md and QWEN.md should reference AGENTS.md instead of duplicating its contents.
- Add only durable knowledge that is likely to affect future work. Session history, one-off task details, and information already available in project files or configuration do not belong in AGENTS.md.
- Place project-specific additions above the `# Manifesto: Java AI Rules for code generation` heading. The heading must remain below all such additions so the manifesto can be updated independently.
- Update AGENTS.md whenever any of the following occurs:
  - The user states a stable project preference — add it under `## Preferences & Style`.
  - A mistake reveals a reusable project-specific lesson — add the preventive rule under `## Mistakes & Lessons`.
  - Durable project knowledge is discovered — add architecture decisions, naming conventions, deployment constraints, or non-obvious key paths under `## Project Knowledge`.
  - A reusable capability is missing — propose the pattern, script, alias, or workflow under `## Skill Suggestions`.
- Before adding or editing guidance, search AGENTS.md for an existing rule and update that single source of truth instead of duplicating it.
- Keep every addition concise, actionable, and independent of a specific AI agent or vendor.
- If this protocol becomes noisy, redundant, or incomplete, propose a focused improvement to it.
