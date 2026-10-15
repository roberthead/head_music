require "spec_helper"
require "open3"

# Verovio engraves each golden MEI document as SVG without a warning or an
# error. Runs only when a verovio executable is on the PATH. The lines checked
# are Verovio's own output, not the gem's.
describe HeadMusic::Notation::MEI do
  verovio = ENV["PATH"].to_s.split(File::PATH_SEPARATOR).map { |directory| File.join(directory, "verovio") }.find { |path| File.executable?(path) }

  before { skip "install verovio on the PATH to engrave the goldens with it" unless verovio }

  MEIFixtures.names.each do |name|
    it "engraves the #{name} golden as SVG without warnings or errors" do
      Dir.mktmpdir("verovio") do |directory|
        target = File.join(directory, "#{name}.svg")
        output, _status = Open3.capture2e(verovio, "--all-pages", "-o", target, MEIFixtures.path(name))
        expect([output.lines.grep(/\[(Warning|Error)\]/), Dir[File.join(directory, "*.svg")].empty?]).to eq [[], false]
      end
    end
  end
end
