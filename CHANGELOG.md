# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **New conversion functions** in `rectify` module:
  - `of_bool/3` - Convert a boolean to Validation with explicit success/error values
    - `of_bool(True, value, error)` → `Valid(value)`
    - `of_bool(False, value, error)` → `Invalid([error])`
    - Useful for predicate-based validation: `string.contains(email, "@") |> of_bool(email, "Missing @")`

  - `of_bool_lazy/3` - Lazy version for expensive computations
    - Success and error values are computed only when needed
    - Useful when values require computation or I/O

- **Test coverage increased**: 127 tests total (up from 112)
  - 6 new unit tests for `of_bool` and `of_bool_lazy` in `test/rectify_test.gleam`
  - 9 new property-based tests verifying correctness, consistency, and equivalence
    - True/False produce expected Valid/Invalid results
    - Lazy and eager versions are equivalent
    - Negation properly inverts results
    - Integration with `is_valid`/`is_invalid` predicates

- **Property-Based Testing & Validation Law Verification**:
  - **Comprehensive law tests** for Validation type in `test/validation_laws_test.gleam`
    - 26 new property-based tests using the `qcheck` library
    - Total test suite now at 77 tests (up from 51)

  - **Functor laws** verified with property-based testing:
    - **Identity Law**: `map(v, fn(x) { x }) == v` - Mapping with identity doesn't change the value
    - **Composition Law**: `map(map(v, f), g) == map(v, fn(x) { g(f(x)) })` - Mapping twice equals mapping once with composed function

  - **Applicative functor laws** verified:
    - **Identity Law**: `apply(valid(fn(x) { x }), v) == v` - Applying identity function preserves value
    - **Homomorphism Law**: `apply(valid(f), valid(x)) == valid(f(x))` - Pure function application
    - **Interchange Law**: `apply(vf, valid(y)) == apply(valid(fn(f) { f(y) }), vf)` - Order independence for pure values
    - **Composition Law**: Function composition respects validation structure

  - **Monad laws** verified (for Valid cases):
    - **Left Identity**: `bind(valid(a), f) == f(a)` - Binding with pure value
    - **Right Identity**: `bind(v, valid) == v` - Binding with pure constructor
    - **Associativity**: `bind(bind(v, f), g) == bind(v, fn(x) { bind(f(x), g) })` - Nested binds can be reordered

  - **Error accumulation properties** verified:
    - All map2/map3/map4/map5 operations correctly accumulate errors from all Invalid validations
    - Valid values are properly ignored when errors exist
    - Mixed Valid/Invalid cases only preserve errors

  - **Conversion and utility properties** verified:
    - Round-trip conversions between Validation and Result
    - Flatten operation correctness for nested validations
    - Predicates (is_valid/is_invalid) are proper complements
    - unwrap and errors functions behave correctly
    - map_errors transforms all errors in a validation

  - **Edge case tests**:
    - Empty error lists
    - Large error accumulation (100+ errors)
    - Mixed valid/invalid combinations

  - **Documentation**: `VALIDATION_LAWS.md` - Comprehensive guide explaining all laws, why they matter, and examples of each

  - **Property-based testing infrastructure**:
    - Uses `qcheck` library for generating hundreds of random test cases per law
    - Custom generators for Validation, Int, String, and function types
    - Verifies laws hold across diverse input spaces, not just hand-picked examples

- **New Option utilities** in `rectify/option` module:
  - **`zip/2` and `zip3/3`** - Combine multiple Options into tuples
    - `zip(Some(1), Some(2))` returns `Some(#(1, 2))`
    - Syntactic sugar for `map2`/`map3` with tuple constructors
    - Useful for combining dictionary lookups or parsed values

  - **`traverse/2`** - Apply a function returning Option to a list, collecting results
    - `traverse(["1", "2"], int.parse)` returns `Some([1, 2])` if all parse successfully
    - Returns `None` if any application returns `None`
    - Common pattern: "Do X for all items, fail if any fail"
    - Examples: parse all strings, look up all keys, validate all items

  - **`sequence/1`** - Convert `List(Option(a))` to `Option(List(a))`
    - `sequence([Some(1), Some(2)])` returns `Some([1, 2])`
    - Returns `None` if any option in the list is `None`
    - Special case of `traverse` where function is identity

- **Test coverage increased**: 92 tests total (up from 77)
  - 15 new tests for zip, traverse, and sequence operations in `rectify/option`
  - Edge cases covered: empty lists, all None, mixed Some/None

