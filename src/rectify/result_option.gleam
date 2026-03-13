//// ResultOption utilities for Rectify
////
//// Helpers for working with `Result(Option(a), e)` — a common pattern
//// for operations that can fail AND may not return a value.
////
//// We refer to this as "ResultOption" for brevity, but it's not a
//// distinct type — just the composed `Result(Option(a), e)` pattern.
////
//// Instead of nested pattern matching, use these combinators.

import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result

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
// Combining
// ==========================================

/// Combine two ResultOptions into a tuple.
/// Returns Error if either is Error, Ok(None) if either is Ok(None),
/// or Ok(Some(#(a, b))) if both are Ok(Some).
///
/// ## Examples
///
/// ```gleam
/// zip(Ok(Some(1)), Ok(Some(2)))
/// // -> Ok(Some(#(1, 2)))
/// ```
///
/// ```gleam
/// zip(Ok(Some(1)), Ok(None))
/// // -> Ok(None)
/// ```
///
/// ```gleam
/// zip(Ok(Some(1)), Error("e"))
/// // -> Error("e")
/// ```
pub fn zip(
  ro1: Result(Option(a), e),
  ro2: Result(Option(b), e),
) -> Result(Option(#(a, b)), e) {
  case ro1, ro2 {
    Ok(Some(a)), Ok(Some(b)) -> Ok(Some(#(a, b)))
    Ok(None), _ | _, Ok(None) -> Ok(None)
    Error(e), _ -> Error(e)
    _, Error(e) -> Error(e)
  }
}

/// Combine three ResultOptions into a tuple.
/// Returns Error if any is Error, Ok(None) if any is Ok(None),
/// or Ok(Some(#(a, b, c))) if all are Ok(Some).
///
/// ## Examples
///
/// ```gleam
/// zip3(Ok(Some(1)), Ok(Some(2)), Ok(Some(3)))
/// // -> Ok(Some(#(1, 2, 3)))
/// ```
///
/// ```gleam
/// zip3(Ok(Some(1)), Ok(None), Ok(Some(3)))
/// // -> Ok(None)
/// ```
///
/// ```gleam
/// zip3(Ok(Some(1)), Error("e"), Ok(Some(3)))
/// // -> Error("e")
/// ```
pub fn zip3(
  ro1: Result(Option(a), e),
  ro2: Result(Option(b), e),
  ro3: Result(Option(c), e),
) -> Result(Option(#(a, b, c)), e) {
  case ro1, ro2, ro3 {
    Ok(Some(a)), Ok(Some(b)), Ok(Some(c)) -> Ok(Some(#(a, b, c)))
    Ok(None), _, _ | _, Ok(None), _ | _, _, Ok(None) -> Ok(None)
    Error(e), _, _ -> Error(e)
    _, Error(e), _ -> Error(e)
    _, _, Error(e) -> Error(e)
  }
}

// ==========================================
// Collections
// ==========================================

/// Apply a function that returns ResultOption to each element of a list,
/// collecting the results.
///
/// - If any function returns `Error(e)`, returns `Error(e)` (fail fast)
/// - If all are `Ok` but any are `Ok(None)`, returns `Ok(None)`
/// - If all are `Ok(Some(value))`, returns `Ok(Some([values]))`
///
/// This is useful for operations like "look up all these IDs in the database,
/// fail if any lookup errors, return None if any not found".
///
/// ## Examples
///
/// ```gleam
/// // All found
/// traverse([1, 2, 3], fn(id) { Ok(Some(id * 10)) })
/// // -> Ok(Some([10, 20, 30]))
/// ```
///
/// ```gleam
/// // One not found
/// traverse([1, 2, 3], fn(id) {
///   case id == 2 {
///     True -> Ok(None)
///     False -> Ok(Some(id * 10))
///   }
/// })
/// // -> Ok(None)
/// ```
///
/// ```gleam
/// // One errors
/// traverse([1, 2, 3], fn(id) {
///   case id == 2 {
///     True -> Error("not found")
///     False -> Ok(Some(id * 10))
///   }
/// })
/// // -> Error("not found")
/// ```
pub fn traverse(
  items: List(a),
  f: fn(a) -> Result(Option(b), e),
) -> Result(Option(List(b)), e) {
  // First check if any errors
  use results <- result.try(list.try_map(items, f))

  // Now check if all are Some
  case list.all(results, option.is_some) {
    True -> {
      // Extract all values (we know they're all Some)
      let values =
        list.filter_map(results, fn(opt) {
          case opt {
            Some(v) -> Ok(v)
            None -> Error(Nil)
          }
        })
      Ok(Some(values))
    }
    False -> Ok(None)
  }
}

/// Convert a list of ResultOptions into a ResultOption of a list.
///
/// - If any is `Error(e)`, returns `Error(e)`
/// - If all are `Ok` but any are `Ok(None)`, returns `Ok(None)`
/// - If all are `Ok(Some(value))`, returns `Ok(Some([values]))`
///
/// This is the special case of `traverse` where the function is identity.
///
/// ## Examples
///
/// ```gleam
/// sequence([Ok(Some(1)), Ok(Some(2)), Ok(Some(3))])
/// // -> Ok(Some([1, 2, 3]))
/// ```
///
/// ```gleam
/// sequence([Ok(Some(1)), Ok(None), Ok(Some(3))])
/// // -> Ok(None)
/// ```
///
/// ```gleam
/// sequence([Ok(Some(1)), Error("e"), Ok(Some(3))])
/// // -> Error("e")
/// ```
///
/// ```gleam
/// sequence([])
/// // -> Ok(Some([]))
/// ```
pub fn sequence(items: List(Result(Option(a), e))) -> Result(Option(List(a)), e) {
  traverse(items, fn(x) { x })
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
