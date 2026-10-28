require "spec_helper"

# Flows written to kern and read back keep their music; see
# spec/support/kern_round_trip.rb for what the comparison leaves out.
describe HeadMusic::Notation::Kern do
  def rhythmic_value(name)
    HeadMusic::Rudiment::RhythmicValue.get(name)
  end

  # One note per bar from bar 1, each filling its bar.
  def place_bars(voice, pitches, rhythmic_value = :whole)
    pitches.each_with_index { |pitch, index| voice.place("#{index + 1}:1", rhythmic_value, pitch) }
  end

  describe "hand-built flows" do
    context "with two parts, their players, and their instruments" do
      let(:flow) do
        HeadMusic::Content::Flow.new(name: "Duet", composer: "Anonymous", key_signature: "D minor", meter: "3/4").tap do |duet|
          soprano = duet.add_part(player: HeadMusic::Content::Player.new(name: "Soprano"), instrument: "soprano_voice").add_voice
          %w[D5 E5 F5].each_with_index { |pitch, index| soprano.place("1:#{index + 1}", :quarter, pitch) }
          bass = duet.add_part(player: HeadMusic::Content::Player.new(name: "Bass"), instrument: "bass_voice").add_voice
          bass.place("1:1", rhythmic_value("dotted half"), "D3")
        end
      end

      it("round-trips") { expect_kern_round_trip(flow) }
    end

    context "with chords, rests, and notes that cross barlines" do
      let(:flow) do
        HeadMusic::Content::Flow.new(meter: "4/4").tap do |ties|
          voice = ties.add_voice
          voice.place("1:1", :quarter, %w[C4 E4 G4])
          voice.place("1:2", :eighth)
          voice.place("1:2:480", rhythmic_value("dotted half"), "A4")
          voice.place("2:1:480", rhythmic_value("whole tied to eighth"), "B4")
          voice.place("3:2", :half, "C5")
        end
      end

      it("round-trips") { expect_kern_round_trip(flow) }
    end

    context "with a pickup and a short final bar" do
      let(:flow) do
        HeadMusic::Content::Flow.new(meter: "3/4").tap do |upbeat|
          voice = upbeat.add_voice
          voice.place("0:1", :half)
          voice.place("0:3", :quarter, "G4")
          voice.place("1:1", rhythmic_value("dotted half"), "C5")
          voice.place("2:1", :half, "B4")
        end
      end

      it("round-trips") { expect_kern_round_trip(flow) }
    end

    context "with key, meter, tempo, and clef changes" do
      let(:flow) do
        HeadMusic::Content::Flow.new(meter: "4/4", tempo: HeadMusic::Rudiment::Tempo.new("quarter", 90)).tap do |changing|
          part = changing.add_part(staff_system: HeadMusic::Content::StaffSystem.single_staff(clef: :bass_clef))
          voice = part.add_voice
          voice.place("1:1", :whole, "C3")
          voice.place("2:1", rhythmic_value("dotted half"), "F4")
          changing.change_key_signature(2, -1, tonal_context: HeadMusic::Rudiment::Key.get("F major"))
          changing.change_meter(2, "3/4")
          changing.change_tempo(2, HeadMusic::Rudiment::Tempo.new("half", 40))
          part.staff_system.first_staff.change_clef(2, :treble_clef)
        end
      end

      it("round-trips") { expect_kern_round_trip(flow) }
    end

    context "with repeats" do
      let(:flow) do
        HeadMusic::Content::Flow.new(meter: "2/4").tap do |repeated|
          place_bars(repeated.add_voice, %w[C4 D4 E4], :half)
          repeated.bars(1).last.starts_repeat = true
          repeated.bars(2).last.ends_repeat_after_num_plays = 2
          repeated.bars(3).last.starts_repeat = true
          repeated.bars(3).last.ends_repeat_after_num_plays = 2
        end
      end

      it("round-trips") { expect_kern_round_trip(flow) }
    end

    context "with double and final barlines and section labels" do
      let(:flow) do
        HeadMusic::Content::Flow.new(meter: "2/4").tap do |marked|
          place_bars(marked.add_voice, %w[C4 D4 E4 F4 G4], :half)
          marked.bars(1).last.rehearsal_mark = "A"
          marked.bars(2).last.barline = :double
          marked.bars(3).last.rehearsal_mark = "Verse 2"
          marked.bars(3).last.barline = :final
          marked.bars(4).last.rehearsal_mark = "B"
          marked.bars(4).last.barline = :dashed
        end
      end

      it "round-trips" do
        reparsed = expect_kern_round_trip(flow)
        expect(reparsed.bars(5).map { |bar| [bar.barline, bar.rehearsal_mark] })
          .to eq [[:regular, "A"], [:double, nil], [:final, "Verse 2"], [:regular, "B"], [:regular, nil]]
      end
    end

    context "with a section label on the bar after a pickup" do
      let(:flow) do
        HeadMusic::Content::Flow.new(meter: "3/4").tap do |upbeat|
          voice = upbeat.add_voice
          voice.place("0:1", :half)
          voice.place("0:3", :quarter, "G4")
          voice.place("1:1", rhythmic_value("dotted half"), "C5")
          upbeat.bars(1).last.rehearsal_mark = "A"
          upbeat.bars(0).last.barline = :double
        end
      end

      it("round-trips") { expect_kern_round_trip(flow) }
    end

    context "with a double barline where a repeat ends" do
      let(:flow) do
        HeadMusic::Content::Flow.new(meter: "2/4").tap do |repeated|
          place_bars(repeated.add_voice, %w[C4 D4 E4], :half)
          repeated.bars(1).last.ends_repeat_after_num_plays = 2
          repeated.bars(1).last.barline = :double
          repeated.bars(2).last.barline = :final
          repeated.bars(3).last.starts_repeat = true
        end
      end

      it "keeps the repeats in place of the barline styles" do
        reparsed = expect_kern_round_trip(flow)
        expect(reparsed.bars(3).map(&:barline)).to eq %i[regular regular regular]
      end
    end

    context "with soprano and alto sharing one staff" do
      let(:flow) do
        HeadMusic::Content::Flow.new(meter: "4/4").tap do |choral|
          upper = choral.add_part(
            player: HeadMusic::Content::Player.new(name: "Women"),
            staff_system: HeadMusic::Content::StaffSystem.single_staff(clef: :treble_clef)
          )
          place_bars(upper.add_voice, %w[E5 D5])
          place_bars(upper.add_voice, %w[C5 B4])
          place_bars(choral.add_voice, %w[C3 G3])
        end
      end

      it "round-trips" do
        reparsed = expect_kern_round_trip(flow)
        expect(reparsed.parts.map { |part| [part.voices.length, part.staff_system.length] }).to eq [[2, 1], [1, 1]]
      end
    end

    context "with a grand-staff part whose voice crosses staves" do
      let(:staff_system) { HeadMusic::Content::StaffSystem.grand_staff }
      let(:flow) do
        HeadMusic::Content::Flow.new(meter: "4/4").tap do |pianistic|
          piano = pianistic.add_part(instrument: "piano", staff_system: staff_system)
          place_bars(piano.add_voice, %w[E5 D5])
          place_bars(piano.add_voice, %w[C5 B4])
          left_hand = piano.add_voice
          left_hand.assign_staff(1, staff_system.staves.last)
          place_bars(left_hand, %w[C3 G4])
          left_hand.assign_staff(2, staff_system.staves.first)
        end
      end

      it("round-trips") { expect_kern_round_trip(flow) }
    end

    context "with two verses of hyphenated lyrics" do
      let(:flow) do
        HeadMusic::Content::Flow.new(meter: "4/4").tap do |sung|
          melody = sung.add_voice
          melody.place("1:1", :half, "C5").sing("Aus", verse: 1).sing("Fear", verse: 2)
          melody.place("1:3", :half, "D5").sing("mei", verse: 1, hyphen_after: true).sing("not", verse: 2)
          melody.place("2:1", :whole, "E5").sing("nes", verse: 1)
        end
      end

      it("round-trips") { expect_kern_round_trip(flow) }
    end

    context "with a section label beside lyrics and dynamics" do
      let(:flow) do
        HeadMusic::Content::Flow.new(meter: "4/4").tap do |sung|
          melody = sung.add_voice
          melody.place("1:1", :whole, "C5").sing("Aus", verse: 1)
          melody.place("2:1", :whole, "D5").sing("mei", verse: 1)
          sung.parts.first.place_dynamic("1:1", :p)
          sung.bars(2).last.rehearsal_mark = "B"
        end
      end

      it("round-trips") { expect_kern_round_trip(flow) }
    end
  end

  describe "the LilyPond writer's fixtures" do
    %i[speed_the_plough chromatic_air rests duo key_and_meter_change tacet song air fourth_species].each do |name|
      it "round-trips #{name}" do
        expect_kern_round_trip(LilyPondFixtures.public_send(name))
      end
    end
  end

  describe "the marking fixtures" do
    it "round-trips the marked melody, keeping every marking and the dynamic in force at every note" do
      original = MarkingFixtures.marked_melody
      expect_same_markings(original, expect_kern_round_trip(original))
    end

    it "round-trips the grand-staff piano's music" do
      expect_kern_round_trip(MarkingFixtures.grand_staff_piano_with_dynamics)
    end

    # The **dynam spine cannot say which voice it means, so the right hand's
    # own mf comes back as the part's, and reaches the left hand too.
    it "gives the grand-staff piano's voice dynamic to the whole part" do
      original = MarkingFixtures.grand_staff_piano_with_dynamics
      expected = marking_summary(original).tap { |voices| voices.last[2][4] = "mf" }
      expect(marking_summary(expect_kern_round_trip(original))).to eq expected
    end
  end

  describe "dynamics where nothing attacks" do
    # kern gives every level to its part, so each part's levels are compared
    # together, wherever the original kept them.
    def levels(flow)
      flow.parts.flat_map { |part| [*part.dynamic_events, *part.voices.flat_map(&:dynamic_events)].map(&:to_s) }.sort
    end

    def values(voice)
      voice.voice_events.map { |voice_event| "#{voice_event.rhythmic_value} at #{voice_event.position}" }
    end

    def whole_note_flow(level_position)
      HeadMusic::Content::Flow.new(name: "Held", meter: "4/4").tap do |flow|
        flow.add_voice.place("1:1", :whole, "C4")
        flow.parts.first.place_dynamic(level_position, :p)
      end
    end

    it "keeps a dotted quarter whole, and the level one eighth into it" do
      original = HeadMusic::Notation::ABC.parse("X:1\nL:1/8\nM:4/4\nK:C\nC3 D E2 F2|\n")
      original.voices.first.place_dynamic("1:1:480", :p)
      restored = expect_kern_round_trip(original)
      expect([values(restored.voices.first).first, levels(restored)]).to eq ["dotted quarter at 1:1:000", ["p at 1:1:480"]]
    end

    it "keeps a level a quarter into a whole note at its position" do
      restored = expect_kern_round_trip(whole_note_flow("1:2"))
      expect([values(restored.voices.first), levels(restored)]).to eq [["whole at 1:1:000"], ["p at 1:2:000"]]
    end

    def rest_flow
      whole_note_flow("1:1").tap do |flow|
        flow.voices.first.place("2:1", :whole)
        flow.parts.first.place_dynamic("2:3", :pp)
      end
    end

    def two_voice_flow
      HeadMusic::Content::Flow.new(name: "Two Held", meter: "4/4").tap do |flow|
        part = flow.add_part(instrument: "piano")
        part.add_voice(role: "upper").place("1:1", :whole, "E5")
        part.add_voice(role: "lower").place("1:1", :whole, "C4")
        part.place_dynamic("1:3", :mf)
      end
    end

    def two_part_flow
      whole_note_flow("1:2").tap do |flow|
        upper = flow.add_voice
        upper.place("1:1", :whole, "E5")
        upper.part.place_dynamic("1:3", :f)
      end
    end

    it "keeps a rest whole under a level" do
      restored = expect_kern_round_trip(rest_flow)
      expect([values(restored.voices.first), levels(restored)])
        .to eq [["whole at 1:1:000", "whole at 2:1:000"], ["p at 1:1:000", "pp at 2:3:000"]]
    end

    it "keeps two voices of a part holding across a level" do
      restored = expect_kern_round_trip(two_voice_flow)
      expect([restored.voices.map { |voice| values(voice) }, levels(restored)])
        .to eq [[["whole at 1:1:000"], ["whole at 1:1:000"]], ["mf at 1:3:000"]]
    end

    it "keeps each part's level at its own position when they share a span" do
      expect(levels(expect_kern_round_trip(two_part_flow))).to eq ["f at 1:3:000", "p at 1:2:000"]
    end

    it "keeps the marked melody's levels at their positions" do
      original = MarkingFixtures.marked_melody
      expect(levels(expect_kern_round_trip(original))).to eq levels(original)
    end

    it "keeps the grand-staff piano's levels at their positions" do
      original = MarkingFixtures.grand_staff_piano_with_dynamics
      expect(levels(expect_kern_round_trip(original))).to eq levels(original)
    end
  end

  describe "dynamics where no note starts" do
    def abc(body)
      HeadMusic::Notation::ABC.parse("X:1\nT:Trailing\nL:1/4\nM:4/4\nK:C\n#{body}\n")
    end

    def expect_round_trip_positions(original, latest_bar_number)
      restored = expect_kern_round_trip(original)
      expect_same_dynamic_positions(original, restored, merged_into: "part")
      expect_same_voice_events(original, restored)
      expect(restored.latest_bar_number).to eq latest_bar_number
    end

    it "keeps a voice dynamic after the last note of a short final bar" do
      original = abc("C D E|").tap { |flow| flow.voices.first.place_dynamic("1:4", :f) }
      expect_round_trip_positions(original, 1)
    end

    it "keeps a part dynamic after the last note of a short final bar" do
      original = abc("C D E|").tap { |flow| flow.parts.first.place_dynamic("1:4", :f) }
      expect_round_trip_positions(original, 1)
    end

    it "keeps a dynamic a half after the last note of a short final bar" do
      original = abc("C D E F|G A|").tap { |flow| flow.voices.first.place_dynamic("2:3", :f) }
      expect_round_trip_positions(original, 2)
    end

    it "keeps a dynamic between the timed rows after the music's end" do
      original = abc("C D E F|G A|").tap { |flow| flow.parts.first.place_dynamic("2:4", :f) }
      expect_round_trip_positions(original, 2)
    end

    it "keeps one part's trailing dynamic, adding no rest to either part" do
      original = HeadMusic::Notation::ABC.parse("X:1\nT:Two\nL:1/4\nM:4/4\nK:C\nV:1\nc d e|\nV:2 clef=bass\nC, D, E,|\n")
      original.parts.last.place_dynamic("1:4", :f)
      expect_round_trip_positions(original, 1)
    end

    def pickup_flow
      HeadMusic::Content::Flow.new(name: "Pickup", meter: "4/4").tap do |flow|
        voice = flow.add_voice
        voice.place("0:1", :dotted_half)
        voice.place("0:4", :quarter, "C4")
        voice.place("1:1", :whole, "D4")
      end
    end

    it "keeps a part dynamic before a pickup's first note" do
      original = pickup_flow.tap { |flow| flow.parts.first.place_dynamic("0:2", :p) }
      expect_round_trip_positions(original, 1)
    end
  end

  describe "the span fixtures" do
    %i[spanned_melody crossing_spans touching_slurs touching_slurs_on_tied_note spanned_piano phrases_on_split_rest].each do |name|
      it "keeps where each span of #{name} starts and ends" do
        original = MarkingFixtures.public_send(name)
        expect_same_spans(original, expect_kern_round_trip(original))
      end
    end
  end

  describe "the melisma fixtures" do
    %i[melismas two_verse_melismas].each do |name|
      it "keeps where each melisma of #{name} starts and ends" do
        original = MelismaFixtures.public_send(name)
        expect_same_melismas(original, expect_kern_round_trip(original))
      end
    end

    it "reads a melisma that stops before an unsung note back as held up to the next syllable, since Lord_ names no end" do
      reparsed = described_class.parse(described_class.render(MelismaFixtures.short_melisma))
      expect(melisma_ends(reparsed)).to eq [[0, 1, "1:1:000", "1:3:000"]]
    end
  end

  describe "hairpins" do
    # The **dynam spine holds the hairpins of a part and its voices, and
    # Verovio drops a hairpin that a level or spine accent interrupts, so each
    # comes back as the part's, cut into touching pieces wherever one falls.
    def self.pieces(part)
      owners = [part, *part.voices]
      HeadMusic::Notation::HairpinSegments.split(owners.flat_map(&:spans).select(&:hairpin?), cuts(part)).uniq(&:to_h)
    end

    def self.cuts(part)
      accented = part.voices.flat_map(&:note_events).select { |note_event| %w[sf rfz fp].include?(note_event.note_dynamic&.name_key) }
      [part, *part.voices].flat_map(&:dynamic_events).map(&:position) + accented.map(&:position)
    end

    # A part's pieces from different owners that overlap cannot share one line.
    def self.overlapping?(flow)
      flow.parts.any? { |part| pieces(part).combination(2).any? { |one, other| one.from < other.to && other.from < one.to } }
    end

    def segmented_by
      lambda do |owner, hairpins|
        part = owner.is_a?(HeadMusic::Content::Part) ? owner : owner.part
        HeadMusic::Notation::HairpinSegments.split(hairpins, self.class.cuts(part))
      end
    end

    # expect_kern_round_trip compares the voice events, by length, since kern
    # writes a value crossing a barline as tied links and splits rests there.
    def expect_hairpin_round_trip(original)
      restored = expect_kern_round_trip(original)
      expect_same_hairpins(original, restored, merged_into: "part", segmented_by: segmented_by)
      expect_same_hairpin_in_force(original, restored, per: :part)
    end

    HairpinFixtures.all.each do |name|
      it "keeps where each hairpin of #{name} starts and ends" do
        expect_hairpin_round_trip(HairpinFixtures.public_send(name))
      end
    end

    it "reads the hairpins fixture back to itself from what it writes" do
      flow = described_class.parse(File.read(File.expand_path("../../fixtures/notation/kern/hairpins.krn", __dir__)))
      expect(described_class.parse(described_class.render(flow)).to_h).to eq flow.to_h
    end

    HairpinGenerator::SEEDS.each do |seed|
      if overlapping?(HairpinGenerator.flow(seed, voices: 2, one_line: false, pickup: true))
        it "refuses the overlapping hairpins of seed #{seed}" do
          expect { described_class.render(HairpinGenerator.flow(seed, voices: 2, one_line: false, pickup: true)) }
            .to raise_error(HeadMusic::Notation::Kern::RenderError, /\*\*dynam spine holds one hairpin at a time/)
        end
      else
        it "keeps where each hairpin of seed #{seed} starts and ends" do
          expect_hairpin_round_trip(HairpinGenerator.flow(seed, voices: 2, one_line: false, pickup: true))
        end
      end

      it "keeps where each hairpin of seed #{seed} starts and ends, on one line across two voices" do
        expect_hairpin_round_trip(HairpinGenerator.flow(seed, voices: 2, one_line: true, pickup: true))
      end
    end
  end

  describe "the cantus firmus catalog" do
    HeadMusic::Content::CantusFirmus::Example.all.each do |example|
      it "round-trips #{example}" do
        expect_kern_round_trip(example.to_flow)
      end
    end
  end
end
