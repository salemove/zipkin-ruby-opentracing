# Zipkin

OpenTracing Tracer implementation for Zipkin in Ruby

## Requirements

Zipkin version >= 2.0.0

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'zipkin'
```

## Usage

```ruby
require 'zipkin/tracer'
OpenTracing.global_tracer = Zipkin::Tracer.build(url: 'http://localhost:9411', service_name: 'echo')

span = OpenTracing.start_span('span name')
span.finish
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/salemove/zipkin-ruby-opentracing


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

