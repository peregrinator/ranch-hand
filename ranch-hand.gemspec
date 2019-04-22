
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ranch_hand/version"

Gem::Specification.new do |spec|
  spec.name          = "ranch-hand"
  spec.version       = RanchHand::VERSION
  spec.authors       = ["Peregrinator"]
  spec.email         = ["bob.burbach@gmail.com"]

  spec.summary       = %q{Provides an interface between the Rancher CLI and the Kubectl commands}
  spec.description   = %q{}
  spec.homepage      = "https://github.com/peregrinator/ranch-hand"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_runtime_dependency "gli", "~> 2.18"
  spec.add_runtime_dependency "pry", "~> 0.12.2"
  spec.add_runtime_dependency "tty-command", "~> 0.8.2"
  spec.add_runtime_dependency "tty-prompt", "~> 0.18.1"
end
