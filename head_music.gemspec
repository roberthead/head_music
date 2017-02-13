# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'head_music/version'

Gem::Specification.new do |spec|
  spec.name          = "head_music"
  spec.version       = HeadMusic::VERSION
  spec.authors       = ["Rob Head"]
  spec.email         = ["robert.head@gmail.com"]

  spec.summary       = %q{The rudiments of western music theory.}
  spec.description   = %q{Work with the elements of western music theory, such as pitches, scales, intervals, and chords.}
  spec.homepage      = "https://github.com/roberthead/head_music"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-its", "~> 1.2"
end
