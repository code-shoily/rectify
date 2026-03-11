//// Rectify - Railway-oriented programming utilities for Gleam
////
//// A port of FsToolkit.ErrorHandling concepts:
//// - Validation: Applicative functor for collecting multiple errors
//// - Result/Option utilities for composing fallible operations

import gleam/list

// ==========================================
// Validation Type
// ==========================================

/// Validation applicative - collect multiple errors instead of fail-fast.
/// 
/// Unlike `Result` which stops at the first `Error`, `Validation` accumulates
/// all errors before returning them together.
pub type Validation(a, e) {
  Valid(a)
  Invalid(List(e))
}

// ==========================================
// Validation Constructors
// ==========================================

/// Create a successful validation.
pub fn valid(a: a) -> Validation(a, e) {
  Valid(a)
}

/// Create a failed validation with a single error.
pub fn invalid(e: e) -> Validation(a, e) {
  Invalid([e])
}

/// Create a failed validation with multiple errors.
pub fn invalid_many(es: List(e)) -> Validation(a, e) {
  Invalid(es)
}

// ==========================================
// Validation Basic Operations
// ==========================================

/// Map a function over a validation.
///
/// ## Examples
///
/// ```gleam
/// valid(5) |> map(fn(n) { n * 2 })
/// // -> Valid(10)
/// ```
///
/// ```gleam
/// invalid("error") |> map(fn(n) { n * 2 })
/// // -> Invalid(["error"])
/// ```
pub fn map(validation: Validation(a, e), f: fn(a) -> b) -> Validation(b, e) {
  case validation {
    Valid(a) -> Valid(f(a))
    Invalid(es) -> Invalid(es)
  }
}

/// Map over two validations, combining their errors if both fail.
///
/// ## Examples
///
/// ```gleam
/// map2(valid(2), valid(3), fn(a, b) { a + b })
/// // -> Valid(5)
/// ```
///
/// ```gleam
/// map2(invalid("e1"), invalid("e2"), fn(a, b) { a + b })
/// // -> Invalid(["e1", "e2"])
/// ```
pub fn map2(
  v1: Validation(a, e),
  v2: Validation(b, e),
  f: fn(a, b) -> c,
) -> Validation(c, e) {
  case v1, v2 {
    Valid(a), Valid(b) -> Valid(f(a, b))
    Invalid(es1), Invalid(es2) -> Invalid(list.append(es1, es2))
    Invalid(es), _ -> Invalid(es)
    _, Invalid(es) -> Invalid(es)
  }
}

/// Map over three validations.
///
/// Similar to `map2`, but for three validations. Gathers all errors if any
/// of the validations are invalid.
pub fn map3(
  v1: Validation(a, e),
  v2: Validation(b, e),
  v3: Validation(c, e),
  f: fn(a, b, c) -> d,
) -> Validation(d, e) {
  map2(map2(v1, v2, fn(a, b) { fn(c) { f(a, b, c) } }), v3, fn(f_, c) { f_(c) })
}

/// Map over four validations.
///
/// Similar to `map2`, but for four validations. Gathers all errors if any
/// of the validations are invalid.
pub fn map4(
  v1: Validation(a, e),
  v2: Validation(b, e),
  v3: Validation(c, e),
  v4: Validation(d, e),
  f: fn(a, b, c, d) -> g,
) -> Validation(g, e) {
  map2(map3(v1, v2, v3, fn(a, b, c) { fn(d) { f(a, b, c, d) } }), v4, fn(f_, d) {
    f_(d)
  })
}

/// Map over five validations.
///
/// Similar to `map2`, but for five validations. Gathers all errors if any
/// of the validations are invalid.
pub fn map5(
  v1: Validation(a, e),
  v2: Validation(b, e),
  v3: Validation(c, e),
  v4: Validation(d, e),
  v5: Validation(g, e),
  f: fn(a, b, c, d, g) -> h,
) -> Validation(h, e) {
  map2(
    map4(v1, v2, v3, v4, fn(a, b, c, d) { fn(g) { f(a, b, c, d, g) } }),
    v5,
    fn(f_, g) { f_(g) },
  )
}

// ==========================================
// Validation Composition
// ==========================================

/// Apply a validation containing a function to a validation containing a value.
///
/// ## Examples
///
/// ```gleam
/// apply(valid(fn(x) { x * 2 }), valid(21))
/// // -> Valid(42)
/// ```
///
/// ```gleam
/// apply(invalid("e1"), invalid("e2"))
/// // -> Invalid(["e1", "e2"])
/// ```
pub fn apply(
  vf: Validation(fn(a) -> b, e),
  va: Validation(a, e),
) -> Validation(b, e) {
  map2(vf, va, fn(f, a) { f(a) })
}

/// Flatten a nested validation.
///
/// ## Examples
///
/// ```gleam
/// flatten(valid(valid(1)))
/// // -> Valid(1)
/// ```
///
/// ```gleam
/// flatten(valid(invalid("e")))
/// // -> Invalid(["e"])
/// ```
pub fn flatten(v: Validation(Validation(a, e), e)) -> Validation(a, e) {
  case v {
    Valid(inner) -> inner
    Invalid(es) -> Invalid(es)
  }
}

