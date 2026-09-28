require "spec_helper"

# A \new Dynamics holds the dynamics of a part: the staff group it sits in, or
# the staff it follows in the same << >>. Its spacers mark time, so each level
# keeps its exact position.
describe HeadMusic::Notation::LilyPond do
  def self.piano(dynamics)
    %(\\new PianoStaff << \\new Staff = "a" { e''1 | e''1 | e''1 } \\new Dynamics { #{dynamics} } \\new Staff = "b" { \\clef bass c1 | c1 | c1 } >>)
  end

  def piano(dynamics)
    self.class.piano(dynamics)
  end

  def part_levels(part)
    part.dynamic_events.map { |event| [event.position.to_s, event.level.name_key] }
  end

  describe "inside a piano staff" do
    subject(:flow) { described_class.parse(piano("s1\\p | s4 s2.\\f | s2. s4\\mp")) }

    it "places each level on the group's part at its exact position, mid-note included" do
      expect(part_levels(flow.parts.first)).to eq [%w[1:1:000 p], %w[2:2:000 f], %w[3:4:000 mp]]
    end

    it "governs both hands" do
      expect(flow.voices.map { |voice| voice.dynamic_at("2:3").name_key }).to eq %w[f f]
    end

    it "gives the voices no dynamics of their own" do
      expect(flow.voices.map(&:dynamic_events)).to eq [[], []]
    end
  end

  it "reads a Dynamics context written after the staves" do
    source = %(\\new StaffGroup << \\new Staff { c''1 } \\new Staff { c1 } \\new Dynamics { s1\\ff } >>)
    expect(part_levels(described_class.parse(source).parts.first)).to eq [%w[1:1:000 ff]]
  end

  it "reads a Dynamics context beside a single staff as that staff's part's" do
    flow = described_class.parse(%(<< \\new Staff { c''1 | c''1 } \\new Dynamics { s1*2/4 s2\\p | s1\\f } \\new Staff { c1 | c1 } >>))
    expect(flow.parts.map { |part| part_levels(part) }).to eq [[%w[1:3:000 p], %w[2:1:000 f]], []]
  end

  it "gives each voice of a single staff the dynamics beside it" do
    flow = described_class.parse(%(<< \\new Staff << \\new Voice { e''1 } \\new Voice { c''1 } >> \\new Dynamics { s1\\mf } >>))
    expect(flow.voices.map { |voice| voice.dynamic_at("1:1").name_key }).to eq %w[mf mf]
  end

  it "reads a Dynamics context beside a piano staff as the piano's" do
    flow = described_class.parse(%(<< \\new PianoStaff << \\new Staff { e''1 } \\new Staff { c1 } >> \\new Dynamics { s1\\pp } >>))
    expect(part_levels(flow.parts.first)).to eq [%w[1:1:000 pp]]
  end

  it "reads rests and whole-bar rests there as spacers" do
    expect(part_levels(described_class.parse(piano("R1*4/4 | r2 r2\\f | s1")).parts.first)).to eq [%w[2:3:000 f]]
  end

  it "reads nested braces there" do
    expect(part_levels(described_class.parse(piano("{ s1 | } { s1\\f | s1 }")).parts.first)).to eq [%w[2:1:000 f]]
  end

  it "drops articulations and ornaments there" do
    flow = described_class.parse(piano("s1-.\\p\\trill | s1 | s1"))
    expect(part_levels(flow.parts.first)).to eq [%w[1:1:000 p]]
    expect(flow.voices.flat_map(&:note_events).flat_map { |note_event| note_event.articulations + note_event.ornaments }).to be_empty
  end

  describe "a sforzando there" do
    def note_dynamics(flow)
      flow.voices.map { |voice| voice.note_events.map { |note_event| note_event.note_dynamic&.name_key } }
    end

    it "goes on every note of the part that attacks at its position" do
      expect(note_dynamics(described_class.parse(piano("s1 | s1\\sfz | s1")))).to eq [[nil, "sfz", nil], [nil, "sfz", nil]]
    end

    it "is dropped where no note attacks" do
      expect(note_dynamics(described_class.parse(piano("s2 s2\\sfz | s1 | s1")))).to eq [[nil, nil, nil], [nil, nil, nil]]
    end

    it "yields to a note's own" do
      source = %(\\new PianoStaff << \\new Staff { e''1\\sf } \\new Dynamics { s1\\sfz } \\new Staff { \\clef bass c1 } >>)
      expect(note_dynamics(described_class.parse(source))).to eq [["sf"], ["sfz"]]
    end

    it "leaves the level in force alone" do
      flow = described_class.parse(piano("s1\\p | s1\\sfz | s1"))
      expect(flow.voices.map { |voice| voice.dynamic_at("2:1").name_key }).to eq %w[p p]
    end
  end

  it "ignores a \\key, \\time, or \\clef there, which only repeats the staves'" do
    source = piano("\\key c \\major \\time 4/4 \\clef treble s1\\p | s1 | s1")
    expect(part_levels(described_class.parse(source).parts.first)).to eq [%w[1:1:000 p]]
  end

  it "drops hairpins and text spans there" do
    source = piano("s1\\p\\< | s1\\f\\> | s1\\!\\cresc")
    expect(part_levels(described_class.parse(source).parts.first)).to eq [%w[1:1:000 p], %w[2:1:000 f]]
  end

  # The reader starts every stream at bar 1, so a pickup bar comes back as
  # bar 1 and everything after it a bar later. The dynamics move with the
  # notes, so each still governs the notes it governed.
  describe "a pickup flow with dynamics" do
    let(:original) do
      LilyPondFixtures.pickup_and_short_final_bar.tap do |flow|
        flow.parts.first.place_dynamic("0:3", :p)
        flow.parts.first.place_dynamic("2:1", :f)
        flow.voices.first.place_dynamic("1:1", :mf)
      end
    end
    let(:round_tripped) { described_class.parse(original.to_lilypond) }

    it "reads the part's dynamics back a bar later" do
      expect(part_levels(round_tripped.parts.first)).to eq [%w[1:3:000 p], %w[3:1:000 f]]
    end

    it "reads the voice's dynamics back a bar later" do
      expect(round_tripped.voices.first.dynamic_events.map(&:to_s)).to eq ["mf at 2:1:000"]
    end

    it "keeps the level in force at every note" do
      levels = [original, round_tripped].map do |flow|
        voice = flow.voices.first
        voice.note_events.map { |note_event| voice.dynamic_at(note_event.position).name_key }
      end
      expect(levels.last).to eq levels.first
    end
  end

  describe "rejections" do
    {
      "a Dynamics context with no staff before it" => [
        %(<< \\new Dynamics { s1\\p } \\new Staff { c'1 } >>), described_class::UnsupportedFeatureError, /must be inside a \\new PianoStaff/
      ],
      "a Dynamics context alone" => [%(\\new Dynamics { s1\\p }), described_class::UnsupportedFeatureError, /must be inside/],
      "a note inside a Dynamics context" => [piano("c'1\\p"), described_class::UnsupportedFeatureError, /Notes inside \\new Dynamics/],
      "a chord inside a Dynamics context" => [piano("<c' e'>1"), described_class::UnsupportedFeatureError, /Notes inside \\new Dynamics/],
      "a command inside a Dynamics context" => [piano("\\tuplet 3/2 { s4 s4 s4 }"), described_class::UnsupportedFeatureError, /"\\tuplet"/],
      "a malformed \\time inside a Dynamics context" => [piano("\\time x s1"), described_class::ParseError, /line 1/],
      "a tie inside a Dynamics context" => [piano("s1~ s1"), described_class::ParseError, /Unexpected token "~" inside \\new Dynamics/],
      "an unsupported mark inside a Dynamics context" => [piano("s1 ["), described_class::UnsupportedFeatureError, /"\["/],
      "a context inside a Dynamics context" => [
        %(<< \\new Staff { c'1 } \\new Dynamics << \\new Voice { c'1 } >> >>), described_class::UnsupportedFeatureError, /Contexts inside \\new Dynamics/
      ],
      "a failed bar check inside a Dynamics context" => [piano("s2 | s2"), described_class::ParseError, /Bar check failed at: 1\/2 in bar 1/],
      "a spacer that falls between ticks" => [piano("s1*1/7\\p"), described_class::UnsupportedFeatureError, /falls between ticks/],
      "two levels for one part at one position" => [
        %(\\new PianoStaff << \\new Staff { c''1 } \\new Dynamics { s1\\p } \\new Dynamics { s1\\f } >>), described_class::ParseError, /already placed/
      ],
      "a spacer outside a Dynamics context" => [%({ c'4 s4 }), described_class::UnsupportedFeatureError, /"s4"/]
    }.each do |description, (source, error_class, message)|
      it "raises for #{description}" do
        expect { described_class.parse(source) }.to raise_error(error_class, message)
      end
    end
  end
end
