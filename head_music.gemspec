# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "head_music/version"

Gem::Specification.new do |spec|
  spec.name = "head_music"
  spec.version = HeadMusic::VERSION
  spec.authors = ["Rob Head"]
  spec.email = ["robert.head@gmail.com"]

  spec.summary = "The rudiments of western music theory."
  spec.description = "Work with the elements of western music theory, such as pitches, scales, intervals, and chords."
  spec.homepage = "https://github.com/roberthead/head_music"
  spec.license = "MIT"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.5"

  spec.add_runtime_dependency "activesupport", "> 5.0"
  spec.add_runtime_dependency "humanize", "~> 1.3"
  spec.add_runtime_dependency "i18n", "~> 1.8"

  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-its", "~> 1.2"
end
