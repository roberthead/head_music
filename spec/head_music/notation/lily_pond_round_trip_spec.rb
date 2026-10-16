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

  FIXTURE_NAMES = %i[
    speed_the_plough chromatic_air rests duo key_and_meter_change tacet song escaped_header anonymous air fourth_species
    tie_into_key_change tie_into_meter_change
    cross_staff_piano one_handed_piano tie_into_staff_crossing piano_and_melody choir_on_two_staves short_final_bar
    melody_with_part_dynamics duet_with_part_dynamics dal_segno_al_coda barline_styles
  ].freeze

  MARKING_FIXTURE_NAMES = %i[marked_melody grand_staff_piano_with_dynamics].freeze
  SPAN_FIXTURE_NAMES = %i[spanned_melody crossing_spans touching_slurs touching_slurs_on_tied_note spanned_piano].freeze
  # A rest across a barline reads back as a rest per bar, which the music
  # comparison counts as a change, so this one is checked for its spans alone.
  SPLIT_REST_FIXTURE_NAMES = %i[phrases_on_split_rest].freeze

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
      expect(reparsed.voices.last.voice_events.last.to_s).to eq "whole tied to quarter rest at 2:1:000"
    end

    LilyPondRoundTripSources::MARKING_FIXTURE_NAMES.each do |name|
      it "round-trips #{name} with its markings and dynamics" do
        expect_lily_pond_round_trip(MarkingFixtures.public_send(name))
      end
    end

    LilyPondRoundTripSources::SPAN_FIXTURE_NAMES.each do |name|
      it "round-trips #{name}, keeping where each span starts and ends" do
        original = MarkingFixtures.public_send(name)
        expect_same_spans(original, expect_lily_pond_round_trip(original))
      end
    end

    LilyPondRoundTripSources::SPLIT_REST_FIXTURE_NAMES.each do |name|
      it "keeps where each span of #{name} starts and ends" do
        original = MarkingFixtures.public_send(name)
        expect_same_spans(original, described_class.parse(original.to_lilypond))
      end
    end

    %i[dal_segno_al_coda barline_styles].each do |name|
      it "brings back every bar marking of #{name}" do
        original = LilyPondFixtures.public_send(name)
        expect(expect_lily_pond_round_trip(original).bars.map(&:to_h)).to eq original.bars.map(&:to_h)
      end

      it "renders #{name} the same after a parse" do
        rendered = LilyPondFixtures.public_send(name).to_lilypond
        expect(described_class.parse(rendered).to_lilypond).to eq rendered
      end
    end

    it "plays a D.S. al Coda back in the same order" do
      original = LilyPondFixtures.dal_segno_al_coda
      played = described_class.parse(original.to_lilypond).performance_order.map { |bar| [bar.number, bar.pass] }
      expect(played).to eq [[1, 1], [2, 1], [3, 1], [4, 1], [2, 1], [3, 1], [5, 1]]
      expect(played).to eq(original.performance_order.map { |bar| [bar.number, bar.pass] })
    end

    it "brings a part's dynamics back on the part, not the voices" do
      reparsed = expect_lily_pond_round_trip(MarkingFixtures.grand_staff_piano_with_dynamics)
      expect(reparsed.voices.map { |voice| voice.dynamic_events.map(&:to_h) }).to eq [[{"position" => "3:1:000", "level" => "mf"}], []]
    end
  end

  describe "dynamics where no note starts" do
    def abc_flow(music, dynamics)
      HeadMusic::Notation::ABC.parse("X:1\nT:Held\nL:1/4\nM:4/4\nK:C\n#{music}\n").tap do |flow|
        dynamics.each { |position, level| flow.voices.first.place_dynamic(position, level) }
      end
    end

    {
      "a level under a dotted half" => ["C3 D|", {"1:2" => :p}, "\\after 4 \\p c'2. d'4"],
      "two levels in one note" => ["C4|", {"1:2" => :p, "1:4" => :f}, "\\after 4 \\p \\after 2. \\f c'1"],
      "a level on the link after a barline split" => ["C2 D2-|D2 E2|", {"2:2" => :p}, "\\after 4 \\p d'2 e'2"],
      "a level on the later link of a tie within a bar" => ["C2- C/2 D3/2|", {"1:3:240" => :p}, "c'2~ \\after 16 \\p c'8"],
      "a level one tick into a whole note" => ["C4|", {"1:1:001" => :p}, "\\after 1*1/3840 \\p c'1"]
    }.each do |description, (music, dynamics, written)|
      context "with #{description}" do
        let(:original) { abc_flow(music, dynamics) }
        let(:rendered) { original.to_lilypond }
        let(:round_tripped) { described_class.parse(rendered) }

        it "writes it with \\after" do
          expect(rendered).to include written
        end

        it "reads it back at its position, owned by the voice, with every voice event whole" do
          expect_same_dynamic_positions(original, round_tripped)
          expect_same_voice_events(original, round_tripped)
        end

        it "compiles without warnings" do
          skip "lilypond is not installed" unless installed_lilypond

          expect(compile_warnings(rendered)).to be_empty
        end
      end
    end
  end

  describe "dynamics after the music's end in a short final bar" do
    def abc_flow(music, voices: 1)
      header = "X:1\nT:Trailing\nL:1/4\nM:4/4\nK:C\n"
      body = (voices == 1) ? "#{music}\n" : "V:1\n#{music}\nV:2\n#{music.downcase}\n"
      HeadMusic::Notation::ABC.parse(header + body)
    end

    {
      "a voice f after one voice" => [1, "C D E|", ->(flow) { flow.voices.first.place_dynamic("1:4", :f) }, "e'4 s4\\f \\bar"],
      "a part f after one voice" => [1, "C D E|", ->(flow) { flow.parts.first.place_dynamic("1:4", :f) }, "s2. s4\\f |"],
      "a voice f after two voices" => [2, "C D E|", ->(flow) { flow.voices.last.place_dynamic("1:4", :f) }, "e''4 s4\\f \\bar"],
      "a part f after two voices" => [2, "C D E|", ->(flow) { flow.parts.last.place_dynamic("1:4", :f) }, "s2. s4\\f |"],
      "a part f at the music's end after a full bar" => [1, "C D E F|G A|", ->(flow) { flow.parts.first.place_dynamic("2:3", :f) }, "s2 s2\\f |"]
    }.each do |description, (voices, music, place, written)|
      context "with #{description}" do
        let(:original) { abc_flow(music, voices: voices).tap(&place) }
        let(:rendered) { original.to_lilypond }
        let(:round_tripped) { described_class.parse(rendered) }

        it "writes the final bar full, with spacers in every voice before the final barline" do
          expect(rendered).to include written
          expect(bar_check_lines(rendered).select { |line| line.include?("\\bar") }).to all(match(/ s\d.* \\bar "\|\." \|\z/))
        end

        it "reads it back at its position and owner, with the music ending where it did" do
          expect_same_dynamic_positions(original, round_tripped)
          expect_same_voice_events(original, round_tripped)
          expect(round_tripped.last_sounding_bar_number).to eq original.last_sounding_bar_number
        end

        it "compiles without warnings" do
          skip "lilypond is not installed" unless installed_lilypond

          expect(compile_warnings(rendered)).to be_empty
        end
      end
    end
  end

  describe "a chord holding one letter and octave under two alterations" do
    def chord_then(key, chord, after)
      HeadMusic::Content::Flow.new(meter: "4/4", key_signature: key).tap do |flow|
        flow.add_voice.place("1:1", :half, chord).voice.place("1:3", :half, after)
      end
    end

    {
      "C major" => [%w[F4 F#4], "F4", "<fis'! f'!>2", %w[sharp natural natural]],
      "F major" => [%w[Bb4 B4], "Bb4", "<b'! bes'!>2", %w[natural flat flat]]
    }.each do |key, (chord, after, written, printed)|
      context "with #{key}" do
        let(:original) { chord_then(key, chord, after) }

        it "writes #{written} and reads #{chord.join(" and ")} back" do
          expect(original.to_lilypond).to include written
          expect_lily_pond_round_trip(original)
        end

        it "prints each member's accidental, and the bar remembers the highest" do
          skip "lilypond is not installed" unless installed_lilypond

          expect(compile_accidentals(original.to_lilypond)).to eq printed
        end
      end
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
    # whole-bar rest in an odd meter comes back as two voice events of the
    # same total length rather than one.
    it "re-renders a whole-bar rest in 5/4 as consecutive rests of the same total length" do
      reparsed = described_class.parse(described_class.parse(LilyPondRoundTripSources::FIVE_FOUR_REST).to_lilypond)
      expect(reparsed.voices.first.voice_events.map(&:to_s).last(2)).to eq ["whole rest at 2:1:000", "quarter rest at 2:5:000"]
    end
  end

  describe "hairpins" do
    # LilyPond ends a hairpin at a level or accent in its context, so the
    # writer cuts it there: a voice's at its levels and accented notes, a
    # part's at its own levels.
    pieces = lambda do |owner, hairpins|
      cuts = owner.dynamic_events.map(&:position)
      cuts += owner.voice_events.select(&:note_dynamic).map(&:position) if owner.is_a?(HeadMusic::Content::Voice)
      HeadMusic::Notation::HairpinSegments.split(hairpins, cuts)
    end

    define_method(:expect_hairpin_round_trip) do |flow|
      back = described_class.parse(described_class.render(flow))
      expect_same_hairpins(flow, back, segmented_by: pieces)
      expect_same_hairpin_in_force(flow, back)
    end

    # The writer writes a pickup bar of full length, rest included, as an
    # ordinary first bar, so it reads back as bar 1 and every position moves
    # a bar, notes as well as hairpins.
    (HairpinFixtures.all - [:hairpin_in_pickup]).each do |fixture|
      it "keeps where each hairpin of #{fixture} starts and ends" do
        expect_hairpin_round_trip(HairpinFixtures.public_send(fixture))
      end
    end

    HairpinGenerator::SEEDS.each do |seed|
      it "keeps where each hairpin of seed #{seed} starts and ends" do
        expect_hairpin_round_trip(HairpinGenerator.flow(seed, pickup: false))
      end
    end
  end

  describe "tuplets and grace notes" do
    # The writer brackets an ungrouped run as it would a group, and the reader
    # reads each bracket as a group, so brackets are compared, not groups.
    # The reader starts every stream at bar 1, so a flow opening with a
    # pickup bar comes back a bar later, and its summaries are shifted to
    # match.
    define_method(:expect_tuplet_round_trip) do |flow|
      rendered = described_class.render(flow)
      back = described_class.parse(rendered)
      shift = 1 - flow.voices.map(&:earliest_bar_number).min
      sounded = ->(summary) { summary.map { |voice| voice.reject { |event| event.last.empty? } } }
      expect(bracket_summary(back)).to eq shift_bars(bracket_summary(flow), shift)
      expect(grace_summary(back)).to eq shift_bars(grace_summary(flow), shift)
      expect(sounded.call(sounding_summary(back))).to eq shift_bars(sounded.call(sounding_summary(flow)), shift)
      expect(described_class.render(back)).to eq rendered
    end

    # Moves the bar of every position ("0:3:000") and exact point ("0+3/8").
    define_method(:shift_bars) do |summary, shift|
      case summary
      when Array then summary.map { |item| shift_bars(item, shift) }
      when String then summary.gsub(/(?<![\d:+\/])\d+(?=:\d+:\d+|\+)/) { |bar| (Integer(bar) + shift).to_s }
      else summary
      end
    end

    TupletFixtures.all.each do |fixture|
      it "keeps the brackets, grace notes, and timing of #{fixture}" do
        expect_tuplet_round_trip(TupletFixtures.public_send(fixture))
      end
    end

    TupletGenerator::SEEDS.each do |seed|
      it "keeps the brackets, grace notes, and timing of seed #{seed}" do
        expect_tuplet_round_trip(TupletGenerator.flow(seed))
      end
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

    (LilyPondRoundTripSources::MARKING_FIXTURE_NAMES + LilyPondRoundTripSources::SPAN_FIXTURE_NAMES +
      LilyPondRoundTripSources::SPLIT_REST_FIXTURE_NAMES).each do |name|
      it "compiles the rendered #{name} marking fixture" do
        expect(compile_quietly(installed_lilypond, MarkingFixtures.public_send(name).to_lilypond)).to be true
      end
    end
  end
end
