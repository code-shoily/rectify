//// ResultOption utilities for Rectify
////
//// Helpers for working with `Result(Option(a), e)` — a common pattern
//// for operations that can fail AND may not return a value.
////
//// We refer to this as "ResultOption" for brevity, but it's not a
//// distinct type — just the composed `Result(Option(a), e)` pattern.
////
//// Instead of nested pattern matching, use these combinators.

import gleam/option.{type Option, None, Some}

// ==========================================
// Constructors
// ==========================================

/// Create a `Result` containing `Some` value.
///
/// ## Examples
///
/// ```gleam
/// some(42)
/// // -> Ok(Some(42))
/// ```
pub fn some(a: a) -> Result(Option(a), e) {
  Ok(Some(a))
}

/// Create a `Result` containing `None`.
///
/// ## Examples
///
/// ```gleam
/// none()
/// // -> Ok(None)
/// ```
pub fn none() -> Result(Option(a), e) {
  Ok(None)
}

/// Create an error `Result`.
///
/// ## Examples
///
/// ```gleam
/// error("not found")
/// // -> Error("not found")
/// ```
pub fn error(e: e) -> Result(Option(a), e) {
  Error(e)
}

// ==========================================
// Mapping
// ==========================================

/// Map over the value inside ResultOption, if both succeed.
///
/// ## Examples
///
/// ```gleam
/// map(Ok(Some(5)), fn(n) { n * 2 })
/// // -> Ok(Some(10))
/// ```
///
/// ```gleam
/// map(Ok(None), fn(n) { n * 2 })
/// // -> Ok(None)
/// ```
///
/// ```gleam
/// map(Error("e"), fn(n) { n * 2 })
/// // -> Error("e")
/// ```
pub fn map(ro: Result(Option(a), e), f: fn(a) -> b) -> Result(Option(b), e) {
  case ro {
    Ok(Some(a)) -> Ok(Some(f(a)))
    Ok(None) -> Ok(None)
    Error(e) -> Error(e)
  }
}

/// Bind over ResultOption.
///
/// ## Examples
///
/// ```gleam
/// bind(Ok(Some(5)), fn(n) { Ok(Some(n * 2)) })
/// // -> Ok(Some(10))
/// ```
///
/// ```gleam
/// bind(Ok(None), fn(n) { Ok(Some(n * 2)) })
/// // -> Ok(None)
/// ```
pub fn bind(
  ro: Result(Option(a), e),
  f: fn(a) -> Result(Option(b), e),
) -> Result(Option(b), e) {
  case ro {
    Ok(Some(a)) -> f(a)
    Ok(None) -> Ok(None)
    Error(e) -> Error(e)
  }
}

// ==========================================
// Conversions
// ==========================================

/// Convert ResultOption to `Option(a)`, losing error information.
///
/// ## Examples
///
/// ```gleam
/// to_option(Ok(Some(42)))
/// // -> Some(42)
/// ```
///
/// ```gleam
/// to_option(Ok(None))
/// // -> None
/// ```
///
/// ```gleam
/// to_option(Error("e"))
/// // -> None
/// ```
pub fn to_option(ro: Result(Option(a), e)) -> Option(a) {
  case ro {
    Ok(Some(a)) -> Some(a)
    Ok(None) | Error(_) -> None
  }
}

/// Convert `Option` to ResultOption, wrapping in `Ok`.
///
/// ## Examples
///
/// ```gleam
/// of_option(Some(42))
/// // -> Ok(Some(42))
/// ```
///
/// ```gleam
/// of_option(None)
/// // -> Ok(None)
/// ```
pub fn of_option(opt: Option(a)) -> Result(Option(a), e) {
  Ok(opt)
}

/// Convert Result to ResultOption, wrapping success in `Some`.
///
/// ## Examples
///
/// ```gleam
/// of_result(Ok(42))
/// // -> Ok(Some(42))
/// ```
///
/// ```gleam
/// of_result(Error("e"))
/// // -> Error("e")
/// ```
pub fn of_result(result: Result(a, e)) -> Result(Option(a), e) {
  case result {
    Ok(a) -> Ok(Some(a))
    Error(e) -> Error(e)
  }
}

/// Convert ResultOption to a plain `Result`, with a default for `None`.
///
/// ## Examples
///
/// ```gleam
/// to_result(Ok(Some(42)), 0)
/// // -> Ok(42)
/// ```
///
/// ```gleam
/// to_result(Ok(None), 0)
/// // -> Ok(0)
/// ```
///
/// ```gleam
/// to_result(Error("e"), 0)
/// // -> Error("e")
/// ```
pub fn to_result(ro: Result(Option(a), e), default: a) -> Result(a, e) {
  case ro {
    Ok(Some(a)) -> Ok(a)
    Ok(None) -> Ok(default)
    Error(e) -> Error(e)
  }
}

// ==========================================
// Predicates
// ==========================================

/// Check if ResultOption contains `Some` value.
///
/// ## Examples
///
/// ```gleam
/// is_some(Ok(Some(42)))
/// // -> True
/// ```
///
/// ```gleam
/// is_some(Ok(None))
/// // -> False
/// ```
///
/// ```gleam
/// is_some(Error("e"))
/// // -> False
/// ```
pub fn is_some(ro: Result(Option(a), e)) -> Bool {
  case ro {
    Ok(Some(_)) -> True
    _ -> False
  }
}

/// Check if ResultOption contains `None`.
///
/// ## Examples
///
/// ```gleam
/// is_none(Ok(None))
/// // -> True
/// ```
///
/// ```gleam
/// is_none(Ok(Some(42)))
/// // -> False
/// ```
///
/// ```gleam
/// is_none(Error("e"))
/// // -> False
/// ```
pub fn is_none(ro: Result(Option(a), e)) -> Bool {
  case ro {
    Ok(None) -> True
    _ -> False
  }
}

// ==========================================
// Defaults
// ==========================================

/// Unwrap the `Option` inside `Result`, using a default for `None`.
/// Returns the value if `Some`, the default if `None`, or preserves `Error`.
///
/// ## Examples
///
/// ```gleam
/// unwrap_option(Ok(Some(42)), 0)
/// // -> Ok(42)
/// ```
///
/// ```gleam
/// unwrap_option(Ok(None), 0)
/// // -> Ok(0)
/// ```
///
/// ```gleam
/// unwrap_option(Error("e"), 0)
/// // -> Error("e")
/// ```
pub fn unwrap_option(ro: Result(Option(a), e), default: a) -> Result(a, e) {
  case ro {
    Ok(Some(a)) -> Ok(a)
    Ok(None) -> Ok(default)
    Error(e) -> Error(e)
  }
}

/// Unwrap the `Option` inside `Result`, computing a default lazily for `None`.
/// Returns the value if `Some`, computes `default` if `None`, or preserves `Error`.
///
/// ## Examples
///
/// ```gleam
/// unwrap_option_lazy(Ok(Some(42)), fn() { 0 })
/// // -> Ok(42)
/// ```
///
/// ```gleam
/// unwrap_option_lazy(Ok(None), fn() { 100 })
/// // -> Ok(100)
/// ```
///
/// ```gleam
/// unwrap_option_lazy(Error("e"), fn() { 0 })
/// // -> Error("e")
/// ```
pub fn unwrap_option_lazy(
  ro: Result(Option(a), e),
  f: fn() -> a,
) -> Result(a, e) {
  case ro {
    Ok(Some(a)) -> Ok(a)
    Ok(None) -> Ok(f())
    Error(e) -> Error(e)
  }
}
