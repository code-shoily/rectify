//// Option utilities for Rectify
////
//// Additional helpers for Gleam's `Option` type that complement
//// the standard library.

import gleam/list
import gleam/option.{type Option, None, Some}

// ==========================================
// Predicates
// ==========================================

/// Check if an option is Some.
///
/// ## Examples
///
/// ```gleam
/// is_some(Some(42))
/// // -> True
/// ```
///
/// ```gleam
/// is_some(None)
/// // -> False
/// ```
pub fn is_some(opt: Option(a)) -> Bool {
  case opt {
    Some(_) -> True
    None -> False
  }
}

/// Check if an option is None.
///
/// ## Examples
///
/// ```gleam
/// is_none(None)
/// // -> True
/// ```
///
/// ```gleam
/// is_none(Some(42))
/// // -> False
/// ```
pub fn is_none(opt: Option(a)) -> Bool {
  !is_some(opt)
}

// ==========================================
// Defaults
// ==========================================

/// Get the value from an option or return a default.
///
/// ## Examples
///
/// ```gleam
/// default_to(Some(42), 0)
/// // -> 42
/// ```
///
/// ```gleam
/// default_to(None, 0)
/// // -> 0
/// ```
pub fn default_to(opt: Option(a), default: a) -> a {
  case opt {
    Some(a) -> a
    None -> default
  }
}

/// Get the value from an option or compute a default.
///
/// ## Examples
///
/// ```gleam
/// default_with(Some(42), fn() { 0 })
/// // -> 42
/// ```
///
/// ```gleam
/// default_with(None, fn() { expensive_computation() })
/// // -> result of expensive_computation()
/// ```
pub fn default_with(opt: Option(a), f: fn() -> a) -> a {
  case opt {
    Some(a) -> a
    None -> f()
  }
}

// ==========================================
// Combining
// ==========================================

/// Map over two options, returning None if either is None.
///
/// ## Examples
///
/// ```gleam
/// map2(Some(2), Some(3), fn(a, b) { a + b })
/// // -> Some(5)
/// ```
///
/// ```gleam
/// map2(Some(2), None, fn(a, b) { a + b })
/// // -> None
/// ```
pub fn map2(opt1: Option(a), opt2: Option(b), f: fn(a, b) -> c) -> Option(c) {
  case opt1, opt2 {
    Some(a), Some(b) -> Some(f(a, b))
    _, _ -> None
  }
}

/// Map over three options.
///
/// ## Examples
///
/// ```gleam
/// map3(Some(1), Some(2), Some(3), fn(a, b, c) { a + b + c })
/// // -> Some(6)
/// ```
///
/// ```gleam
/// map3(Some(1), None, Some(3), fn(a, b, c) { a + b + c })
/// // -> None
/// ```
pub fn map3(
  opt1: Option(a),
  opt2: Option(b),
  opt3: Option(c),
  f: fn(a, b, c) -> d,
) -> Option(d) {
  case opt1, opt2, opt3 {
    Some(a), Some(b), Some(c) -> Some(f(a, b, c))
    _, _, _ -> None
  }
}

/// Map over four options.
///
/// ## Examples
///
/// ```gleam
/// map4(Some(1), Some(2), Some(3), Some(4), fn(a, b, c, d) { a + b + c + d })
/// // -> Some(10)
/// ```
///
/// ```gleam
/// map4(Some(1), Some(2), None, Some(4), fn(a, b, c, d) { a + b + c + d })
/// // -> None
/// ```
pub fn map4(
  opt1: Option(a),
  opt2: Option(b),
  opt3: Option(c),
  opt4: Option(d),
  f: fn(a, b, c, d) -> g,
) -> Option(g) {
  case opt1, opt2, opt3, opt4 {
    Some(a), Some(b), Some(c), Some(d) -> Some(f(a, b, c, d))
    _, _, _, _ -> None
  }
}

/// Map over five options.
///
/// ## Examples
///
/// ```gleam
/// map5(Some(1), Some(2), Some(3), Some(4), Some(5), fn(a, b, c, d, e) { a + b + c + d + e })
/// // -> Some(15)
/// ```
///
/// ```gleam
/// map5(Some(1), None, Some(3), Some(4), Some(5), fn(a, b, c, d, e) { a + b + c + d + e })
/// // -> None
/// ```
pub fn map5(
  opt1: Option(a),
  opt2: Option(b),
  opt3: Option(c),
  opt4: Option(d),
  opt5: Option(e),
  f: fn(a, b, c, d, e) -> h,
) -> Option(h) {
  case opt1, opt2, opt3, opt4, opt5 {
    Some(a), Some(b), Some(c), Some(d), Some(e) -> Some(f(a, b, c, d, e))
    _, _, _, _, _ -> None
  }
}

// ==========================================
// Collections
// ==========================================

/// Extract all Some values from a list of options.
///
/// ## Examples
///
/// ```gleam
/// choose_somes([Some(1), None, Some(2), None, Some(3)])
/// // -> [1, 2, 3]
/// ```
pub fn choose_somes(opts: List(Option(a))) -> List(a) {
  list.filter_map(opts, fn(opt) {
    case opt {
      Some(a) -> Ok(a)
      None -> Error(Nil)
    }
  })
}

/// Returns the first Some value, or None if all are None.
///
/// ## Examples
///
/// ```gleam
/// first_some([None, Some(2), Some(3)])
/// // -> Some(2)
/// ```
///
/// ```gleam
/// first_some([None, None])
/// // -> None
/// ```
pub fn first_some(opts: List(Option(a))) -> Option(a) {
  case opts {
    [] -> None
    [Some(a), ..] -> Some(a)
    [None, ..rest] -> first_some(rest)
  }
}

// ==========================================
// Conversions
// ==========================================

/// Convert an Option to a Result with a custom error.
///
/// ## Examples
///
/// ```gleam
/// to_result(Some(42), "not found")
/// // -> Ok(42)
/// ```
///
/// ```gleam
/// to_result(None, "not found")
/// // -> Error("not found")
/// ```
pub fn to_result(opt: Option(a), error: e) -> Result(a, e) {
  case opt {
    Some(a) -> Ok(a)
    None -> Error(error)
  }
}

/// Convert a Result to an Option, discarding the error.
///
/// ## Examples
///
/// ```gleam
/// of_result(Ok(42))
/// // -> Some(42)
/// ```
///
/// ```gleam
/// of_result(Error("oops"))
/// // -> None
/// ```
pub fn of_result(result: Result(a, e)) -> Option(a) {
  case result {
    Ok(a) -> Some(a)
    Error(_) -> None
  }
}
