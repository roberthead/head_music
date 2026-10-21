require "spec_helper"
require "open3"

# abcm2ps engraves each written tune without a warning or an error. Runs only
# when an abcm2ps executable is on the PATH. The lines checked are abcm2ps's
# own output, not the gem's. A line of few bars is underfull on the page,
# which is about the page's width, not the music, so that warning is off.
describe HeadMusic::Notation::ABC, oracle: :abcm2ps do
  def engraving_problems(abc)
    Dir.mktmpdir("abcm2ps") do |directory|
      source = File.join(directory, "tune.abc")
      File.write(source, abc)
      output, status = Open3.capture2e(Oracles.which("abcm2ps"), "--linewarn", "0", "-O", File.join(directory, "tune.ps"), source)
      [output.lines.grep(/\b(warning|error)\b/i), status.success?]
    end
  end

  {
    "the timeline melody" => -> { TimelineExpressionFixtures.melody },
    "the spanned melody" => -> { MarkingFixtures.spanned_melody },
    "the chorale" => -> { TimelineExpressionFixtures.chorale },
    "two voices with meter and key changes" => -> { LilyPondFixtures.key_and_meter_change },
    "two voices tied into a key change" => -> { LilyPondFixtures.tie_into_key_change },
    "meter and key changes" => -> {
      described_class.parse("X:1\nT:Changes\nM:4/4\nL:1/8\nK:G\n|:G8|[1 G8:|[2 [M:3/4][K:D]F6|[M:C]=F8|[M:C|][K:Bb]B8|]\n")
    }
  }.each do |name, flow|
    it "engraves #{name} without warnings or errors" do
      expect(engraving_problems(described_class.render(flow.call))).to eq [[], true]
    end
  end

  def transposed_score
    project = LayoutFixtures.clarinet_project(pitches: %w[F4 F4 F4 F4])
    flow = project.flows.first
    flow.parts.first.change_instrument(3, "clarinet_in_a")
    flow.add_part(player: project.add_player(name: "Flute"), instrument: "flute").add_voice(role: "flute").place("1:1", :whole, "F4")
    project.add_layout(kind: :score, players: project.players, concert_pitch: false)
  end

  it "engraves a transposed score whose clarinet changes instrument without warnings or errors" do
    expect(engraving_problems(transposed_score.to_abc)).to eq [[], true]
  end
end
