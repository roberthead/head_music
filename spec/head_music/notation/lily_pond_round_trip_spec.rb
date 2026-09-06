require "spec_helper"

# Hand-written inputs for the round-trip and oracle examples. Each relative
# source is paired with the pitches it must resolve to and an absolute twin
# that must parse to the same music.
module LilyPondRoundTripSources
  RELATIVE_TWINS = {
    "the story's excerpt" => {
      relative: "\\relative c' { \\key g \\major \\time 4/4 g8 a b c d c b g | }",
      absolute: "{ \\key g \\major \\time 4/4 g8 a8 b8 c'8 d'8 c'8 b8 g8 | }",
      pitches: %w[G3 A3 B3 C4 D4 C4 B3 G3]
    },
    "a chromatic line" => {
      relative: "\\relative c'' { \\key a \\minor a4 gis a bes | b cis d ees | }",
      absolute: "{ \\key a \\minor a'4 gis'4 a'4 bes'4 | b'4 cis''4 d''4 ees''4 | }",
      pitches: %w[A4 G♯4 A4 B♭4 B4 C♯5 D5 E♭5]
    },
    "ties and rests" => {
      relative: "\\relative c' { c2~ c8 r8 d4 | r1 | }",
      absolute: "{ c'2~ c'8 r8 d'4 | r1 | }",
      pitches: %w[C4 D4]
    },
    "a chord" => {
      relative: "\\relative c' { <c e g>2 <d f a> | }",
      absolute: "{ <c' e' g'>2 <d' f' a'>2 | }",
      pitches: %w[G4 A4]
    },
    "block comments" => {
      relative: "\\relative c' { %{ two\nlines %} c4 d e f | % end\n}",
      absolute: "{ c'4 d'4 e'4 f'4 | }",
      pitches: %w[C4 D4 E4 F4]
    }
  }.freeze

  OTHER_SOURCES = {
    "a duo with roles" => %(<< \\new Staff \\with { instrumentName = "Melody" } { \\clef treble e''1 | d''1 | } \\new Staff \\with { instrumentName = "Bass" } { \\clef bass c1 | R1*4/4 | } >>),
    "a mid-piece change" => "{ \\key g \\major g'1 | \\key d \\major \\time 3/4 d'2. | }"
  }.freeze

  FIVE_FOUR_REST = "{ \\time 5/4 c'1 c'4 | R1*5/4 | }".freeze

  FIXTURE_NAMES = %i[speed_the_plough chromatic_air rests duo key_and_meter_change tacet song escaped_header anonymous air].freeze

  ALL_HAND_WRITTEN = RELATIVE_TWINS.flat_map { |name, twin| [["#{name} (relative)", twin[:relative]], ["#{name} (absolute)", twin[:absolute]]] }
    .concat(OTHER_SOURCES.to_a, [["a whole-bar rest in 5/4", FIVE_FOUR_REST]])
    .to_h.freeze
end

# The writer's fixtures read back through the parser, retroactively
# automating the export story's toolchain-acceptance proof, and the real
# lilypond binary as an oracle for every input shape the parser accepts.
describe HeadMusic::Notation::LilyPond do
  def non_ascii_flow
    flow = HeadMusic::Content::Flow.new(name: "Ægir", composer: "Dvořák")
    flow.add_voice.place("1:1", :whole, "C4")
    flow
  end

  def chords_and_ties_flow
    flow = HeadMusic::Content::Flow.new(name: "Chords", meter: "4/4")
    voice = flow.add_voice
    voice.place("1:1", "half tied to eighth", %w[C4 E4 G4])
    voice.place("1:3:480", :eighth, "D4")
    voice.place("1:4", :quarter, "E4")
    flow
  end

  # A short second voice, so the writer pads its second bar with R1*5/4.
  def five_four_flow
    flow = HeadMusic::Content::Flow.new(name: "Five", meter: "5/4")
    upper = flow.add_voice
    upper.place("1:1", :whole, "C4")
    upper.place("1:5", :quarter, "D4")
    upper.place("2:1", :whole, "E4")
    upper.place("2:5", :quarter, "F4")
    flow.add_voice.place("1:1", "whole tied to quarter", "C3")
    flow
  end

  describe "round trips of the writer's fixtures" do
    LilyPondRoundTripSources::FIXTURE_NAMES.each do |name|
      it "round-trips #{name}" do
        expect_lily_pond_round_trip(LilyPondFixtures.public_send(name))
      end
    end

    it "round-trips a non-ASCII header byte for byte" do
      reparsed = expect_lily_pond_round_trip(non_ascii_flow)
      expect([reparsed.name, reparsed.composer]).to eq ["Ægir", "Dvořák"]
    end

    it "round-trips chords and tied values" do
      expect_lily_pond_round_trip(chords_and_ties_flow)
    end

    it "reads the writer's whole-bar padding in an odd meter as a rest of the bar's length" do
      reparsed = expect_lily_pond_round_trip(five_four_flow)
      expect(reparsed.voices.last.placements.last.to_s).to eq "whole tied to quarter rest at 2:1:000"
    end
  end

  describe "hand-written inputs" do
    LilyPondRoundTripSources::RELATIVE_TWINS.each do |name, twin|
      it "resolves #{name} to the expected pitches" do
        expect(described_class.parse(twin[:relative]).voices.first.pitches.map(&:to_s)).to eq twin[:pitches]
      end

      it "reads #{name} the same in relative and absolute mode" do
        expect(described_class.parse(twin[:relative]).to_lilypond).to eq described_class.parse(twin[:absolute]).to_lilypond
      end
    end

    LilyPondRoundTripSources::OTHER_SOURCES.each do |name, source|
      it "re-renders #{name} to a document that parses to the same music" do
        expect_lily_pond_round_trip(described_class.parse(source))
      end
    end

    # The writer emits a tied rest chain as consecutive rests, so a
    # whole-bar rest in an odd meter comes back as two placements of the
    # same total length rather than one.
    it "re-renders a whole-bar rest in 5/4 as consecutive rests of the same total length" do
      reparsed = described_class.parse(described_class.parse(LilyPondRoundTripSources::FIVE_FOUR_REST).to_lilypond)
      expect(reparsed.voices.first.placements.map(&:to_s).last(2)).to eq ["whole rest at 2:1:000", "quarter rest at 2:5:000"]
    end
  end

  describe "with the lilypond binary as an oracle" do
    before do
      skip "lilypond is not installed" unless installed_lilypond
    end

    LilyPondRoundTripSources::ALL_HAND_WRITTEN.each do |name, source|
      it "compiles #{name} as authored" do
        expect(compile_quietly(installed_lilypond, "\\version \"2.24.0\"\n#{source}\n")).to be true
      end

      it "compiles #{name} after a parse and render" do
        expect(compile_quietly(installed_lilypond, described_class.parse(source).to_lilypond)).to be true
      end
    end

    LilyPondRoundTripSources::FIXTURE_NAMES.each do |name|
      it "compiles the rendered #{name} fixture" do
        expect(compile_quietly(installed_lilypond, LilyPondFixtures.public_send(name).to_lilypond)).to be true
      end
    end
  end
end
