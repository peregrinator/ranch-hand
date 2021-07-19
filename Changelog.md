### 0.7.0
#### Features
Add support for command arguments. Commands that use arguments no longer need to be wrapped in a string in order to be passed properly. This provides a better interface for editor plugins that automatically append arguments to the end of a custom command.
  - https://github.com/peregrinator/ranch-hand/commit/a70d44042507d407c0088a2a8ffa4d4514a800af
  - ex: before: `ranch-hand exec -c 'rspec spec/foo.rb:21'`, now: `ranch-hand exec -c rspec spec/foo.rb:21`

#### Bugfixes:
- d76855: correctly handle scenario in which the namespace queried has no pods

### 0.6.0

Updates for Ruby 3.0 compat
  - https://rubyreferences.github.io/rubychanges/3.0.html#keyword-arguments-are-now-fully-separated-from-positional-arguments