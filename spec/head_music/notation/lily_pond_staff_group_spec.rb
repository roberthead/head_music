require "spec_helper"

# A \new PianoStaff or \new StaffGroup is one part: its named staves become the
# part's staff system, its voices are written on those staves, and a
# \change Staff at a barline is a crossing from that bar onward.
describe HeadMusic::Notation::LilyPond do
  def group(type, *staves)
    "\\new #{type} << #{staves.join(" ")} >>"
  end

  def staff(name, *voices)
    %(\\new Staff = "#{name}" << #{voices.join(" ")} >>)
  end

  def voice(body, name: nil)
    name ? %(\\new Voice = "#{name}" { #{body} }) : "\\new Voice { #{body} }"
  end

  let(:grand_staff) do
    group(
      "PianoStaff",
      staff("upper", voice("\\clef treble e''1 | e''1 |", name: "right hand")),
      staff("lower", voice(%(\\clef bass c1 | \\change Staff = "upper" c'1 |), name: "left hand"))
    )
  end

  def staff_indexes(voice, bars)
    bars.map { |bar| voice.part.staff_system.staves.index { |candidate| candidate.equal?(voice.staff_at(bar)) } }
  end

  describe "a piano staff" do
    subject(:flow) { described_class.parse(grand_staff) }

    let(:part) { flow.parts.first }

    it "reads as one part" do
      expect([flow.parts.length, part.voices.map(&:role)]).to eq [1, ["right hand", "left hand"]]
    end

    it "braces its staves, each in the clef its voices open with" do
      expect([part.staff_system.bracket, part.staff_system.staves.map { |staff| staff.clef.name_key }])
        .to eq [:brace, %w[treble_clef bass_clef]]
    end

    it "writes each voice on its staff and crosses at the barline" do
      expect(part.voices.map { |voice| staff_indexes(voice, 1..2) }).to eq [[0, 0], [1, 0]]
    end
  end

  it "reads a staff group as a bracketed part" do
    source = group("StaffGroup", staff("a", voice("c''1")), staff("b", voice("c1")))
    expect(described_class.parse(source).parts.first.staff_system.bracket).to eq :bracket
  end

  it "reads several voices on one staff" do
    source = group("PianoStaff", staff("a", voice("e''1", name: "S"), voice("c''1", name: "A")), staff("b", voice("c1")))
    voices = described_class.parse(source).voices
    expect(voices.map { |voice| [voice.role, staff_indexes(voice, [1]).first] }).to eq [["S", 0], ["A", 0], [nil, 1]]
  end

  it "reads unnamed staves holding their music directly" do
    source = "\\new PianoStaff << \\new Staff { \\clef treble e''1 } \\new Staff { \\clef \"treble_8\" c'1 } >>"
    expect(described_class.parse(source).parts.first.staff_system.staves.map { |staff| staff.clef.name_key })
      .to eq %w[treble_clef vocal_tenor_clef]
  end

  it "keeps a staff that holds only whole-bar rests without giving it a voice" do
    source = group("PianoStaff", staff("a", voice("e''1 |", name: "right hand")), staff("b", voice("\\clef bass R1*4/4 |")))
    part = described_class.parse(source).parts.first
    expect([part.staff_system.length, part.voices.map(&:role)]).to eq [2, ["right hand"]]
  end

  it "keeps a silent staff silent through a short final bar" do
    source = group("PianoStaff", staff("a", voice("\\time 3/4 e''2", name: "right hand")), staff("b", voice("\\time 3/4 r2")))
    expect(described_class.parse(source).voices.map(&:role)).to eq ["right hand"]
  end

  describe "a staff change at a barline inside a tied note" do
    let(:lower_voice) do
      described_class.parse(
        group("PianoStaff", staff("upper", voice("e''1 | e''1 |")), staff("lower", voice(%(c2 c'2~ | \\change Staff = "upper" c'2 d'2 |))))
      ).voices.last
    end

    it "crosses at that barline, keeping the tied note whole" do
      expect([staff_indexes(lower_voice, 1..2), lower_voice.placements.map(&:to_s)[1]])
        .to eq [[1, 0], "half tied to half C4 at 1:3:000"]
    end
  end

  it "still names a voice outside a staff group by its staff alone" do
    expect(described_class.parse(%(\\new Staff { \\new Voice = "melody" { c'1 } })).voices.first.role).to be_nil
  end

  describe "rejections" do
    {
      "a staff change in the middle of a bar" => [
        %(\\new PianoStaff << \\new Staff = "a" { c''1 } \\new Staff = "b" { c2\n\\change Staff = "a" c'2 } >>),
        HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /\\change Staff in the middle of a bar is not supported \(line 2\)/
      ],
      "a staff change to an unknown staff" => [
        %(\\new PianoStaff << \\new Staff = "a" { c''1 } \\new Staff = "b" { c1 | \\change Staff = "c" c1 } >>),
        HeadMusic::Notation::LilyPond::ParseError, /No staff named "c"/
      ],
      "a staff change outside a staff group" => [
        %(\\new Staff { c'1 | \\change Staff = "a" c'1 }),
        HeadMusic::Notation::LilyPond::ParseError, /No staff named "a"/
      ],
      "a change of another context" => [
        %({ \\change Voice = "a" c'1 }),
        HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /\\change is supported only for a Staff/
      ],
      "a voice directly inside a staff group" => [
        %(\\new PianoStaff << \\new Voice { c'1 } >>),
        HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Only \\new Staff contexts are supported inside \\new PianoStaff/
      ],
      "a staff group inside another" => [
        %(\\new StaffGroup << \\new PianoStaff << \\new Staff { c'1 } >> >>),
        HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Only \\new Staff contexts are supported/
      ],
      "a staff group whose staves are not simultaneous" => [
        %(\\new PianoStaff { \\new Staff { c'1 } }),
        HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /expects its staves inside << >>/
      ],
      "a staff group inside \\relative" => [
        %(\\relative c' \\new PianoStaff << \\new Staff { c1 } >>),
        HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Simultaneous music inside \\relative/
      ]
    }.each do |description, (source, error_class, message)|
      it "raises for #{description}" do
        expect { described_class.parse(source) }.to raise_error(error_class, message)
      end
    end
  end
end
