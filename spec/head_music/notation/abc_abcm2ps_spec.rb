require "spec_helper"
require "open3"

# abcm2ps engraves each written tune without a warning or an error. Runs only
# when an abcm2ps executable is on the PATH. The lines checked are abcm2ps's
# own output, not the gem's.
describe HeadMusic::Notation::ABC, oracle: :abcm2ps do
  def engraving_problems(abc)
    Dir.mktmpdir("abcm2ps") do |directory|
      source = File.join(directory, "tune.abc")
      File.write(source, abc)
      output, status = Open3.capture2e(Oracles.which("abcm2ps"), "-O", File.join(directory, "tune.ps"), source)
      [output.lines.grep(/\b(warning|error)\b/i), status.success?]
    end
  end

  {
    "the timeline melody" => -> { TimelineExpressionFixtures.melody },
    "the spanned melody" => -> { MarkingFixtures.spanned_melody }
  }.each do |name, flow|
    it "engraves #{name} without warnings or errors" do
      expect(engraving_problems(described_class.render(flow.call))).to eq [[], true]
    end
  end
end
