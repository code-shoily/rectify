```text
    ╭────────────────────────────────────╮
    │      ╭────╮  ╭────╮  ╭────╮        │
    │      │    │  │    │  │    │        │
    ╰──────┴────┴──┴────┴──┴────┴────────╯
    
    ═══════════════════════════════════════
    
    ════════════ rectify ═══════════════
    
    ═══════════════════════════════════════
    
    ╭──────┬────┬──┬────┬──┬────┬────────╮
    │      │    │  │    │  │    │        │
    │      ╰────╯  ╰────╯  ╰────╯        │
    ╰────────────────────────────────────╯
```

# rectify

[![Package Version](https://img.shields.io/hexpm/v/rectify)](https://hex.pm/packages/rectify)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/rectify/)

Railway-oriented programming utilities for Gleam. A port of FsToolkit.ErrorHandling concepts, focusing on **accumulating validation errors** instead of failing fast.

```sh
gleam add rectify@1
```

## Quick Start

```gleam
import rectify

// Individual validators return Validation
type User {
  User(name: String, email: String, age: Int)
}

fn validate_name(name: String) -> rectify.Validation(String, String) {
  case string.trim(name) {
    "" -> rectify.invalid("Name is required")
    n -> rectify.valid(n)
  }
}

fn validate_email(email: String) -> rectify.Validation(String, String) {
  case string.contains(email, "@") {
    True -> rectify.valid(email)
    False -> rectify.invalid("Invalid email address")
  }
}

fn validate_age(age: Int) -> rectify.Validation(Int, String) {
  case age >= 0 && age <= 150 {
    True -> rectify.valid(age)
    False -> rectify.invalid("Age must be between 0 and 150")
  }
}

// Collect ALL errors, not just the first one
let result = rectify.map3(
  validate_name(""),
  validate_email("not-an-email"),
  validate_age(200),
  User,
)

// result = Invalid(["Name is required", "Invalid email address", "Age must be between 0 and 150"])
// vs Result which would only give you the first error
```

## Why Validation instead of Result?

| `Result(a, e)` | `Validation(a, e)` |
|----------------|-------------------|
| Stops at first error | Accumulates all errors |
| Single error in `Error(e)` | List of errors in `Invalid(List(e))` |
| Good for early exit | Good for form validation |
| Fail-fast | Report-all |

## Modules

### `rectify` - Validation

The core `Validation` type for accumulating errors.

```gleam
import rectify

// Constructors
rectify.valid(42)                    // Valid(42)
rectify.invalid("oops")              // Invalid(["oops"])
rectify.invalid_many(["a", "b"])     // Invalid(["a", "b"])

// Mapping - errors accumulate!
rectify.map2(valid(2), valid(3), fn(a, b) { a + b })        // Valid(5)
rectify.map2(invalid("a"), invalid("b"), fn(a, b) { a + b }) // Invalid(["a", "b"])
rectify.map3(v1, v2, v3, User)  // Up to map5 available

// Conversions
rectify.to_result(valid(42))           // Ok(42)
rectify.of_result(Error("e"))          // Invalid(["e"])
```

### `rectify/option` - Option Utilities

Additional helpers for Gleam's `Option` type.

```gleam
import rectify/option as ropt

// Predicates
ropt.is_some(Some(42))    // True
ropt.is_none(None)        // True

// Defaults
ropt.default_to(Some(42), 0)     // 42
ropt.default_to(None, 0)         // 0
ropt.default_with(None, fn() { expensive() })

// Combining
ropt.map2(Some(2), Some(3), fn(a, b) { a + b })  // Some(5)
ropt.map3(opt1, opt2, opt3, fn(a, b, c) { a + b + c })

// Collections
ropt.choose_somes([Some(1), None, Some(2)])  // [1, 2]
ropt.first_some([None, Some(2), Some(3)])    // Some(2)

// Conversions
ropt.to_result(Some(42), "not found")  // Ok(42)
ropt.of_result(Ok(42))                 // Some(42)
```

### `rectify/result_option` - Result<Option> Helpers

For working with `Result(Option(a), e)` - a common pattern for operations that can fail AND may not return a value.

```gleam
import rectify/result_option as ro

// Constructors
ro.some(42)        // Ok(Some(42))
ro.none()          // Ok(None)
ro.error("e")      // Error("e")

// Mapping
ro.map(Ok(Some(5)), fn(n) { n * 2 })     // Ok(Some(10))
ro.bind(Ok(Some(5)), fn(n) { ro.some(n * 2) })

// Predicates
ro.is_some(Ok(Some(42)))     // True
ro.is_none(Ok(None))         // True
ro.is_error(Error("e"))      // True

// Conversions
ro.to_option(Ok(Some(42)))        // Some(42)
ro.of_option(Some(42))            // Ok(Some(42))
ro.of_result(Ok(42))              // Ok(Some(42))
ro.to_result(Ok(Some(42)), 0)     // Ok(42)
ro.to_result(Ok(None), 0)         // Ok(0) - default value
```

## Common Patterns

### Form Validation

```gleam
import rectify

type Form {
  Form(name: String, email: String, age: Int)
}

fn validate_form(name: String, email: String, age: Int) {
  rectify.map3(
    validate_name(name),
    validate_email(email),
    validate_age(age),
    Form,
  )
  |> rectify.to_result  // Convert to Result for standard error handling
}

// Usage
case validate_form("", "bad-email", -5) {
  Ok(form) -> create_user(form)
  Error(errors) -> show_validation_errors(errors)
}
```

### Option Chaining

```gleam
import rectify/option as ropt
import gleam/option.{Some, None}

// Combine multiple optional lookups
let result = ropt.map3(
  dict.get(users, "alice"),     // Some(user1)
  dict.get(users, "bob"),       // None
  dict.get(users, "charlie"),   // Some(user3)
  fn(a, b, c) { [a, b, c] }
)
// result = None (because bob was None)

// Find first available fallback
ropt.first_some([
  dict.get(config, "primary_url"),
  dict.get(config, "fallback_url"),
  Some("default"),
])
```

### Result<Option> Pipeline

```gleam
import rectify/result_option as ro

// Database lookup that can fail (Error) or not find result (Ok(None))
fn find_user(id: Int) -> Result(Option(User), DbError) {
  // ... database code
}

// Transform through pipeline
find_user(42)
|> ro.map(fn(user) { user.name })
|> ro.bind(fn(name) { 
  case name {
    "" -> ro.none()
    _ -> ro.some(name)
  }
})
|> ro.to_result("unknown")  // Get Result(String, String)
```

## Comparison with Gleam's Result

```gleam
// Result - fail fast
let r1 = Ok(1)
let r2 = Error("error 1")
let r3 = Error("error 2")

use a <- result.try(r1)
use b <- result.try(r2)  // Stops here, never sees "error 2"
use c <- result.try(r3)
Ok(a + b + c)
// Error("error 1")

// Validation - collect all
let v1 = rectify.valid(1)
let v2 = rectify.invalid("error 1")
let v3 = rectify.invalid("error 2")

rectify.map3(v1, v2, v3, fn(a, b, c) { a + b + c })
// Invalid(["error 1", "error 2"])
```

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam docs   # Generate documentation
```

## Acknowledgements

Inspired by the excellent [FsToolkit.ErrorHandling](https://github.com/demystifyfp/FsToolkit.ErrorHandling) library for F#.

## License

This project is licensed under the [MIT License](LICENSE).