- **New Result(Option) utilities** in `rectify/result_option` module:
  - **`zip/2` and `zip3/3`** - Combine multiple Result(Option)s into tuples
    - `zip(Ok(Some(1)), Ok(Some(2)))` returns `Ok(Some(#(1, 2)))`
    - Returns `Error` if any is `Error` (fail fast)
    - Returns `Ok(None)` if any is `Ok(None)`
    - Useful for combining database lookups or API calls

  - **`traverse/2`** - Apply a function returning Result(Option) to a list, collecting results
    - `traverse([1, 2, 3], find_user)` processes all IDs
    - Returns `Error` if any operation fails (fail fast on errors)
    - Returns `Ok(None)` if all succeed but any return `Ok(None)`
    - Returns `Ok(Some([values]))` if all succeed and return `Some`
    - Perfect for batch database lookups: "find all users, fail on DB error, None if any missing"

  - **`sequence/1`** - Convert `List(Result(Option(a), e))` to `Result(Option(List(a)), e)`
    - `sequence([Ok(Some(1)), Ok(Some(2))])` returns `Ok(Some([1, 2]))`
    - Returns `Error` if any item is `Error`
    - Returns `Ok(None)` if any item is `Ok(None)`
    - Special case of `traverse` where function is identity

- **Test coverage increased**: 112 tests total (up from 92)
  - 20 new tests for Result(Option) zip, traverse, and sequence operations
  - Edge cases covered: empty lists, errors before nones (fail fast), all error/none combinations

## [1.1.0] - 2026-03-12

### Breaking

- **rectify/option** - Removed `is_some/1` and `is_none/1`
  - These were duplicates of `gleam/option.is_some/1` and `gleam/option.is_none/1`, use those instead.

- **rectify/option** - Removed `default_to/2`
  - Use `gleam/option.unwrap/2` instead (identical functionality).

- **rectify/option** - Renamed `default_with/2` to `unwrap_lazy/2`
  - Better conveys the lazy evaluation semantics and mirrors `unwrap` naming.

- **rectify/result_option** - Removed `is_error/1`
  - Use `gleam/result.is_error/1` instead (identical functionality).

- **rectify/result_option** - Renamed `default_to/2` to `unwrap_option/2` and `default_with/2` to `unwrap_option_lazy/2`
  - Names better describe the operation: unwrapping the Option inside the Result.

- **rectify** (Validation) - Renamed `default_to/2` to `unwrap/2` and `default_with/2` to `unwrap_lazy/2`
  - Consistent naming with `rectify/option` module. `unwrap` extracts the value or returns a default.

### Changed

- Improved documentation and examples throughout all modules
  - Added rationale sections explaining design decisions (Miller's Law, cognitive ergonomics)
  - Enhanced `apply` documentation with practical currying examples
  - Added hierarchical composition examples for handling large field counts
  - Better cross-references between related functions

## [1.0.0] - 2026-03-10

### Added

- **Validation** type - Applicative functor for collecting multiple errors instead of fail-fast
  - `Validation(a, e)` with `Valid(a)` and `Invalid(List(e))` variants
  - Constructors: `valid/1`, `invalid/1`, `invalid_many/1`
  - Mapping: `map/2`, `map2/3`, `map3/4`, `map4/4`, `map5/5`
  - Composition: `apply/2`, `flatten/1`, `bind/2`
  - Predicates: `is_valid/1`, `is_invalid/1`
  - Conversions: `to_result/1`, `of_result/1`, `of_result_list/1`
  - Utilities: `default_to/2`, `default_with/2`, `errors/1`, `map_errors/2`

- **rectify/option** module - Additional utilities for Gleam's `Option` type
  - Predicates: `is_some/1`, `is_none/1`
  - Defaults: `default_to/2`, `default_with/2`
  - Combining: `map2/3`, `map3/4`
  - Collections: `choose_somes/1`, `first_some/1`
  - Conversions: `to_result/2`, `of_result/1`

- **rectify/result_option** module - Helpers for `Result(Option(a), e)` pattern
  - Constructors: `some/1`, `none/0`, `error/1`
  - Mapping: `map/2`, `bind/2`
  - Predicates: `is_some/1`, `is_none/1`, `is_error/1`
  - Conversions: `to_option/1`, `of_option/1`, `of_result/1`, `to_result/2`
  - Defaults: `default_to/2`, `default_with/2`

- 55 test cases covering all functionality

[Unreleased]: https://github.com/code-shoily/rectify/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/code-shoily/rectify/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/code-shoily/rectify/releases/tag/v1.0.0
