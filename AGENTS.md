# AGENTS.md

Rules and guidelines for AI agents working in this repository. Everything in
this document is a directive, not a suggestion. A new project started from this
template should replace the Project Direction section below with its own; the
rest of this file is the shared engineering standard and stays as written.

---

## Project Direction

> **TEMPLATE PLACEHOLDER -- replace this whole block.**
>
> State what this project is and what it is for, in two or three sentences.
> Then list the key architectural invariants an agent must never weaken --
> the decisions that, if violated, make the change wrong regardless of whether
> it compiles and passes tests. Examples of the kind of thing that belongs
> here: what the source of truth is, which boundaries are one-way, which
> numeric representations are allowed, what is never allowed to reach a
> privileged subsystem.
>
> If the project keeps a spec, a roadmap, or a workflow doc, link them here
> and say which one is authoritative for behavior. Delete this blockquote once
> the section describes the real project.

### Agent expectations

- Follow the TTDD workflow: types first, failing test, implementation, refine.
- Honor the rules in this document for code style, testing, and quality gates.
- Edit code, tests, and configs in this repo. Humans own deploys, secrets, and
  external systems outside git.
- Never relax quality checks (clippy, tests, lints) without explicit
  permission. Ask if a check seems wrong; don't suppress.
- Don't substitute approaches, libraries, or tools without checking in. Scope
  is whatever was asked, not whatever you'd prefer.
- When an issue is pointed out, fix it immediately. The user never sends
  messages just for the sake of it.

---

## Development Commands

```bash
cargo check              # Fast compilation verification
cargo nextest run        # Run tests
cargo clippy             # Linting
cargo fmt                # Format code
```

While developing, run `cargo check` and `cargo nextest run` continuously to
verify types and behavior. Only once the implementation is complete run
`cargo clippy` and fix every warning, then `cargo fmt` before committing.

**CRITICAL: Never use `cargo build` for verification.** Use `cargo check`
(faster) or `cargo nextest run` (more useful). Only use `cargo build` when you
genuinely need the binary.

**Dependencies**: Always use `cargo add <crate>` -- never manually edit
`Cargo.toml` versions. LLMs hallucinate version numbers.

**Migrations** (projects that use sqlx): never hand-write migration files. Add
`sqlx-cli` to the dev shell and go through it (`sqlx migrate add <name>`,
`sqlx migrate run`).

### Environment

- **Nix + direnv**: `direnv allow` activates the dev environment.
- All dependencies come from the Nix flake -- no `cargo install`, no
  `brew install`, no ad-hoc installs outside the flake. If a tool is missing,
  add it to the flake.

### Version control

Stacked PRs are the unit of review: one branch per PR, each based on its
predecessor, each small enough to review in one sitting.

Write operations go through the GitButler CLI (`but`), provided in the dev
shell by the `but.nix` flake input -- not `git add`, `git commit`, `git push`,
`git checkout`, or `git rebase`. Read-only git inspection (`git status`,
`git log`, `git diff`) is fine. The gitbutler agent skill is installed into
`.claude/skills/gitbutler` and `.cursor/skills/gitbutler` on shell entry; read
it for the command reference and workflow.

GitButler writes a stack-navigation footer into each PR body, but it drifts:
after a rebase, a branch add or remove, or a merge it goes stale or is missing
on PRs that were not opened through GitButler. Refresh every stacked PR's
footer with `nix run .#pr-stack-footer` after any operation that reshapes a
stack.

---

## Workflow & Policies

### TTDD (type-driven TDD)

1. **Types first**: define the types, traits, and method signatures that model
   the domain. Stub bodies with `todo!()`.
2. **Failing tests**: write tests that **compile** and fail. A build error is
   not a failing test.
3. **Implementation**: write the logic that makes the tests pass.
4. **Refine**: broaden coverage, tighten types.

Steps 1 and 2 interleave -- signatures often change to make a test compile. The
hard constraint: no behavioral logic before a compiling, failing test.

For bug fixes, same shape: a test that compiles and fails by asserting the
correct behavior, then the fix.

### PR titles and descriptions

**Titles**: lowercase, imperative, concise. Describe the outcome, not the
mechanism. No prefixes like `feat:` or `fix:`.

