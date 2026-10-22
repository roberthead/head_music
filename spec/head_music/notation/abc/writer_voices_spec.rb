require "spec_helper"

describe HeadMusic::Notation::ABC::Writer do
  def render(flow)
    described_class.new(flow).to_s
  end

  def body_of(flow)
    render(flow).lines.drop_while { |line| !line.start_with?("K:") }.drop(1).join
  end

  def two_voices(first, second, roles: %w[S B], header: "")
    HeadMusic::Notation::ABC.parse(
      "X:1\nT:Two\nM:4/4\nL:1/4\n#{header}V:#{roles[0]}\nV:#{roles[1]}\nK:C\nV:#{roles[0]}\n#{first}\nV:#{roles[1]}\n#{second}\n"
    )
  end

  describe "a flow of several voices" do
    let(:systems) do
      <<~ABC
        V:S
        V:B
        K:C
        V:S
        c2 d2 e2 f2|g2 a2 b2 c'2|d'2 c'2 b2 a2|g2 f2 e2 d2|
        V:B
        C2 D2 E2 F2|G2 A2 B2 c2|d2 c2 B2 A2|G2 F2 E2 D2|
        V:S
        c8|]
        V:B
        C8|]
      ABC
    end

    it "declares each voice before K: and writes their lines in turn, four bars at a time" do
      flow = two_voices("c d e f|g a b c'|d' c' b a|g f e d|c4|", "C D E F|G A B c|d c B A|G F E D|C4|")
      expect(render(flow).lines.drop(4).join).to eq systems
    end

    it "writes a flow of one voice with no V: field" do
      expect(render(TimelineExpressionFixtures.melody).lines.grep(/\AV:/)).to be_empty
    end

    it "writes a fermata on each voice's note where a timeline fermata begins" do
      expect(body_of(TimelineExpressionFixtures.chorale).lines.grep(/!fermata!/).length).to eq 2
    end
  end

  describe "voice ids" do
    def ids(*roles)
      flow = HeadMusic::Content::Flow.new
      roles.each { |role| flow.add_voice(role: role).place("1:1", :whole, "C4") }
      render(flow).lines.grep(/\AV:/).first(roles.length).map(&:chomp)
    end

    it "names each voice for its role" do
      expect(ids("S", "B")).to eq %w[V:S V:B]
    end

    it "names a voice by its place where its role holds a space, a bracket, a percent, or an equals sign" do
      expect(ids("cantus firmus", "a]", "b%", "c=d")).to eq %w[V:1 V:2 V:3 V:4]
    end

    it "names voices by their places where they share a role or have none" do
      expect(ids("tenor", "tenor", nil)).to eq %w[V:1 V:2 V:3]
    end

    it "skips a place another voice's role already names" do
      expect(ids("2", "cantus firmus")).to eq %w[V:2 V:3]
    end
  end

  describe "a voice silent in some bars" do
    let(:flow) do
      HeadMusic::Content::Flow.new(meter: "4/4").tap do |flow|
        flow.add_voice(role: "early").place("1:1", :whole, "C5").voice.place("2:1", :half, "D5")
        flow.add_voice(role: "late").place("2:1", :whole, "C4").voice.place("3:1", :whole, "D4")
      end
    end

    it "writes whole-bar rests before a voice enters, and fills the bar where a voice ends early" do
      expect(body_of(flow)).to eq "V:early\nc8|d4 z4|z8|]\nV:late\nz8|C8|D8|]\n"
    end

    it "reads the rests back where they were written" do
      round_tripped = HeadMusic::Notation::ABC.parse(render(flow))
      expect(round_tripped.voices.map { |voice| voice.voice_events.map(&:to_s) }).to eq [
        ["whole C5 at 1:1:000", "half D5 at 2:1:000", "half rest at 2:3:000", "whole rest at 3:1:000"],
        ["whole rest at 1:1:000", "whole C4 at 2:1:000", "whole D4 at 3:1:000"]
      ]
    end

    it "writes the flow's tempo change on the lead voice's rest" do
      flow.change_tempo(3, HeadMusic::Rudiment::Tempo.new("quarter", 90))
      expect(body_of(flow).lines[1]).to eq "c8|d4 z4|[Q:1/4=90]z8|]\n"
    end

    it "refuses a mark no rest of a silent bar can reach before writing any bar" do
      flow.voices.last.place_dynamic("1:1:320", :p)
      expect { render(flow) }.to raise_error(HeadMusic::Notation::ABC::RenderError, /dynamic p at 1:1:320/)
    end
  end

  describe "marks of the flow" do
    let(:flow) do
      two_voices(
        %(|:[P:A]!segno!c d "^rit."e f:|[Q:1/4=90]g4!D.S.!|),
        "|:C D E F:|G4|",
        header: "Q:1/4=120\n"
      )
    end

    let(:lines) { body_of(flow).lines }

    it "writes the part label, the tempo marks, and the navigation in the lead voice" do
      expect(lines[1]).to eq %(|:[P:A]!segno!c2 d2 "^rit."e2 f2:|[Q:1/4=90]g8!D.S.!|]\n)
    end

    it "writes the repeats alone in the other voices" do
      expect(lines[3]).to eq "|:C2 D2 E2 F2:|G8|]\n"
    end

    it "reads the marks back once" do
      round_tripped = HeadMusic::Notation::ABC.parse(render(flow))
      expect([round_tripped.tempo_ramps.length, round_tripped.bar(1).rehearsal_mark]).to eq [1, "A"]
    end
  end

  describe "dynamics" do
    let(:flow) do
      HeadMusic::Content::Flow.new(meter: "4/4").tap do |flow|
        part = flow.add_part
        part.add_voice(role: "upper").place("1:1", :whole, "C5")
        part.add_voice(role: "lower").place("1:1", :whole, "C4")
        part.place_dynamic("1:1", :p)
      end
    end

    it "writes a part's dynamics in its first voice only" do
      expect(body_of(flow)).to eq "V:upper\n!p!c8|]\nV:lower\nC8|]\n"
    end

    it "writes a hairpin in each voice that holds one at the same time" do
      flow.voices.each { |voice| voice.add_span(:crescendo, from: "1:1", to: "2:1") }
      expect(body_of(flow)).to eq "V:upper\n!p!!<(!c8 !<)!y|]\nV:lower\n!<(!C8 !<)!y|]\n"
    end
  end

  describe "meter and key changes" do
    let(:flow) { two_voices("c d e f|[M:3/4][K:D]f g a|", "C D E F|F G A|") }

    it "writes each change in every voice" do
      expect(body_of(flow).lines.values_at(1, 3)).to eq ["c2 d2 e2 f2|[M:3/4][K:D]f2 g2 a2|]\n", "C2 D2 E2 F2|[M:3/4][K:D]F2 G2 A2|]\n"]
    end
  end
end
