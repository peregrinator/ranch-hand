# RanchHand

Provides a simple interface on top the Rancher CLI and the Kubectl commands to make running commands in pods easier.
This is particularily useful when using Kubernetes in a development environment.

![ranch-hand demo](https://github.com/peregrinator/ranch-hand/raw/master/doc/ranch-hand-demo.gif "Ranch-hand Demo")

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ranch-hand'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ranch-hand

## Usage

RanchHand makes use of the [GLI](https://github.com/davetron5000/gli) (Git Like Interface) gem to create a CLI with features similar to the Git CLI. Run `ranch-hand help` or `ranch-hand command help` for usage information.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/peregrinator/ranch-hand. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RanchHand project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/peregrinator/ranch-hand/blob/master/CODE_OF_CONDUCT.md).