- Good: `reject orders that exceed the position limit`
- Good: `replace stringly-typed ids with newtypes`
- Bad: `Add validation helper for order sizing`
- Bad: `Refactor id handling to use newtype wrappers`

**Descriptions**: follow `.github/PULL_REQUEST_TEMPLATE.md` -- two sections.

- `## Motivation`: why the change is needed. The problem and the desired end
  state, not the diff. Link the issue or ADR it advances.
- `## Solution`: how the PR solves it -- approach and key decisions, one line
  per bullet. Note stack relationships, trade-offs, and follow-ups.

**No self-promotion, ever.** No "Generated with <tool>" footers, no AI
attribution, no co-author trailers -- not in commits, PRs, or code.

### Quality checks

**NEVER disable or relax a quality check without explicit permission.** That
includes clippy allows (`#[allow(clippy::*)]`), compiler-warning allows
(`#[allow(dead_code)]`, `#[allow(unused)]`), lint config loosening, and test
coverage regressions. Fix the underlying code instead of suppressing.

If fixing the code is impossible or clearly worse than suppressing (a genuine
false positive, or a lint that conflicts with project policy), STOP and ask.
Don't burn time on a convoluted workaround. When permission is granted, add a
comment explaining why the allow is necessary.

### Documentation stays in lockstep with the code

Every PR must leave the documentation true. Before handing off work, audit what
your change touched and update anything that went stale: `README.md`, this
file, any spec or roadmap the project keeps, subtree `AGENTS.md` files, and the
doc comments on the code you edited.

If a doc has drifted and it is not in your change's path, fix it in the same PR
(preferred) or open a follow-up issue immediately. Stale documentation is a
bug: don't ship work that introduces it, don't ignore it when you see it.

### When stuck

If a fix doesn't work after three attempts, stop guessing and read the official
documentation for the thing you're fighting.

---

## Code Style

### Functional programming

Prefer declarative, expression-oriented code: `map`, `filter`, `fold`,
`collect` over imperative loops; pure functions over side effects;
immutability by default; method chaining over intermediate variables.

The smell to avoid: `let mut items = Vec::new(); for x in xs { items.push(..) }`
where `.map(..).collect()` would do. `mut` is fine in idiomatic contexts --
`.scan()`, `.try_fold()`, builder patterns.

### No boolean blindness

Raw booleans obscure meaning at call sites. Prefer a discriminated union
(`enum ModalState { Open, Closed }`) or a named function (`open_modal()`) over
`set_is_open(true)`.

### ASCII for code, Unicode for users

The split is by **audience**, not by file type.

**ASCII** (the default): code, comments, identifiers, type names, log
messages, commit subjects, PR titles, documentation prose, config files, and
developer-console output. Use `*` not a multiplication sign, `->` not an arrow,
`~` not an approximation sign, `--` not an em-dash, `beta` not a Greek letter.

**Unicode** only where the audience is a user: UI text rendered in the app, CLI
output presented to a user, product-facing error messages, accessibility
strings, and UI strings quoted verbatim inside documentation. Inside those
quotes write the exact character the user sees; the prose around the quote
stays ASCII.

A bulk find/replace of Unicode punctuation across the repo is not a safe
refactor -- it mangles user-facing strings and the docs that quote them.

### Self-documenting code

Documentation comments (docstrings, API docs) are good. Implementation comments
are a last resort -- refactor until the code is clear instead.

### Descriptive names

- Name what a thing IS. Avoid `result`, `data`, `value`, `item`.
- No single-letter variable names anywhere -- not in closures, locals,
  parameters, or destructuring. `|r|` is unreadable; write `|rate|`.
- No abbreviations unless universally understood (`id`, `url`, `http`, `msg`,
  `tx`). This includes import aliases: alias to the full name, not to initials.

### Colocate types

Keep types with the code that uses them, not in a separate file.

### No hidden defaults

Never add a default value (`#[serde(default)]`, `unwrap_or`, `Default` impls
for config) without being explicitly asked. Required configuration must fail
loudly when missing, not silently run on a value the user never chose. Ship an
example config file so new setups have a starting point.

### Logging

Use levels semantically:

- **ERROR**: something failed and needs attention.
- **WARN**: something unexpected happened but the system recovered (retries
  exhausted, fallback used).
- **INFO**: high-level lifecycle events only (service ready, graceful
  shutdown). One or two lines per startup, not per component.
