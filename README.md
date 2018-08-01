# Zipkin

OpenTracing Tracer implementation for Zipkin in Ruby

## Requirements

Zipkin version >= 2.0.0. Zipkin >= 2.8 is required to use protobuf encoding.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'zipkin'
```

## Usage

```ruby
require 'zipkin/tracer'
OpenTracing.global_tracer = Zipkin::Tracer.build(
  url: 'http://localhost:9411',
  encoder: Zipkin::Encoders::ProtobufEncoder,
  service_name: 'echo'
)

OpenTracing.start_active_span('span name') do
  # do something

  OpenTracing.start_active_span('inner span name') do
    # do something else
  end
end
```

See [opentracing-ruby](https://github.com/opentracing/opentracing-ruby) for more examples.

### Encoders

This library supports two encoders: json (default) and protobuf.

Using json encoder:

```ruby
require 'zipkin/tracer'
OpenTracing.global_tracer = Zipkin::Tracer.build(
  url: 'http://localhost:9411',
  encoder: Zipkin::Encoders::JsonEncoder,
  service_name: 'echo'
)
```

Using protobuf encoder:

```ruby
require 'zipkin/tracer'
OpenTracing.global_tracer = Zipkin::Tracer.build(
  url: 'http://localhost:9411',
  encoder: Zipkin::Encoders::ProtobufEncoder,
  service_name: 'echo'
)
```

### Samplers

#### Const sampler

`Const` sampler always makes the same decision for new traces depending on the initialization value. Set `sampler` to: `Zipkin::Samplers::Const.new(true)` to mark all new traces as sampled.

#### Probabilistic sampler

`Probabilistic` sampler samples traces with probability equal to `rate` (must be between 0.0 and 1.0). Set `sampler` to `Zipkin::Samplers::Probabilistic.new(rate: 0.1)` to mark 10% of new traces as sampled.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/salemove/zipkin-ruby-opentracing


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

