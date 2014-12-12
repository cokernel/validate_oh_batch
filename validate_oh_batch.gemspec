# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'validate_oh_batch/version'

Gem::Specification.new do |spec|
  spec.name          = "validate_oh_batch"
  spec.version       = ValidateOhBatch::VERSION
  spec.authors       = ["Michael Slone"]
  spec.email         = ["m.slone@gmail.com"]
  spec.summary       = %q{Validation tests for oral history SIP batches}
  spec.description   = %q{Validation tests for oral history SIP batches.}
  spec.homepage      = "https://github.com/cokernel/validate_oh_batch"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  #spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "bagit", "~> 0.3"
  spec.add_dependency "nokogiri", "~> 1.6"
  spec.add_dependency "trollop", "~> 2"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
