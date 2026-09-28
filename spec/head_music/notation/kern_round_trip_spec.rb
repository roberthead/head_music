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

  describe "the span fixtures" do
    %i[spanned_melody crossing_spans touching_slurs spanned_piano].each do |name|
      it "keeps where each span of #{name} starts and ends" do
        original = MarkingFixtures.public_send(name)
        expect_same_spans(original, expect_kern_round_trip(original))
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
