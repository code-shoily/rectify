import gleam/int
import gleam/list
import gleeunit
import gleeunit/should
import qcheck
import rectify

pub fn main() {
  gleeunit.main()
}

// ==========================================
// Generators
// ==========================================

fn validation_generator() -> qcheck.Generator(rectify.Validation(Int, String)) {
  qcheck.map(qcheck.uniform_int(), fn(n) {
    case n % 5 {
      0 -> rectify.valid(42)
      1 -> rectify.valid(0)
      2 -> rectify.valid(-10)
      3 -> rectify.invalid("error")
      _ -> rectify.invalid_many(["error1", "error2"])
    }
  })
}

fn int_generator() -> qcheck.Generator(Int) {
  qcheck.uniform_int()
}

fn string_generator() -> qcheck.Generator(String) {
  qcheck.non_empty_string()
}

fn function_generator() -> qcheck.Generator(fn(Int) -> Int) {
  qcheck.map(qcheck.uniform_int(), fn(n) {
    case n % 4 {
      0 -> fn(x) { x * 2 }
      1 -> fn(x) { x + 1 }
      2 -> fn(x) { x - 5 }
      _ -> fn(_) { 0 }
    }
  })
}

// ==========================================
// Functor Laws
// ==========================================

/// Functor Law 1: Identity
/// map(v, fn(x) { x }) == v
pub fn functor_law_identity_test() {
  qcheck.given(validation_generator(), fn(v) {
    let id = fn(x) { x }
    let result = rectify.map(v, id)
    result |> should.equal(v)
  })
}

/// Functor Law 2: Composition
/// map(map(v, f), g) == map(v, fn(x) { g(f(x)) })
pub fn functor_law_composition_test() {
  qcheck.given(validation_generator(), fn(v) {
    let f = fn(x) { x * 2 }
    let g = fn(x) { x + 1 }
    let composed = fn(x) { g(f(x)) }

    let left = rectify.map(v, f) |> rectify.map(g)
    let right = rectify.map(v, composed)

    left |> should.equal(right)
  })
}

// ==========================================
// Applicative Functor Laws
// ==========================================

/// Applicative Law 1: Identity
/// apply(valid(fn(x) { x }), v) == v
pub fn applicative_law_identity_test() {
  qcheck.given(validation_generator(), fn(v) {
    let id = fn(x) { x }
    let result = rectify.apply(rectify.valid(id), v)
    result |> should.equal(v)
  })
}

/// Applicative Law 2: Homomorphism
/// apply(valid(f), valid(x)) == valid(f(x))
pub fn applicative_law_homomorphism_test() {
  qcheck.given(int_generator(), fn(x) {
    let f = fn(n) { n * 2 }
    let left = rectify.apply(rectify.valid(f), rectify.valid(x))
    let right = rectify.valid(f(x))
    left |> should.equal(right)
  })
}

/// Applicative Law 3: Interchange
/// apply(vf, valid(y)) == apply(valid(fn(f) { f(y) }), vf)
pub fn applicative_law_interchange_test() {
  qcheck.given(function_generator(), fn(f) {
    let y = 10
    let vf = rectify.valid(f)
    let left = rectify.apply(vf, rectify.valid(y))
    let right = rectify.apply(rectify.valid(fn(g) { g(y) }), vf)
    left |> should.equal(right)
  })
}

/// Applicative Law 4: Composition
/// apply(apply(apply(valid(compose), u), v), w) == apply(u, apply(v, w))
/// where compose = fn(f) { fn(g) { fn(x) { f(g(x)) } } }
pub fn applicative_law_composition_test() {
  let u = rectify.valid(fn(x) { x * 2 })
  let v = rectify.valid(fn(x) { x + 1 })
  let w = rectify.valid(5)

  let compose = fn(f) { fn(g) { fn(x) { f(g(x)) } } }

  // Left side: apply(apply(apply(valid(compose), u), v), w)
  let left =
    rectify.apply(rectify.apply(rectify.apply(rectify.valid(compose), u), v), w)

  // Right side: apply(u, apply(v, w))
  let right = rectify.apply(u, rectify.apply(v, w))

  left |> should.equal(right)
}

// ==========================================
// Error Accumulation Properties
// ==========================================