- **DEBUG**: operational detail useful for troubleshooting (component
  initialized, request handled, config applied).
- **TRACE**: fine-grained execution flow for deep debugging.

Message quality:

- Log completion, not initiation: `"http server ready"`, not
  `"starting http server"`. Never log both at the same level.
- Messages are grep-friendly and unique. No `"error occurred"`,
  `"operation failed"`, `debug!("here")`, or `info!("initialized")` -- a log
  line must be clear without reading the module path it came from.
- Context goes in structured fields, not interpolated strings:
  `info!(port = config.port, "server ready")`, never
  `info!("server ready on port {}", config.port)`.
- Never log credentials, tokens, or personal data.

### Scripts

Any script big enough to live in its own file MUST NOT be bash -- use nushell
(`.nu`, shebang `#!/usr/bin/env nu`). Bash is acceptable only for short inline
blocks (CI workflow `run:` steps, Makefile recipes). Nushell has structured
data, real error handling, and predictable quoting; bash files accumulate
footguns that nushell avoids by construction.

---

## Rust Code Style

### Package by feature, not by layer

Organize by business domain, not by technical layer or language primitive.

**FORBIDDEN file names**: `types.rs`, `error.rs`, `errors.rs`, `models.rs`,
`utils.rs`, `helpers.rs`, `impl.rs`, `traits.rs`, `structs.rs`, `enums.rs`,
`config.rs`, `constants.rs`, `common.rs`, `shared.rs`, `core.rs`.

Each feature module holds all its related code: types, errors, logic. While the
project is small keep everything in `main.rs` or `lib.rs`; split only when
there are real domain boundaries.

### Type modeling

**Make invalid states unrepresentable.** This is non-negotiable.

Never use `String` where the domain has a finite set of valid values:

```rust
// FORBIDDEN: accepts "info", "debug", and also "banana"
struct Config { log_level: String }

// CORRECT
enum LogLevel { Trace, Debug, Info, Warn, Error }
struct Config { log_level: LogLevel }
```

Use enums instead of fields that can contradict each other:

```rust
// Bad
struct Order { status: String, order_id: Option<String>, error: Option<String> }

// Good: each state carries exactly the data it needs
enum OrderStatus {
    Pending,
    Completed { order_id: OrderId },
    Failed { reason: FailureReason },
}
```

**Parse, don't validate.** If a value exists, it is valid -- validation happens
once, at construction, through a smart constructor with a private inner field.
Parse external input (config, API responses) into domain types at the boundary;
never pass raw strings through the system.

**Persistent IDs are newtypes.** Never a raw `String` or `&str` for an
identifier that is persisted or crosses an async boundary -- the type system
should make `load_portfolio(ingestion_id)` a compile error.

Use typestate when a protocol must be enforced: encode "this has passed check
X" as a witness in the type, so the unchecked value cannot reach the operation
that requires the check.

### Compile-time literals, never parsed

Hardcoded values of parseable types use their compile-time macros rather than
runtime parsing -- for example `address!` / `b256!` / `fixed_bytes!` for alloy
byte types, `dec!` for `Decimal`. Runtime parsing (`FromStr`, `.parse()`) is
reserved for genuinely dynamic input at system boundaries.

### Avoid deep nesting

Keep function bodies, module structure, and tests flat.

```rust
fn validate(data: Option<&Data>) -> Result<(), Error> {
    let Some(data) = data else { return Err(Error::NoData) };
    if data.quantity <= 0 { return Err(Error::InvalidQuantity); }
    Ok(())
}
```

Early returns and `let-else` over nested `if let`. No modules inside modules.
No nested modules inside `mod tests` -- use descriptive test function names
instead. Nesting inside type definitions is the exception: an enum with struct
variants beats flattening into mutually exclusive optional fields.

### Error handling

- Use `?` and proper error types (thiserror).
- Never a `SomeError(String)` variant that throws type information away.
- Use `#[from]` to preserve error chains. Don't design error variants up front
  -- write `?` where it belongs and let `cargo check` tell you which `#[from]`
  variants you need.

**`#[from]` variant names mirror the source error type, not the operation.**
`?` auto-converts every matching error, so an operation-specific name becomes a
lie the moment a second operation produces the same error type.

