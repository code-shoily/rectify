import gleam/int
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import rectify/option as ropt

pub fn main() {
  gleeunit.main()
}

// ==========================================
// Defaults
// ==========================================

pub fn unwrap_lazy_test() {
  ropt.unwrap_lazy(Some(42), fn() { 0 })
  |> should.equal(42)

  ropt.unwrap_lazy(None, fn() { 100 })
  |> should.equal(100)
}

// ==========================================
// Combining
// ==========================================

pub fn map2_test() {
  ropt.map2(Some(2), Some(3), fn(a, b) { a + b })
  |> should.equal(Some(5))

  ropt.map2(Some(2), None, fn(a, b) { a + b })
  |> should.equal(None)

  ropt.map2(None, Some(3), fn(a, b) { a + b })
  |> should.equal(None)

  ropt.map2(None, None, fn(a, b) { a + b })
  |> should.equal(None)
}

pub fn map3_test() {
  ropt.map3(Some(1), Some(2), Some(3), fn(a, b, c) { a + b + c })
  |> should.equal(Some(6))

  ropt.map3(Some(1), None, Some(3), fn(a, b, c) { a + b + c })
  |> should.equal(None)
}

pub fn map4_test() {
  ropt.map4(Some(1), Some(2), Some(3), Some(4), fn(a, b, c, d) { a + b + c + d })
  |> should.equal(Some(10))

  ropt.map4(Some(1), Some(2), None, Some(4), fn(a, b, c, d) { a + b + c + d })
  |> should.equal(None)
}

pub fn map5_test() {
  ropt.map5(Some(1), Some(2), Some(3), Some(4), Some(5), fn(a, b, c, d, e) {
    a + b + c + d + e
  })
  |> should.equal(Some(15))

  ropt.map5(Some(1), None, Some(3), Some(4), Some(5), fn(a, b, c, d, e) {
    a + b + c + d + e
  })
  |> should.equal(None)
}

// ==========================================
// Collections
// ==========================================

pub fn choose_somes_test() {
  ropt.choose_somes([Some(1), None, Some(2), None, Some(3)])
  |> should.equal([1, 2, 3])

  ropt.choose_somes([None, None])
  |> should.equal([])

  ropt.choose_somes([])
  |> should.equal([])
}

pub fn first_some_test() {
  ropt.first_some([None, Some(2), Some(3)])
  |> should.equal(Some(2))

  ropt.first_some([Some(1), Some(2)])
  |> should.equal(Some(1))

  ropt.first_some([None, None])
  |> should.equal(None)

  ropt.first_some([])
  |> should.equal(None)
}

// ==========================================
// Conversions
// ==========================================

pub fn to_result_test() {
  ropt.to_result(Some(42), "not found")
  |> should.equal(Ok(42))

  ropt.to_result(None, "not found")
  |> should.equal(Error("not found"))
}

pub fn of_result_test() {
  ropt.of_result(Ok(42))
  |> should.equal(Some(42))

  ropt.of_result(Error("oops"))
  |> should.equal(None)
}

// ==========================================
// Zip
// ==========================================

pub fn zip_both_some_test() {
  ropt.zip(Some(1), Some(2))
  |> should.equal(Some(#(1, 2)))
}

pub fn zip_first_none_test() {
  ropt.zip(None, Some(2))
  |> should.equal(None)
}

pub fn zip_second_none_test() {
  ropt.zip(Some(1), None)
  |> should.equal(None)
}

pub fn zip_both_none_test() {
  ropt.zip(None, None)
  |> should.equal(None)
}

pub fn zip3_all_some_test() {
  ropt.zip3(Some(1), Some(2), Some(3))
  |> should.equal(Some(#(1, 2, 3)))
}

pub fn zip3_one_none_test() {
  ropt.zip3(Some(1), None, Some(3))
  |> should.equal(None)
}

// ==========================================
// Traverse
// ==========================================

pub fn traverse_all_some_test() {
  ropt.traverse([1, 2, 3], fn(x) { Some(x * 2) })
  |> should.equal(Some([2, 4, 6]))
}

pub fn traverse_one_none_test() {
  ropt.traverse([1, 2, 3], fn(x) {
    case x == 2 {
      True -> None
      False -> Some(x)
    }
  })
  |> should.equal(None)
}

pub fn traverse_empty_list_test() {
  ropt.traverse([], fn(x) { Some(x) })
  |> should.equal(Some([]))
}

pub fn traverse_with_int_parse_success_test() {
  ["1", "2", "3"]
  |> ropt.traverse(fn(s) { int.parse(s) |> ropt.of_result })
  |> should.equal(Some([1, 2, 3]))
}

pub fn traverse_with_int_parse_failure_test() {
  ["1", "bad", "3"]
  |> ropt.traverse(fn(s) { int.parse(s) |> ropt.of_result })
  |> should.equal(None)
}

// ==========================================
// Sequence
// ==========================================

pub fn sequence_all_some_test() {
  ropt.sequence([Some(1), Some(2), Some(3)])
  |> should.equal(Some([1, 2, 3]))
}

pub fn sequence_one_none_test() {
  ropt.sequence([Some(1), None, Some(3)])
  |> should.equal(None)
}

pub fn sequence_empty_test() {
  ropt.sequence([])
  |> should.equal(Some([]))
}

pub fn sequence_all_none_test() {
  ropt.sequence([None, None, None])
  |> should.equal(None)
}