/// Bind/flatMap for validation (note: doesn't accumulate errors across binds).
///
/// Use this when determining the next validation step depends on the success
/// value of the previous step. Errors from the first step are preserved, but
/// errors do not accumulate with operations in the second step, because the
/// second step is never executed if the first step fails.
///
/// ## Examples
///
/// ```gleam
/// valid(1) |> bind(fn(x) { valid(x * 2) })
/// // -> Valid(2)
/// ```
///
/// ```gleam
/// invalid("e") |> bind(fn(x) { valid(x * 2) })
/// // -> Invalid(["e"])
/// ```
pub fn bind(
  v: Validation(a, e),
  f: fn(a) -> Validation(b, e),
) -> Validation(b, e) {
  case v {
    Valid(a) -> f(a)
    Invalid(es) -> Invalid(es)
  }
}

// ==========================================
// Validation Predicates
// ==========================================

/// Check if validation is valid.
///
/// ## Examples
///
/// ```gleam
/// is_valid(valid(1))
/// // -> True
/// ```
///
/// ```gleam
/// is_valid(invalid("e"))
/// // -> False
/// ```
pub fn is_valid(v: Validation(a, e)) -> Bool {
  case v {
    Valid(_) -> True
    Invalid(_) -> False
  }
}

/// Check if validation has errors.
///
/// ## Examples
///
/// ```gleam
/// is_invalid(invalid("e"))
/// // -> True
/// ```
///
/// ```gleam
/// is_invalid(valid(1))
/// // -> False
/// ```
pub fn is_invalid(v: Validation(a, e)) -> Bool {
  !is_valid(v)
}

// ==========================================
// Validation Conversions
// ==========================================

/// Convert validation to Result (all errors as list).
///
/// ## Examples
///
/// ```gleam
/// to_result(valid(42))
/// // -> Ok(42)
/// ```
///
/// ```gleam
/// to_result(invalid_many(["a", "b"]))
/// // -> Error(["a", "b"])
/// ```
pub fn to_result(v: Validation(a, e)) -> Result(a, List(e)) {
  case v {
    Valid(a) -> Ok(a)
    Invalid(es) -> Error(es)
  }
}

/// Convert Result to Validation.
///
/// ## Examples
///
/// ```gleam
/// of_result(Ok(42))
/// // -> Valid(42)
/// ```
///
/// ```gleam
/// of_result(Error("e"))
/// // -> Invalid(["e"])
/// ```
pub fn of_result(r: Result(a, e)) -> Validation(a, e) {
  case r {
    Ok(a) -> Valid(a)
    Error(e) -> Invalid([e])
  }
}

/// Convert Result with multiple errors to Validation.
///
/// ## Examples
///
/// ```gleam
/// of_result_list(Ok(42))
/// // -> Valid(42)
/// ```
///
/// ```gleam
/// of_result_list(Error(["e1", "e2"]))
/// // -> Invalid(["e1", "e2"])
/// ```
pub fn of_result_list(r: Result(a, List(e))) -> Validation(a, e) {
  case r {
    Ok(a) -> Valid(a)
    Error(es) -> Invalid(es)
  }
}

// ==========================================
// Validation Helpers
// ==========================================

/// Run a validation and return the value or a default.
///
/// ## Examples
///
/// ```gleam
/// default_to(valid(42), 0)
/// // -> 42
/// ```
///
/// ```gleam
/// default_to(invalid("e"), 0)
/// // -> 0
/// ```
pub fn default_to(v: Validation(a, e), default: a) -> a {
  case v {
    Valid(a) -> a
    Invalid(_) -> default
  }
}

/// Run a validation with a lazy default.
///
/// ## Examples
///
/// ```gleam
/// default_with(valid(42), fn() { 0 })
/// // -> 42
/// ```
///
/// ```gleam
/// default_with(invalid("e"), fn() { 0 })
/// // -> 0
/// ```
pub fn default_with(v: Validation(a, e), f: fn() -> a) -> a {
  case v {
    Valid(a) -> a
    Invalid(_) -> f()
  }
}

/// Get errors from a validation, or empty list if Valid.
///
/// ## Examples
///
/// ```gleam
/// errors(valid(1))
/// // -> []
/// ```
///
/// ```gleam
/// errors(invalid_many(["a", "b"]))
/// // -> ["a", "b"]
/// ```
pub fn errors(v: Validation(a, e)) -> List(e) {
  case v {
    Valid(_) -> []
    Invalid(es) -> es
  }
}

/// Transform errors in a validation.
///
/// ## Examples
///
/// ```gleam
/// invalid("e") |> map_errors(fn(e) { "Error: " <> e })
/// // -> Invalid(["Error: e"])
/// ```
pub fn map_errors(v: Validation(a, e), f: fn(e) -> f) -> Validation(a, f) {
  case v {
    Valid(a) -> Valid(a)
    Invalid(es) -> Invalid(list.map(es, f))
  }
}
