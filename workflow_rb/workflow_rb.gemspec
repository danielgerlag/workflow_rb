# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'workflow_rb/version'

Gem::Specification.new do |spec|
  spec.name          = "workflow_rb"
  spec.version       = WorkflowRb::VERSION
  spec.authors       = ["Daniel Gerlag"]
  spec.email         = ["daniel@gerlag.ca"]
  spec.license       = "MIT"
  spec.summary       = %q{Lightweight workflow library}
  spec.homepage      = "http://github.com/danielgerlag/workflow_rb"


  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
