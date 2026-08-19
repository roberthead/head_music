require "spec_helper"

describe "HeadMusic::VERSION" do
  subject(:version) { HeadMusic::VERSION }

  it { is_expected.to be_a String }

  it "is a three-segment version and nothing else" do
    expect(version).to match(/\A\d+\.\d+\.\d+\z/)
  end

  it "parses as a rubygems version" do
    expect { Gem::Version.new(version) }.not_to raise_error
  end

  # The gemspec requires version.rb to read VERSION, so Bundler has already
  # loaded it by the time the suite starts measuring and its lines are never
  # recorded -- the file reports as wholly uncovered however much it is used.
  # Evaluating it once more here is what puts it on the record. The second
  # argument namespaces the constant into a throwaway module, so the real
  # HeadMusic::VERSION is left alone and nothing is reassigned.
  it "defines the same version when evaluated on its own" do
    namespace = Module.new
    load File.expand_path("../../lib/head_music/version.rb", __dir__), namespace

    expect(namespace::HeadMusic::VERSION).to eq version
  end
end
