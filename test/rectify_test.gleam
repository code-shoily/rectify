import gleam/string
import gleeunit
import gleeunit/should
import rectify

pub fn main() {
  gleeunit.main()
}

// ==========================================
// Basic constructors
// ==========================================

pub fn valid_test() {
  rectify.valid(42)
  |> should.equal(rectify.Valid(42))
}

pub fn invalid_test() {
  rectify.invalid("failed")
  |> should.equal(rectify.Invalid(["failed"]))
}

pub fn invalid_many_test() {
  rectify.invalid_many(["error1", "error2"])
  |> should.equal(rectify.Invalid(["error1", "error2"]))
}

// ==========================================
// Map operations
// ==========================================

pub fn map_valid_test() {
  rectify.valid(5)
  |> rectify.map(fn(n) { n * 2 })
  |> should.equal(rectify.Valid(10))
}

pub fn map_invalid_test() {
  rectify.invalid("bad")
  |> rectify.map(fn(n) { n * 2 })
  |> should.equal(rectify.Invalid(["bad"]))
}

// ==========================================
// Map2 - error accumulation
// ==========================================

pub fn map2_both_valid_test() {
  rectify.map2(rectify.valid(2), rectify.valid(3), fn(a, b) { a + b })
  |> should.equal(rectify.Valid(5))
}

pub fn map2_first_invalid_test() {
  rectify.map2(rectify.invalid("first"), rectify.valid(3), fn(a, b) { a + b })
  |> should.equal(rectify.Invalid(["first"]))
}

pub fn map2_second_invalid_test() {
  rectify.map2(rectify.valid(2), rectify.invalid("second"), fn(a, b) { a + b })
  |> should.equal(rectify.Invalid(["second"]))
}

pub fn map2_both_invalid_test() {
  rectify.map2(rectify.invalid("first"), rectify.invalid("second"), fn(a, b) {
    a + b
  })
  |> should.equal(rectify.Invalid(["first", "second"]))
}

// ==========================================
// Form validation example
// ==========================================

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

pub fn form_validation_all_valid_test() {
  let result =
    rectify.map3(
      validate_name("Alice"),
      validate_email("alice@example.com"),
      validate_age(30),
      User,
    )

  result
  |> should.equal(rectify.valid(User("Alice", "alice@example.com", 30)))
}

pub fn form_validation_multiple_errors_test() {
  let result =
    rectify.map3(
      validate_name(""),
      validate_email("not-an-email"),
      validate_age(200),
      User,
    )

  result
  |> should.equal(
    rectify.Invalid([
      "Name is required",
      "Invalid email address",
      "Age must be between 0 and 150",
    ]),
  )
}

pub fn form_validation_partial_errors_test() {
  let result =
    rectify.map3(
      validate_name("Bob"),
      validate_email("invalid"),
      validate_age(25),
      User,
    )

  result
  |> should.equal(rectify.Invalid(["Invalid email address"]))
}

// ==========================================
// Conversions
// ==========================================

pub fn to_result_valid_test() {
  rectify.valid(42)
  |> rectify.to_result
  |> should.equal(Ok(42))
}

pub fn to_result_invalid_test() {
  rectify.invalid_many(["a", "b", "c"])
  |> rectify.to_result
  |> should.equal(Error(["a", "b", "c"]))
}

pub fn of_result_ok_test() {
  Ok(42)
  |> rectify.of_result
  |> should.equal(rectify.valid(42))
}

pub fn of_result_error_test() {
  Error("oops")
  |> rectify.of_result
  |> should.equal(rectify.invalid("oops"))
}

// ==========================================
// Utilities
// ==========================================

pub fn is_valid_test() {
  rectify.valid(1) |> rectify.is_valid |> should.be_true
  rectify.invalid("e") |> rectify.is_valid |> should.be_false
}

pub fn is_invalid_test() {
  rectify.valid(1) |> rectify.is_invalid |> should.be_false
  rectify.invalid("e") |> rectify.is_invalid |> should.be_true
}

pub fn default_to_test() {
  rectify.valid(42) |> rectify.default_to(0) |> should.equal(42)
  rectify.invalid("e") |> rectify.default_to(0) |> should.equal(0)
}