- FORBIDDEN: `ReadConfig(#[from] std::io::Error)`
- CORRECT: `Io(#[from] std::io::Error)`
- FORBIDDEN: `ParseConfig(#[from] toml::de::Error)`
- CORRECT: `Toml(#[from] toml::de::Error)`

**Never fabricate another crate's error.** Constructing
`std::io::Error::new(...)` to signal your own condition lies about the error's
origin and misleads whoever debugs it. Define your own variant.

### Defensive programming

Treat persisted state, external responses, configuration, arithmetic, and
cross-module inputs as capable of violating your assumptions. Enforce
invariants in types where possible, and at the narrowest boundary otherwise.

An invariant violation returns a specific typed error. It never panics, never
silently coerces the value, never invents a fallback, and never continues with
partially trusted state. Every such check gets a regression test covering the
malformed or impossible shape alongside the valid path.

Small custom macros are welcome when they remove genuinely mechanical
boilerplate and make the invariant easier to read at every call site. Keep the
domain operation, control flow, types, and error path visible; if understanding
the macro means reconstructing hidden behavior, write the explicit code.

### Zero tolerance for panics in non-test code

FORBIDDEN in production code: `unwrap()`, `expect()`, `panic!()`,
`unreachable!()`, `unimplemented!()`, indexing that can panic (`vec[i]` -- use
`.get(i)`), and unchecked arithmetic where overflow is possible. Enforce this
with workspace clippy lints.

All of the above are fine inside `#[cfg(test)]`.

`todo!()` is encouraged during the types-first stage of TTDD and must be gone
before the work is complete. Any `todo!()` in finished code is unacceptable.

### Module organization

Public API first, private helpers below -- consumers read the interface, not
the implementation, and diffs surface the important changes first.

Use the most restrictive visibility that works: private over `pub(super)` over
`pub(crate)` over `pub`. Restrictive visibility lets the compiler find dead
code; `pub` blinds it.

### Import organization

Two groups, blank line between: external (`std`, `tokio`, `serde`), then
internal (`crate::`, `super::`). No function-level imports, except
enum-variant imports inside a function body.

**No aliases to dodge name conflicts** -- use qualified paths, so meaning is
clear at the usage site instead of requiring a jump to the `use` block.

**Tracing macros are unqualified.** `use tracing::error;` then
`error!(error = %err, "request failed")`, not `tracing::error!(...)`.

---

## Testing

### Testing pyramid

More tests at the lower levels, fewer at the higher:

1. **Property tests** (proptest) -- most numerous, for invariants.
2. **Unit tests** -- exhaustive edge cases, fast feedback.
3. **Integration tests** -- components working together, externals mocked.
4. **E2E tests** -- fewest, but required for full-system orchestration.

The pyramid is about quantity, not avoidance. MANY property and unit tests,
SOME integration tests, a FEW e2e tests -- but e2e tests are mandatory for
verifying that async processes coordinate, that startup/shutdown and recovery
behave, and that flows spanning several components hold together.

### E2E tests: strict definition

E2E tests live in `tests/`, never in `src/`. A test is only e2e if it:

1. Spins up the full service.
2. Uses ONLY the public API, as an external consumer would.
3. Mocks only truly external systems.
4. Asserts correctness through public responses.

A test that reaches for internal types -- for setup or for verification -- is
not e2e. It belongs in `src/` as a unit or integration test.

### Testing guidelines

- Write the test before changing the logic. When testing existing code, don't
  assume the current behavior is correct; it may be the bug.
- Tests assert CORRECT behavior. Never write a test that "documents" a known
  gap by asserting the wrong result.
- Never test language features -- test business logic:

```rust
// Bad: tests struct assignment, not our code
let request = Request { quantity: 100 };
assert_eq!(request.quantity, 100);

// Good: tests our validation logic
let result = validate_order(OrderRequest { quantity: -10 });
assert!(matches!(result, Err(OrderError::InvalidQuantity)));
```

- Bug reproductions must exercise real code paths with realistic fixtures. A
  test that hand-constructs invalid state and shows it fails proves only that
  invalid things are invalid. Build the input through the same functions
  production uses, then show the system produces the wrong result -- that is
  the bug.
- Put context in the `assert!` message rather than debugging with `println!`.
- Cover happy paths in integration and e2e tests; cover edge cases in unit
  tests.