/// Property: map2 accumulates errors from both sides
pub fn map2_error_accumulation_test() {
  qcheck.given(
    qcheck.tuple2(string_generator(), string_generator()),
    fn(errors) {
      let #(e1, e2) = errors
      let result =
        rectify.map2(rectify.invalid(e1), rectify.invalid(e2), fn(a, b) {
          a + b
        })

      case result {
        rectify.Invalid(errs) -> {
          list.contains(errs, e1) |> should.be_true
          list.contains(errs, e2) |> should.be_true
        }
        _ -> panic as "Expected Invalid"
      }
    },
  )
}

/// Property: map3 accumulates all errors
pub fn map3_error_accumulation_test() {
  let result =
    rectify.map3(
      rectify.invalid("e1"),
      rectify.invalid("e2"),
      rectify.invalid("e3"),
      fn(a, b, c) { a + b + c },
    )

  result |> should.equal(rectify.Invalid(["e1", "e2", "e3"]))
}

/// Property: map4 accumulates all errors
pub fn map4_error_accumulation_test() {
  let result =
    rectify.map4(
      rectify.invalid("e1"),
      rectify.invalid("e2"),
      rectify.invalid("e3"),
      rectify.invalid("e4"),
      fn(a, b, c, d) { a + b + c + d },
    )

  result |> should.equal(rectify.Invalid(["e1", "e2", "e3", "e4"]))
}

/// Property: map5 accumulates all errors
pub fn map5_error_accumulation_test() {
  let result =
    rectify.map5(
      rectify.invalid("e1"),
      rectify.invalid("e2"),
      rectify.invalid("e3"),
      rectify.invalid("e4"),
      rectify.invalid("e5"),
      fn(a, b, c, d, e) { a + b + c + d + e },
    )

  result |> should.equal(rectify.Invalid(["e1", "e2", "e3", "e4", "e5"]))
}

/// Property: Valid values ignore errors in accumulation
pub fn valid_values_succeed_test() {
  qcheck.given(
    qcheck.tuple3(int_generator(), int_generator(), int_generator()),
    fn(values) {
      let #(a, b, c) = values
      let result =
        rectify.map3(
          rectify.valid(a),
          rectify.valid(b),
          rectify.valid(c),
          fn(x, y, z) { x + y + z },
        )

      result |> should.equal(rectify.valid(a + b + c))
    },
  )
}

/// Property: Mixed valid and invalid accumulates only errors
pub fn mixed_valid_invalid_test() {
  let result =
    rectify.map4(
      rectify.valid(1),
      rectify.invalid("e1"),
      rectify.valid(2),
      rectify.invalid("e2"),
      fn(a, b, c, d) { a + b + c + d },
    )

  result |> should.equal(rectify.Invalid(["e1", "e2"]))
}

// ==========================================
// Monad Laws (Bind - Note: NOT a lawful monad for error accumulation)
// ==========================================

/// Left Identity: bind(valid(a), f) == f(a)
pub fn monad_law_left_identity_test() {
  qcheck.given(int_generator(), fn(a) {
    let f = fn(x) { rectify.valid(x * 2) }
    let left = rectify.bind(rectify.valid(a), f)
    let right = f(a)
    left |> should.equal(right)
  })
}

/// Right Identity: bind(v, valid) == v
pub fn monad_law_right_identity_test() {
  qcheck.given(validation_generator(), fn(v) {
    let result = rectify.bind(v, rectify.valid)
    result |> should.equal(v)
  })
}

/// Associativity: bind(bind(v, f), g) == bind(v, fn(x) { bind(f(x), g) })
pub fn monad_law_associativity_test() {
  qcheck.given(int_generator(), fn(a) {
    let v = rectify.valid(a)
    let f = fn(x) { rectify.valid(x * 2) }
    let g = fn(x) { rectify.valid(x + 1) }

    let left = rectify.bind(rectify.bind(v, f), g)
    let right = rectify.bind(v, fn(x) { rectify.bind(f(x), g) })

    left |> should.equal(right)
  })
}

// ==========================================
// Conversion Laws
// ==========================================

/// Property: to_result and of_result form a round-trip for Valid
pub fn conversion_roundtrip_valid_test() {
  qcheck.given(int_generator(), fn(a) {
    let v = rectify.valid(a)
    let result = v |> rectify.to_result |> rectify.of_result_list
    result |> should.equal(v)
  })
}

