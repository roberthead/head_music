lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "head_music/version"

Gem::Specification.new do |spec|
  spec.name = "head_music"
  spec.version = HeadMusic::VERSION
  spec.authors = ["Rob Head"]
  spec.email = ["robert.head@gmail.com"]

  spec.summary = "The rudiments of western music theory and analysis."
  spec.description = "Work with the elements of western music theory, such as pitches, scales, intervals, and chords."
  spec.homepage = "https://github.com/roberthead/head_music"
  spec.license = "MIT"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/roberthead/head_music",
    "changelog_uri" => "https://github.com/roberthead/head_music/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://rubydoc.info/gems/head_music",
    "bug_tracker_uri" => "https://github.com/roberthead/head_music/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/}) || f.match(/\.gem$/)
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 3.3.0"

  spec.add_runtime_dependency "activesupport", ">= 7.0", "< 10"
  spec.add_runtime_dependency "humanize", "~> 2.0"
  spec.add_runtime_dependency "i18n", "~> 1.8"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-its", "~> 2.0"
  spec.add_development_dependency "bundler-audit", "~> 0.9"
  spec.add_development_dependency "yard", "~> 0.9"
end
