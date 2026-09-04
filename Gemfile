source "https://rubygems.org"

ruby ">= 3.3.0"

# Specify your gem's dependencies in head_music.gemspec
gemspec

# Allow CI to test against specific ActiveSupport versions. An unset or empty
# value leaves the gemspec range alone -- empty is truthy in Ruby, so a matrix
# cell that sets the key to "" would otherwise resolve against "~> .0".
activesupport_version = ENV["ACTIVESUPPORT_VERSION"].to_s
gem "activesupport", "~> #{activesupport_version}.0" unless activesupport_version.empty?

gem "standard", require: false

group :test do
  # rubocop is not listed directly: standard pins it (~> 1.88.0) and must
  # lead. Listing it here let Dependabot bump it past standard, which the
  # resolver "fixed" by downgrading standard 1.56 -> 1.35.
  gem "rubocop-rspec", require: false
  gem "rubocop-rake", require: false
  # simplecov 1.1.x forwards an anonymous block inside a block, which is a
  # syntax error on Ruby 3.3. Unpin once upstream drops that or we drop 3.3.
  gem "simplecov", "< 1.1", require: false
end

group :development do
  gem "bundler-audit", require: false
  gem "rubycritic", require: false
  gem "yard", require: false
  gem "kramdown", require: false
end
