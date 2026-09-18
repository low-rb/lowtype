# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Minor features that don't break backwards compatibility are released as patches.

## 1.5.0 [UNRELEASED]

### Added

- Export method signatures to RBS (via Lowkey)
- Activate `:shim` mode when debugging with `binding.irb/pry` to avoid `step`ing through shim methods
- Support dynamic expressions in methods and return types at runtime (like `type()` already does)
- Complex types validation
- `Boolean` type support
- Error mode config

## 1.4.0

### Added

- New disable mode: `:shim`. When `config.type_checking = false` and `config.disable_mode = :shim` then methods will be stripped of types on class load. Zero-overhead. Exporting to untyped files in a build step is also possible in future

### Changed

- Gem renamed from `low_type` to `lowtype`
- Binding and namespace improvements. No longer need to use the full namespace
- `ArgumentTypeError` now inherits from `ArgumentError`

## 1.3.1

### Fixed

- Fix Providers integration

## 1.3.0

- Support custom types in parameters ([#40](https://github.com/low-rb/lowtype/issues/40), [#39](https://github.com/low-rb/lowtype/pull/39), [#6](https://github.com/low-rb/lowkey/pull/6))

### Added

## 1.2.0

### Added

- Support inheritance type checking
- Support value expression inheritance type checking
- Support empty hash syntax (`Hash | {}`)

## 1.1.10

### Changed

- Deeper Lowkey integration
- Better architecture documentation

## 1.1.9

### Changed

- Lowkey dependency
- Move parser, file proxy and class proxy to lowkey

## 1.1.3

### Added

- Enable/disable type checking via `LowType.config.type_checking`

### Fixed

- [Add prefix to lambda locals to avoid name conflicts](https://github.com/low-rb/lowtype/pull/2)
- [Improved error message with unknown return type](https://github.com/low-rb/lowtype/pull/1)

## 1.1.2

### Added

- Repository pattern for loading `low_methods`

## 1.1.0

### Added

- Deep type checking
- Array subtype expressions `Array[String | nil]`
- Complex types support

## 1.0.8

### Added

- Add `output_mode` and `output_size` config options

### Changed

- Rename `severity_level` config to `error_mode`

## 1.0.3

### Changed

- Disable union type expressions via config

## 1.0.2

### Changed

- Handle multiple classes per file
- Support main object

## 1.0.1

### Changed

- Use refinements instead of subclasses

## 1.0.0

### Changed

- Use subclasses of `Array`/`Hash` for type expression enumerable syntax (`[]`) by default (scoped to the module, not global)

### Removed

- Remove `object.with_type=()` assignment method

## 0.9.0

### Added

- Typed accessor methods

## 0.8.0

### Added

- Sinatra route return type support
- Introduce `AllowedTypeError` for situations where a framework limits available types
- Add `HTML` and `JSON` types

### Changed

- Rename "type assignment" to "local types"

## 0.7.0

### Changed

- Raise `ArgumentTypeError`, `LocalTypeError` and `ReturnTypeError` error types
- Improve error messages

## 0.6.0

### Added

- `type` and `object.with_type=()` assignment methods
- Configuration object

## 0.5.0

### Added

- Use a type as a value with `value()`/`low_value()` helper methods

### Fixed

- Make return type specific error

## 0.4.0

### Added

- Support typed return values

## 0.3.0

### Added

- Support for `Array[T]` enumerable type
- Support for `Hash[T]` enumerable type

## 0.2.0

### Added

- Support for class methods
- Support for private methods

### Changed

- Reuse core Ruby error types
- Ignore untyped methods for better performance
- Use an abstract syntax tree for more accurate method metadata
- Use Ruby's Prism parser
