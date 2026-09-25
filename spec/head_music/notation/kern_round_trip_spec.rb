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

  describe "the cantus firmus catalog" do
    HeadMusic::Content::CantusFirmus::Example.all.each do |example|
      it "round-trips #{example}" do
        expect_kern_round_trip(example.to_flow)
      end
    end
  end
end