/// Property: to_result and of_result form a round-trip for Invalid
pub fn conversion_roundtrip_invalid_test() {
  qcheck.given(string_generator(), fn(e) {
    let v = rectify.invalid(e)
    let result = v |> rectify.to_result |> rectify.of_result_list
    result |> should.equal(v)
  })
}

// ==========================================
// Flatten Laws
// ==========================================

/// Property: flatten(valid(valid(a))) == valid(a)
pub fn flatten_valid_valid_test() {
  qcheck.given(int_generator(), fn(a) {
    let v = rectify.valid(rectify.valid(a))
    rectify.flatten(v) |> should.equal(rectify.valid(a))
  })
}

/// Property: flatten(valid(invalid(e))) == invalid(e)
pub fn flatten_valid_invalid_test() {
  qcheck.given(string_generator(), fn(e) {
    let v = rectify.valid(rectify.invalid(e))
    rectify.flatten(v) |> should.equal(rectify.invalid(e))
  })
}

/// Property: flatten(invalid(e)) == invalid(e)
pub fn flatten_invalid_test() {
  qcheck.given(string_generator(), fn(e) {
    let v = rectify.invalid(e)
    rectify.flatten(v) |> should.equal(rectify.invalid(e))
  })
}

// ==========================================
// Utility Properties
// ==========================================

/// Property: is_valid and is_invalid are complements
pub fn is_valid_is_invalid_complement_test() {
  qcheck.given(validation_generator(), fn(v) {
    case rectify.is_valid(v), rectify.is_invalid(v) {
      True, False | False, True -> Nil
      _, _ -> panic as "is_valid and is_invalid should be complements"
    }
  })
}

/// Property: unwrap returns value for Valid, default for Invalid
pub fn unwrap_property_test() {
  let default = 0

  qcheck.given(validation_generator(), fn(v) {
    let result = rectify.unwrap(v, default)
    case v {
      rectify.Valid(a) -> result |> should.equal(a)
      rectify.Invalid(_) -> result |> should.equal(default)
    }
  })
}

/// Property: errors returns empty list for Valid, error list for Invalid
pub fn errors_property_test() {
  qcheck.given(validation_generator(), fn(v) {
    let errs = rectify.errors(v)
    case v {
      rectify.Valid(_) -> errs |> should.equal([])
      rectify.Invalid(es) -> errs |> should.equal(es)
    }
  })
}

/// Property: map_errors transforms all errors
pub fn map_errors_property_test() {
  let transform = fn(e) { "Error: " <> e }

  let v1 = rectify.invalid("e1")
  let result1 = rectify.map_errors(v1, transform)
  result1 |> should.equal(rectify.invalid("Error: e1"))

  let v2 = rectify.invalid_many(["e1", "e2"])
  let result2 = rectify.map_errors(v2, transform)
  result2 |> should.equal(rectify.invalid_many(["Error: e1", "Error: e2"]))
}

// ==========================================
// Example-Based Edge Cases
// ==========================================

/// Edge case: Empty error list should not happen but if it does, it's still Invalid
pub fn empty_error_list_edge_case_test() {
  let v = rectify.invalid_many([])
  rectify.is_invalid(v) |> should.be_true
  rectify.errors(v) |> should.equal([])
}

/// Edge case: Large error accumulation
pub fn large_error_accumulation_test() {
  // Generate 100 errors manually using list.repeat and list.index_map
  let validations =
    list.repeat(Nil, 100)
    |> list.index_map(fn(_, i) {
      rectify.invalid("error" <> int.to_string(i + 1))
    })

  // Create a chain of map2 operations
  let result =
    list.fold(validations, rectify.valid(0), fn(acc, v) {
      rectify.map2(acc, v, fn(a, b) { a + b })
    })

  case result {
    rectify.Invalid(errs) -> {
      list.length(errs) |> should.equal(100)
    }
    _ -> panic as "Expected Invalid"
  }
}

// ==========================================
// of_bool Properties
// ==========================================

