# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'workflow_rb/db/version'

Gem::Specification.new do |spec|
  spec.name          = "workflow_rb-db"
  spec.version       = WorkflowRb::Db::VERSION
  spec.authors       = ["Daniel gerlag"]
  spec.email         = ["daniel@gerlag.ca"]

  spec.summary       = %q{Active Record persistence provider for WorkflowRb}
  spec.homepage      = "https://github.com/danielgerlag/workflow_rb"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "workflow_rb", "~> 0.1.0"
  spec.add_dependency "activerecord", "~> 5.0.0"

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
