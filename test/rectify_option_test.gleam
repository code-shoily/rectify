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
