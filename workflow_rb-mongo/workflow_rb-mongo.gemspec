# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'workflow_rb/mongo/version'

Gem::Specification.new do |spec|
  spec.name          = "workflow_rb-mongo"
  spec.version       = WorkflowRb::Mongo::VERSION
  spec.authors       = ["Daniel Gerlag"]
  spec.email         = ["daniel@gerlag.ca"]

  spec.summary       = %q{MongoDB persistence provider for workflow_rb}
  spec.homepage      = "http://github.com/danielgerlag/workflow_rb"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "mongoid", "~> 6.0.3"
  spec.add_dependency "workflow_rb", "~> 0.1.0"

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rake-hooks", "~> 1.2.3"
  spec.add_development_dependency "rspec", "~> 3.0"
end
