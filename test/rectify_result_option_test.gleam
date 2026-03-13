import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import rectify/result_option as ro

pub fn main() {
  gleeunit.main()
}

// ==========================================
// Constructors
// ==========================================

pub fn some_test() {
  ro.some(42)
  |> should.equal(Ok(Some(42)))
}

pub fn none_test() {
  ro.none()
  |> should.equal(Ok(None))
}

pub fn error_test() {
  ro.error("oops")
  |> should.equal(Error("oops"))
}

// ==========================================
// Mapping
// ==========================================

pub fn map_test() {
  ro.map(Ok(Some(5)), fn(n) { n * 2 })
  |> should.equal(Ok(Some(10)))

  ro.map(Ok(None), fn(n) { n * 2 })
  |> should.equal(Ok(None))

  ro.map(Error("e"), fn(n) { n * 2 })
  |> should.equal(Error("e"))
}

pub fn bind_test() {
  ro.bind(Ok(Some(5)), fn(n) { ro.some(n * 2) })
  |> should.equal(Ok(Some(10)))

  ro.bind(Ok(None), fn(n) { ro.some(n * 2) })
  |> should.equal(Ok(None))

  ro.bind(Error("e1"), fn(n) { ro.some(n * 2) })
  |> should.equal(Error("e1"))

  ro.bind(Ok(Some(5)), fn(_) { ro.error("e2") })
  |> should.equal(Error("e2"))
}

// ==========================================
// Conversions
// ==========================================

pub fn to_option_test() {
  ro.to_option(Ok(Some(42)))
  |> should.equal(Some(42))

  ro.to_option(Ok(None))
  |> should.equal(None)

  ro.to_option(Error("e"))
  |> should.equal(None)
}

pub fn of_option_test() {
  ro.of_option(Some(42))
  |> should.equal(Ok(Some(42)))

  ro.of_option(None)
  |> should.equal(Ok(None))
}

pub fn of_result_test() {
  ro.of_result(Ok(42))
  |> should.equal(Ok(Some(42)))

  ro.of_result(Error("e"))
  |> should.equal(Error("e"))
}

pub fn to_result_test() {
  ro.to_result(Ok(Some(42)), 0)
  |> should.equal(Ok(42))

  ro.to_result(Ok(None), 0)
  |> should.equal(Ok(0))

  ro.to_result(Error("e"), 0)
  |> should.equal(Error("e"))
}

// ==========================================
// Predicates
// ==========================================

pub fn is_some_test() {
  ro.is_some(Ok(Some(42)))
  |> should.be_true

  ro.is_some(Ok(None))
  |> should.be_false

  ro.is_some(Error("e"))
  |> should.be_false
}

pub fn is_none_test() {
  ro.is_none(Ok(None))
  |> should.be_true

  ro.is_none(Ok(Some(42)))
  |> should.be_false

  ro.is_none(Error("e"))
  |> should.be_false
}

// ==========================================
// Defaults
// ==========================================

pub fn unwrap_option_test() {
  ro.unwrap_option(Ok(Some(42)), 0)
  |> should.equal(Ok(42))

  ro.unwrap_option(Ok(None), 0)
  |> should.equal(Ok(0))

  ro.unwrap_option(Error("e"), 0)
  |> should.equal(Error("e"))
}

pub fn unwrap_option_lazy_test() {
  ro.unwrap_option_lazy(Ok(Some(42)), fn() { 0 })
  |> should.equal(Ok(42))

  ro.unwrap_option_lazy(Ok(None), fn() { 100 })
  |> should.equal(Ok(100))

  ro.unwrap_option_lazy(Error("e"), fn() { 0 })
  |> should.equal(Error("e"))
}

// ==========================================
// Zip
// ==========================================

pub fn zip_both_some_test() {
  ro.zip(Ok(Some(1)), Ok(Some(2)))
  |> should.equal(Ok(Some(#(1, 2))))
}

pub fn zip_first_none_test() {
  ro.zip(Ok(None), Ok(Some(2)))
  |> should.equal(Ok(None))
}

pub fn zip_second_none_test() {
  ro.zip(Ok(Some(1)), Ok(None))
  |> should.equal(Ok(None))
}

pub fn zip_first_error_test() {
  ro.zip(Error("e1"), Ok(Some(2)))
  |> should.equal(Error("e1"))
}

pub fn zip_second_error_test() {
  ro.zip(Ok(Some(1)), Error("e2"))
  |> should.equal(Error("e2"))
}

pub fn zip_both_error_test() {
  ro.zip(Error("e1"), Error("e2"))
  |> should.equal(Error("e1"))
}

pub fn zip3_all_some_test() {
  ro.zip3(Ok(Some(1)), Ok(Some(2)), Ok(Some(3)))
  |> should.equal(Ok(Some(#(1, 2, 3))))
}

pub fn zip3_one_none_test() {
  ro.zip3(Ok(Some(1)), Ok(None), Ok(Some(3)))
  |> should.equal(Ok(None))
}

pub fn zip3_one_error_test() {
  ro.zip3(Ok(Some(1)), Error("e"), Ok(Some(3)))
  |> should.equal(Error("e"))
}

// ==========================================
// Traverse
// ==========================================

pub fn traverse_all_some_test() {
  ro.traverse([1, 2, 3], fn(x) { Ok(Some(x * 2)) })
  |> should.equal(Ok(Some([2, 4, 6])))
}

pub fn traverse_one_none_test() {
  ro.traverse([1, 2, 3], fn(x) {
    case x == 2 {
      True -> Ok(None)
      False -> Ok(Some(x))
    }
  })
  |> should.equal(Ok(None))
}

pub fn traverse_one_error_test() {
  ro.traverse([1, 2, 3], fn(x) {
    case x == 2 {
      True -> Error("not found")
      False -> Ok(Some(x))
    }
  })
  |> should.equal(Error("not found"))
}

pub fn traverse_empty_list_test() {
  ro.traverse([], fn(x) { Ok(Some(x)) })
  |> should.equal(Ok(Some([])))
}

pub fn traverse_errors_before_nones_test() {
  // Should fail fast on error, not check for None
  ro.traverse([1, 2, 3], fn(x) {
    case x {
      1 -> Error("error")
      2 -> Ok(None)
      _ -> Ok(Some(x))
    }
  })
  |> should.equal(Error("error"))
}

// ==========================================
// Sequence
// ==========================================

pub fn sequence_all_some_test() {
  ro.sequence([Ok(Some(1)), Ok(Some(2)), Ok(Some(3))])
  |> should.equal(Ok(Some([1, 2, 3])))
}

pub fn sequence_one_none_test() {
  ro.sequence([Ok(Some(1)), Ok(None), Ok(Some(3))])
  |> should.equal(Ok(None))
}

pub fn sequence_one_error_test() {
  ro.sequence([Ok(Some(1)), Error("e"), Ok(Some(3))])
  |> should.equal(Error("e"))
}

pub fn sequence_empty_test() {
  ro.sequence([])
  |> should.equal(Ok(Some([])))
}

pub fn sequence_all_none_test() {
  ro.sequence([Ok(None), Ok(None), Ok(None)])
  |> should.equal(Ok(None))
}

pub fn sequence_all_error_test() {
  ro.sequence([Error("e1"), Error("e2"), Error("e3")])
  |> should.equal(Error("e1"))
}
