# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bummr/version'

Gem::Specification.new do |spec|
  spec.name          = "bummr"
  spec.version       = Bummr::VERSION
  spec.authors       = ["Lee Pender"]
  spec.email         = ["lpender@gmail.com"]
  spec.summary       = %q{Helper script to intelligently update your Gemfile}
  spec.description   = %q{See Readme}
  spec.homepage      = "https://github.com/lpender/bummr"
  spec.license       = "MIT"

  spec.files         = Dir["{lib,bin}/**/*"] + %w|LICENSE README.md|
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  # Toolkit for building powerful command-line interfaces
  spec.add_dependency "thor"
  # Colorize printed text on ANSI terminals
  spec.add_dependency "rainbow"

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-nc"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "spring"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "jet_black", "~> 0.3"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-remote"
  spec.add_development_dependency "pry-nav"
  spec.add_development_dependency "codeclimate-test-reporter", "~> 1.0.0"
end
