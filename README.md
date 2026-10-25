# Unisender

Ruby gem scaffold for the UniSender API. API methods are not implemented yet.

Requires Ruby 3.3 or newer. There are no runtime dependencies.

## Development

Install the development dependencies and run the tests:

```sh
bundle install
bundle exec rake
```

Load the library from this checkout:

```sh
bundle exec ruby -Ilib -runisender -e 'puts Unisender::VERSION'
```

Build the gem:

```sh
bundle exec rake build
```

The package is written to `pkg/unisender-0.1.0.gem`. To install it locally:

```sh
gem install ./pkg/unisender-0.1.0.gem
```

Then load it with `require "unisender"`.

## License

Released under the MIT License. See [LICENSE.txt](LICENSE.txt).
