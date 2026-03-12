# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Breaking

- **rectify/option** - Removed `is_some/1` and `is_none/1`
  - These were duplicates of `gleam/option.is_some/1` and `gleam/option.is_none/1`, use those instead.

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

[Unreleased]: https://github.com/code-shoily/rectify/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/code-shoily/rectify/releases/tag/v1.0.0