/// Property: of_bool(True, a, e) always returns Valid(a)
pub fn of_bool_true_always_valid_test() {
  qcheck.given(qcheck.tuple2(int_generator(), string_generator()), fn(inputs) {
    let #(a, e) = inputs
    rectify.of_bool(True, a, e) |> should.equal(rectify.valid(a))
  })
}

/// Property: of_bool(False, a, e) always returns Invalid([e])
pub fn of_bool_false_always_invalid_test() {
  qcheck.given(qcheck.tuple2(int_generator(), string_generator()), fn(inputs) {
    let #(a, e) = inputs
    rectify.of_bool(False, a, e) |> should.equal(rectify.invalid(e))
  })
}

/// Property: of_bool is consistent with manual construction
pub fn of_bool_consistency_test() {
  qcheck.given(qcheck.tuple2(int_generator(), string_generator()), fn(inputs) {
    let #(a, e) = inputs

    // True case should equal valid()
    rectify.of_bool(True, a, e) |> should.equal(rectify.valid(a))

    // False case should equal invalid()
    rectify.of_bool(False, a, e) |> should.equal(rectify.invalid(e))
  })
}

/// Property: Negating condition swaps Valid/Invalid
pub fn of_bool_negation_inverts_result_test() {
  qcheck.given(qcheck.tuple2(int_generator(), string_generator()), fn(inputs) {
    let #(a, e) = inputs
    let condition = True

    let result_true = rectify.of_bool(condition, a, e)
    let result_false = rectify.of_bool(!condition, a, e)

    case result_true, result_false {
      rectify.Valid(_), rectify.Invalid(_) -> Nil
      rectify.Invalid(_), rectify.Valid(_) -> Nil
      _, _ -> panic as "Negation should swap Valid/Invalid"
    }
  })
}

/// Property: of_bool result can be checked with is_valid
pub fn of_bool_is_valid_correspondence_test() {
  qcheck.given(
    qcheck.tuple3(qcheck.bool(), int_generator(), string_generator()),
    fn(inputs) {
      let #(condition, a, e) = inputs
      let result = rectify.of_bool(condition, a, e)

      case condition {
        True -> rectify.is_valid(result) |> should.be_true
        False -> rectify.is_invalid(result) |> should.be_true
      }
    },
  )
}

// ==========================================
// of_bool_lazy Properties
// ==========================================

/// Property: of_bool_lazy(True, on_true, on_false) always returns Valid
pub fn of_bool_lazy_true_always_valid_test() {
  qcheck.given(qcheck.tuple2(int_generator(), string_generator()), fn(inputs) {
    let #(a, e) = inputs
    rectify.of_bool_lazy(True, fn() { a }, fn() { e })
    |> should.equal(rectify.valid(a))
  })
}

/// Property: of_bool_lazy(False, on_true, on_false) always returns Invalid
pub fn of_bool_lazy_false_always_invalid_test() {
  qcheck.given(qcheck.tuple2(int_generator(), string_generator()), fn(inputs) {
    let #(a, e) = inputs
    rectify.of_bool_lazy(False, fn() { a }, fn() { e })
    |> should.equal(rectify.invalid(e))
  })
}

/// Property: of_bool_lazy is equivalent to of_bool for eager values
pub fn of_bool_lazy_equivalence_test() {
  qcheck.given(
    qcheck.tuple3(qcheck.bool(), int_generator(), string_generator()),
    fn(inputs) {
      let #(condition, a, e) = inputs

      let eager_result = rectify.of_bool(condition, a, e)
      let lazy_result = rectify.of_bool_lazy(condition, fn() { a }, fn() { e })

      lazy_result |> should.equal(eager_result)
    },
  )
}

/// Property: of_bool_lazy negation inverts result
pub fn of_bool_lazy_negation_inverts_result_test() {
  qcheck.given(qcheck.tuple2(int_generator(), string_generator()), fn(inputs) {
    let #(a, e) = inputs
    let condition = True

    let result_true = rectify.of_bool_lazy(condition, fn() { a }, fn() { e })
    let result_false = rectify.of_bool_lazy(!condition, fn() { a }, fn() { e })

    case result_true, result_false {
      rectify.Valid(_), rectify.Invalid(_) -> Nil
      rectify.Invalid(_), rectify.Valid(_) -> Nil
      _, _ -> panic as "Negation should swap Valid/Invalid"
    }
  })
}
