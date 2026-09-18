# Development

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add lowtype
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install lowtype
```

To install this gem onto your local machine, run `bundle exec rake install`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Testing

```bash
rake spec:shim  # TYPE_CHECKING=true DISABLE_MODE=shim bundle exec rspec
rake spec:strip # TYPE_CHECKING=false DISABLE_MODE=strip bundle exec rspec
rake spec:all   # Runs all configurations
```

Plain `rake spec` / `bundle exec rspec` defaults to `type_checking: true`.

## Releasing

To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Execution paths

LowType has two paths depending when `config.type_checking = false`:

### config.disable_mode = :shim (default)

Methods are redefined via a prepended Module using `define_method`. On each call, argument types are validated against the evaluated expressions, then `super` dispatches to the original method.

### config.disable_mode = :strip

Methods are rewritten directly on the class. `MethodProxy#rewrite_signature` strips type annotations from the signature line in the shared `lines` array, then `class_eval(method_proxy.export)` redefines the method with a plain Ruby signature. No prepended module, no `super`, no runtime overhead beyond the method itself.

The rewritten method has default values baked in from the expressions, so keyword and positional defaults work as normal Ruby defaults would.

Private visibility is preserved using `klass.send(:private, method_name)` after the `class_eval`.

## Benchmarks

Run the benchmark with:

```bash
bundle exec ruby benchmarks/strip_benchmark.rb
```

Results on Ruby 3.3.0 (keyword args, which is the primary use case):

| Approach                   | i/s       |
| -------------------------- | --------- |
| Plain Ruby                 | 6,200,000 |
| strip_types                | 5,130,000 |
| shimmed_methods shim       | 1,100,000 |

The Strip method is 4.67x faster than the old shim and within 1.21x of plain Ruby.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/low-rb/lowtype.