pub fn errors_test() {
  rectify.valid(1) |> rectify.errors |> should.equal([])
  rectify.invalid_many(["a", "b"]) |> rectify.errors |> should.equal(["a", "b"])
}

// ==========================================
// More Map operations
// ==========================================

pub fn map3_test() {
  rectify.map3(
    rectify.valid(1),
    rectify.valid(2),
    rectify.valid(3),
    fn(a, b, c) { a + b + c },
  )
  |> should.equal(rectify.Valid(6))

  rectify.map3(
    rectify.invalid("e1"),
    rectify.valid(2),
    rectify.invalid("e3"),
    fn(a, b, c) { a + b + c },
  )
  |> should.equal(rectify.Invalid(["e1", "e3"]))
}

pub fn map4_test() {
  rectify.map4(
    rectify.valid(1),
    rectify.valid(2),
    rectify.valid(3),
    rectify.valid(4),
    fn(a, b, c, d) { a + b + c + d },
  )
  |> should.equal(rectify.Valid(10))

  rectify.map4(
    rectify.invalid("e1"),
    rectify.invalid("e2"),
    rectify.valid(3),
    rectify.valid(4),
    fn(a, b, c, d) { a + b + c + d },
  )
  |> should.equal(rectify.Invalid(["e1", "e2"]))
}

pub fn map5_test() {
  rectify.map5(
    rectify.valid(1),
    rectify.valid(2),
    rectify.valid(3),
    rectify.valid(4),
    rectify.valid(5),
    fn(a, b, c, d, e) { a + b + c + d + e },
  )
  |> should.equal(rectify.Valid(15))

  rectify.map5(
    rectify.invalid("e1"),
    rectify.valid(2),
    rectify.valid(3),
    rectify.invalid("e4"),
    rectify.valid(5),
    fn(a, b, c, d, e) { a + b + c + d + e },
  )
  |> should.equal(rectify.Invalid(["e1", "e4"]))
}

// ==========================================
// Composition operations
// ==========================================

pub fn apply_test() {
  let f = rectify.valid(fn(x) { x * 2 })
  rectify.apply(f, rectify.valid(21))
  |> should.equal(rectify.Valid(42))

  let f_err = rectify.invalid("bad_func")
  rectify.apply(f_err, rectify.invalid("bad_val"))
  |> should.equal(rectify.Invalid(["bad_func", "bad_val"]))
}

pub fn flatten_test() {
  rectify.valid(rectify.valid(1))
  |> rectify.flatten
  |> should.equal(rectify.Valid(1))

  rectify.valid(rectify.invalid("e"))
  |> rectify.flatten
  |> should.equal(rectify.Invalid(["e"]))

  rectify.invalid("e")
  |> rectify.flatten
  |> should.equal(rectify.Invalid(["e"]))
}

pub fn bind_test() {
  rectify.valid(1)
  |> rectify.bind(fn(x) { rectify.valid(x * 2) })
  |> should.equal(rectify.Valid(2))

  rectify.valid(1)
  |> rectify.bind(fn(_) { rectify.invalid("e2") })
  |> should.equal(rectify.Invalid(["e2"]))

  rectify.invalid("e1")
  |> rectify.bind(fn(x) { rectify.valid(x * 2) })
  |> should.equal(rectify.Invalid(["e1"]))
}

// ==========================================
// More conversions
// ==========================================

pub fn of_result_list_test() {
  Ok(42)
  |> rectify.of_result_list
  |> should.equal(rectify.Valid(42))

  Error(["e1", "e2"])
  |> rectify.of_result_list
  |> should.equal(rectify.Invalid(["e1", "e2"]))
}

// ==========================================
// More utilities
// ==========================================

pub fn default_with_test() {
  rectify.valid(42)
  |> rectify.default_with(fn() { 0 })
  |> should.equal(42)

  rectify.invalid("e")
  |> rectify.default_with(fn() { 0 })
  |> should.equal(0)
}

pub fn map_errors_test() {
  rectify.valid(42)
  |> rectify.map_errors(fn(e) { "Err: " <> e })
  |> should.equal(rectify.Valid(42))

  rectify.invalid_many(["a", "b"])
  |> rectify.map_errors(fn(e) { "Err: " <> e })
  |> should.equal(rectify.Invalid(["Err: a", "Err: b"]))
}
