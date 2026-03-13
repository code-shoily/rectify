# Validation Laws (WIP)

This document explains the mathematical laws that the `Validation` type satisfies, and why they matter for building reliable, predictable software.

## Table of Contents

1. [Functor Laws](#functor-laws)
2. [Applicative Functor Laws](#applicative-functor-laws)
3. [Monad Laws (with caveats)](#monad-laws-with-caveats)
4. [Error Accumulation Properties](#error-accumulation-properties)
5. [Why Laws Matter](#why-laws-matter)

---

## Functor Laws

The `Validation` type is a **Functor**, meaning it has a `map` operation that satisfies two laws:

### Law 1: Identity

**Statement:** Mapping with the identity function doesn't change the value.

```gleam
map(v, fn(x) { x }) == v
```

**What it means:** If you map a function that does nothing, you get back what you started with.

**Example:**

```gleam
let v = valid(42)
map(v, fn(x) { x })  // -> valid(42)
```

### Law 2: Composition

**Statement:** Mapping twice is the same as mapping once with the composed function.

```gleam
map(map(v, f), g) == map(v, fn(x) { g(f(x)) })
```

**What it means:** You can optimize by combining functions before mapping, or map twice - the result is the same.

**Example:**

```gleam
let v = valid(5)
let double = fn(x) { x * 2 }
let add_one = fn(x) { x + 1 }

// These are equivalent:
map(map(v, double), add_one)           // -> valid(11)
map(v, fn(x) { add_one(double(x)) })   // -> valid(11)
```

---

## Applicative Functor Laws

The `Validation` type is an **Applicative Functor**, which means it supports error accumulation through `map2`, `map3`, etc.

### Law 1: Identity

**Statement:** Applying the identity function doesn't change the value.

```gleam
apply(valid(fn(x) { x }), v) == v
```

**What it means:** If you apply a function that does nothing, the value is unchanged.

**Example:**

```gleam
let v = valid(42)
apply(valid(fn(x) { x }), v)  // -> valid(42)
```

### Law 2: Homomorphism

**Statement:** Applying a pure function to a pure value is the same as making the result pure.

```gleam
apply(valid(f), valid(x)) == valid(f(x))
```

**What it means:** If both the function and value are valid, the result is just the function applied normally, wrapped in Valid.

**Example:**

```gleam
let f = fn(x) { x * 2 }
apply(valid(f), valid(21))  // -> valid(42)
valid(f(21))                // -> valid(42)  (same!)
```

### Law 3: Interchange

**Statement:** The order of applying doesn't matter for pure values.

```gleam
apply(vf, valid(y)) == apply(valid(fn(f) { f(y) }), vf)
```

**What it means:** You can swap which side gets the function wrapper.

### Law 4: Composition

**Statement:** Composing functions inside validations works correctly.

```gleam
apply(apply(apply(valid(compose), u), v), w) == apply(u, apply(v, w))
where compose = fn(f) { fn(g) { fn(x) { f(g(x)) } } }
```

**What it means:** Function composition respects the validation structure.

---

## The Monad Dilemma (Why `bind` is special)

The `Validation` type has a `bind` operation that perfectly satisfies the three standard Monad laws (Left Identity, Right Identity, and Associativity).

However, in functional programming, types that are both Applicatives and Monads must satisfy the **Consistency Law**: `apply` and `bind` must result in the exact same behavior.

For `Validation`, they deliberately disagree:

```gleam
let v1 = invalid(["e1"])
let v2 = invalid(["e2"])

// The Applicative way (map2/apply) evaluates in parallel and accumulates:
map2(v1, v2, fn(a, b) { a + b })  // -> Invalid(["e1", "e2"])

// The Monad way (bind) evaluates sequentially and short-circuits:
bind(v1, fn(_) { v2 })            // -> Invalid(["e1"])
```

#### Law 1: Left Identity

```gleam
bind(valid(a), f) == f(a)
```

**Example:**

```gleam
bind(valid(5), fn(x) { valid(x * 2) })  // -> valid(10)
fn(x) { valid(x * 2) }(5)               // -> valid(10)  (same!)
```

#### Law 2: Right Identity

```gleam
bind(v, valid) == v
```

**Example:**

```gleam
bind(valid(42), valid)  // -> valid(42)
```

#### Law 3: Associativity

```gleam
bind(bind(v, f), g) == bind(v, fn(x) { bind(f(x), g) })
```

**Example:**

```gleam
let v = valid(5)
let double = fn(x) { valid(x * 2) }
let add_one = fn(x) { valid(x + 1) }

bind(bind(v, double), add_one)            // -> valid(11)
bind(v, fn(x) { bind(double(x), add_one) }) // -> valid(11)
```

---

## Error Accumulation Properties

These properties are unique to `Validation` and distinguish it from `Result`.

### Property 1: All Errors Accumulate

When using `map2`, `map3`, `map4`, or `map5`, **all errors are collected**.

```gleam
map3(
  invalid("e1"),
  invalid("e2"),
  invalid("e3"),
  fn(a, b, c) { a + b + c }
)
// -> Invalid(["e1", "e2", "e3"])
```

This is the **key feature** that makes `Validation` useful for form validation.

### Property 2: Valid Values Short-Circuit

If all values are `Valid`, the function is applied:

```gleam
map3(
  valid(1),
  valid(2),
  valid(3),
  fn(a, b, c) { a + b + c }
)
// -> Valid(6)
```

### Property 3: Mixed Valid/Invalid Only Keeps Errors

```gleam
map4(
  valid(1),
  invalid("e1"),
  valid(2),
  invalid("e2"),
  fn(a, b, c, d) { a + b + c + d }
)
// -> Invalid(["e1", "e2"])
```

Only the errors are accumulated; valid values are ignored when any error exists.

---

## Why Laws Matter

### 1. Predictability

Laws guarantee that your code behaves the same way regardless of how you structure it:

```gleam
// These are guaranteed to be equivalent:
map(map(v, f), g)
map(v, fn(x) { g(f(x)) })
```

You can refactor without changing behavior.

### 2. Composability

Laws ensure that small pieces combine correctly into larger pieces:

```gleam
// Compose validations without worrying about edge cases
let validate_user = fn(data) {
  map3(
    validate_name(data.name),
    validate_email(data.email),
    validate_age(data.age),
    User
  )
}

// Composes with other validations:
map2(
  validate_user(user_data),
  validate_address(address_data),
  UserWithAddress
)
```

### 3. Reasoning

Laws let you reason algebraically about your code:

```gleam
// If you see this:
let v = map(map(data, parse), validate)

// You know it's the same as:
let v = map(data, fn(x) { validate(parse(x)) })

// So you can optimize without testing!
```

### 4. Tooling & Optimization

When a type follows laws, compilers and tools can:

- Perform safe optimizations (fusion, deforestation)
- Generate correct code transformations
- Provide better error messages
- Enable property-based testing

---

## Verification

All these laws are verified in `test/validation_laws_test.gleam` using **property-based testing** with the `qcheck` library. The tests run hundreds of random inputs to ensure the laws hold in all cases.

**Test Coverage:**

- ✅ 2 Functor laws
- ✅ 4 Applicative functor laws
- ✅ 3 Monad laws (bind satisfies these, but see caveat above)
- ✅ 6 Error accumulation properties
- ✅ 6 Conversion and utility properties
- ✅ 9 of_bool properties (correctness, consistency, equivalence)
- ✅ 5 Edge case tests

**Total: 35 property-based law tests** + 92 unit tests = **127 tests**

---

## Further Reading

- [Functors, Applicatives, and Monads in Pictures](https://adit.io/posts/2013-04-17-functors,_applicatives,_and_monads_in_pictures.html)
- [Validation Applicative Functor (Haskell)](https://hackage.haskell.org/package/validation)
- [FsToolkit.ErrorHandling](https://github.com/demystifyfp/FsToolkit.ErrorHandling) (F# inspiration)
- [Railway Oriented Programming](https://fsharpforfunandprofit.com/rop/)
