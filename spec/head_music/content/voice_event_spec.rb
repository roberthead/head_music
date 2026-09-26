require "spec_helper"

describe HeadMusic::Content::VoiceEvent do
  # rubocop:disable RSpec/MultipleMemoizedHelpers
  subject(:voice_event) { described_class.build(voice, position, rhythmic_value, pitch) }

  let(:flow) { HeadMusic::Content::Flow.new.tap(&:add_voice) }
  let(:voice) { flow.voices.first }
  let(:position) { "2:2:240" }
  let(:pitch) { HeadMusic::Rudiment::Pitch.get("F#4") }
  let(:rhythmic_value) { HeadMusic::Rudiment::RhythmicValue.new(:eighth) }

  it "is abstract" do
    expect { described_class.new(voice, position, rhythmic_value) }.to raise_error(NoMethodError, /private method/)
  end

  describe ".build" do
    it "builds a note event for sounds" do
      expect(voice_event).to be_a HeadMusic::Content::NoteEvent
    end

    it "builds a rest event for no sounds" do
      expect(described_class.build(voice, position, rhythmic_value)).to be_a HeadMusic::Content::RestEvent
    end
  end

  its(:flow) { is_expected.to eq flow }
  its(:voice) { is_expected.to eq voice }
  its(:position) { is_expected.to eq HeadMusic::Content::Position.new(flow, "2:2:240") }
  its(:pitch) { is_expected.to eq "F#4" }

  context "when pitch is omitted" do
    let(:pitch) { nil }

    it { is_expected.to be_rest }

    its(:pitch) { is_expected.to be_nil }

    context "when the rhythmic value is a thirty-second note" do
      let(:rhythmic_value) { HeadMusic::Rudiment::RhythmicValue.new(:"thirty-second") }

      its(:rhythmic_value) { is_expected.to eq "thirty-second" }
    end
  end

  describe "#next_position" do
    specify { expect(voice_event.next_position).to eq "2:2:720" }

    context "when the rhythmic value is longer than a measure" do
      let(:rhythmic_value) { HeadMusic::Rudiment::RhythmicValue.new(:breve) }

      specify { expect(voice_event.next_position).to eq "4:2:240" }
    end

    context "when the value occurs at a fractional position" do
      let(:position) { "5:1:001" }
      let(:rhythmic_value) { HeadMusic::Rudiment::RhythmicValue.new(:"thirty-second") }

      specify { expect(voice_event.next_position).to eq "5:1:121" }
    end
  end

  describe "#during?" do
    subject(:voice_event) { described_class.build(voice, position, rhythmic_value, pitch) }

    let(:other_voice_event) { described_class.build(voice, "2:2:000", :quarter) }

    context "when it starts before the other voice event and ends at the start" do
      let(:position) { "2:1:000" }
      let(:rhythmic_value) { :quarter }

      specify { expect(voice_event.send(:starts_during?, other_voice_event)).to be_falsey }
      specify { expect(voice_event.send(:ends_during?, other_voice_event)).to be_falsey }
      specify { expect(voice_event.send(:wraps?, other_voice_event)).to be_falsey }

      it { is_expected.not_to be_during(other_voice_event) }
    end

    context "when it starts at the same time as the other voice event" do
      let(:position) { "2:2:000" }
      let(:rhythmic_value) { :eighth }

      specify { expect(voice_event.send(:starts_during?, other_voice_event)).to be_truthy }
      specify { expect(voice_event.send(:ends_during?, other_voice_event)).to be_truthy }
      specify { expect(voice_event.send(:wraps?, other_voice_event)).to be_falsey }

      it { is_expected.to be_during(other_voice_event) }
    end

    context "when it starts during the other voice event" do
      let(:position) { "2:2:480" }
      let(:rhythmic_value) { :quarter }

      specify { expect(voice_event.send(:starts_during?, other_voice_event)).to be_truthy }
      specify { expect(voice_event.send(:ends_during?, other_voice_event)).to be_falsey }
      specify { expect(voice_event.send(:wraps?, other_voice_event)).to be_falsey }

      it { is_expected.to be_during(other_voice_event) }
    end

    context "when it starts after and ends before the other voice event" do
      let(:position) { "2:2:240" }
      let(:rhythmic_value) { :sixteenth }

      specify { expect(voice_event.send(:starts_during?, other_voice_event)).to be_truthy }
      specify { expect(voice_event.send(:ends_during?, other_voice_event)).to be_truthy }
      specify { expect(voice_event.send(:wraps?, other_voice_event)).to be_falsey }

      it { is_expected.to be_during(other_voice_event) }
    end

    context "when it starts before and ends after the other voice event" do
      let(:position) { "2:1:000" }
      let(:rhythmic_value) { :whole }

      specify { expect(voice_event.send(:starts_during?, other_voice_event)).to be_falsey }
      specify { expect(voice_event.send(:ends_during?, other_voice_event)).to be_falsey }
      specify { expect(voice_event.send(:wraps?, other_voice_event)).to be_truthy }

      it { is_expected.to be_during(other_voice_event) }
    end

    context "when it ends during the other voice event" do
      let(:position) { "2:1:480" }
      let(:rhythmic_value) { :quarter }

      specify { expect(voice_event.send(:starts_during?, other_voice_event)).to be_falsey }
      specify { expect(voice_event.send(:ends_during?, other_voice_event)).to be_truthy }
      specify { expect(voice_event.send(:wraps?, other_voice_event)).to be_falsey }

      it { is_expected.to be_during(other_voice_event) }
    end

    context "when it starts at the end of the other voice event" do
      let(:position) { "2:3" }
      let(:rhythmic_value) { :quarter }

      specify { expect(voice_event.send(:starts_during?, other_voice_event)).to be_falsey }
      specify { expect(voice_event.send(:ends_during?, other_voice_event)).to be_falsey }
      specify { expect(voice_event.send(:wraps?, other_voice_event)).to be_falsey }

      it { is_expected.not_to be_during(other_voice_event) }
    end
  end

  describe "#to_h" do
    it "serializes a pitched note with string keys and values" do
      expect(voice_event.to_h).to eq(
        "position" => "2:2:240",
        "rhythmic_value" => "eighth",
        "sounds" => ["F♯4"]
      )
    end

    context "when the voice event is a rest" do
      let(:pitch) { nil }

      it "serializes an empty sounds array" do
        expect(voice_event.to_h["sounds"]).to eq []
      end
    end

    context "when the voice event is an unpitched sound on an instrument" do
      let(:pitch) { HeadMusic::Rudiment::UnpitchedSound.get("snare drum") }

      it "serializes the sound as an unpitched hash" do
        expect(voice_event.to_h["sounds"]).to eq [{"unpitched" => "snare_drum"}]
      end
    end

    context "when the voice event is the generic unpitched sound" do
      let(:pitch) { HeadMusic::Rudiment::UnpitchedSound.get }

      it "serializes the sound with a nil name" do
        expect(voice_event.to_h["sounds"]).to eq [{"unpitched" => nil}]
      end
    end

    context "when the voice event mixes a pitch and an unpitched sound" do
      let(:pitch) { ["C4", HeadMusic::Rudiment::UnpitchedSound.get("snare drum")] }

      it "serializes each sound in its own shape" do
        expect(voice_event.to_h["sounds"]).to eq ["C4", {"unpitched" => "snare_drum"}]
      end
    end

    context "when the position has a tick offset" do
      let(:position) { "1:1:480" }

      it "preserves the exact position string" do
        expect(voice_event.to_h["position"]).to eq "1:1:480"
      end
    end

    context "with beam_break_before flags" do
      it "omits the key when the flag is nil" do
        expect(voice_event.to_h).not_to have_key("beam_break_before")
      end

      it "includes the key when the flag is true" do
        voice_event.beam_break_before = true
        expect(voice_event.to_h["beam_break_before"]).to be true
      end

      it "includes the key when the flag is false" do
        voice_event.beam_break_before = false
        expect(voice_event.to_h["beam_break_before"]).to be false
      end
    end

    context "with syllables" do
      it "omits the key when there are none" do
        expect(voice_event.to_h).not_to have_key("syllables")
      end

      it "serializes syllables in verse order" do
        voice_event.sing("peace", verse: 2)
        voice_event.sing("glo", verse: 1, hyphen_after: true)
        expect(voice_event.to_h["syllables"]).to eq(
          [{"text" => "glo", "hyphen_after" => true}, {"text" => "peace", "verse" => 2}]
        )
      end
    end
  end

  describe "sung text" do
    it "carries no syllables by default" do
      expect(voice_event).not_to be_sung
      expect(voice_event.syllables).to eq({})
    end

    it "assigns a syllable for the default verse" do
      voice_event.sing("la")
      expect(voice_event).to be_sung
      expect(voice_event.syllable).to eq HeadMusic::Content::Syllable.new("la")
    end

    it "returns self from #sing so calls chain" do
      expect(voice_event.sing("la")).to be voice_event
    end

    it "holds at most one syllable per verse across multiple verses" do
      voice_event.sing("glo", hyphen_after: true).sing("peace", verse: 2)
      expect(voice_event.syllable(1).text).to eq "glo"
      expect(voice_event.syllable(2).text).to eq "peace"
    end

    it "replaces the syllable when the same verse is sung again" do
      voice_event.sing("la").sing("dee")
      expect(voice_event.syllable.text).to eq "dee"
      expect(voice_event.syllables.length).to eq 1
    end

    it "keys by the coerced verse so a string verse is found by its integer" do
      voice_event.sing("la", verse: "2")
      expect(voice_event.syllable(2).text).to eq "la"
      expect(voice_event.syllables.keys).to eq [2]
    end

    it "sorts mixed integer- and string-supplied verses without raising" do
      voice_event.sing("one").sing("two", verse: "2")
      expect(voice_event.to_h["syllables"].map { |syllable| syllable["text"] }).to eq %w[one two]
    end

    context "when two voice events at the same position are merged" do
      it "keeps the existing voice event's syllables" do
        voice_event.sing("keep")
        other = described_class.build(voice, position, rhythmic_value, HeadMusic::Rudiment::Pitch.get("A4"))
        other.sing("drop")
        voice_event.merge(other)
        expect(voice_event.syllable.text).to eq "keep"
      end
    end
  end

  describe "chords" do
    context "when given a single bare pitch" do
      it { is_expected.not_to be_chord }
      it { is_expected.to be_note }

      it "wraps the pitch in a frozen single-element sounds array" do
        expect(voice_event.pitches.map(&:to_s)).to eq ["F♯4"]
        expect(voice_event.sounds).to be_frozen
      end
    end

    context "when given an array of pitches" do
      let(:pitch) { %w[G4 C4 E4] }

      it { is_expected.to be_chord }
      it { is_expected.not_to be_note }
      it { is_expected.not_to be_rest }

      it "preserves the order of the given pitches" do
        expect(voice_event.pitches.map(&:to_s)).to eq %w[G4 C4 E4]
      end

      it "freezes the sounds array" do
        expect(voice_event.sounds).to be_frozen
      end

      it "derives the pitch from the highest chord tone" do
        expect(voice_event.pitch.to_s).to eq "G4"
      end

      it "serializes the pitches in order" do
        expect(voice_event.to_h).to eq(
          "position" => "2:2:240",
          "rhythmic_value" => "eighth",
          "sounds" => %w[G4 C4 E4]
        )
      end

      it "joins the pitches with spaces in to_s" do
        expect(voice_event.to_s).to eq "eighth G4 C4 E4 at 2:2:240"
      end
    end

    context "when chord tones tie enharmonically" do
      let(:pitch) { %w[B♭4 A♯4] }

      it "derives the first-listed pitch of the tie" do
        expect(voice_event.pitch.to_s).to eq "B♭4"
      end
    end

    context "when given a single-element array" do
      let(:pitch) { ["F#4"] }
      let(:bare_voice_event) { described_class.build(voice, position, rhythmic_value, "F#4") }

      it { is_expected.not_to be_chord }
      it { is_expected.to be_note }

      it "behaves identically to a bare pitch" do
        expect(voice_event.to_h).to eq bare_voice_event.to_h
        expect(voice_event.to_s).to eq bare_voice_event.to_s
      end
    end

    context "when given an empty array" do
      let(:pitch) { [] }

      it { is_expected.to be_rest }
      it { is_expected.not_to be_note }
      it { is_expected.not_to be_chord }

      its(:pitch) { is_expected.to be_nil }

      it "serializes an empty sounds array" do
        expect(voice_event.to_h["sounds"]).to eq []
      end
    end

    context "when given a bare unparseable pitch" do
      let(:pitch) { "bogus" }

      it "raises ArgumentError" do
        expect { voice_event }.to raise_error(ArgumentError, 'unknown sound: "bogus"')
      end
    end

    context "when an array element is unparseable" do
      let(:pitch) { %w[C4 bogus G4] }

      it "raises ArgumentError naming the sound" do
        expect { voice_event }.to raise_error(ArgumentError, 'unknown sound: "bogus"')
      end
    end

    context "when an array element is nil" do
      let(:pitch) { [nil] }

      it "raises ArgumentError" do
        expect { voice_event }.to raise_error(ArgumentError, "unknown sound: nil")
      end
    end

    context "when given duplicate pitches" do
      let(:pitch) { %w[C4 C4] }

      it { is_expected.not_to be_chord }

      it "keeps one of each pitch" do
        expect(voice_event.pitches.map(&:to_s)).to eq %w[C4]
      end
    end
  end

  describe "sound predicates" do
    let(:snare) { HeadMusic::Rudiment::UnpitchedSound.get("snare drum") }
    let(:kick) { HeadMusic::Rudiment::UnpitchedSound.get("bass drum") }

    context "with a lone pitch" do
      let(:pitch) { "C4" }

      it { is_expected.to be_note }
      it { is_expected.to be_pitched_note }
      it { is_expected.not_to be_unpitched_note }
      it { is_expected.not_to be_chord }
      it { is_expected.to be_pitched }
      it { is_expected.to be_sounded }
      it { is_expected.not_to be_rest }
    end

    context "with a lone unpitched sound" do
      let(:pitch) { snare }

      it { is_expected.to be_note }
      it { is_expected.to be_unpitched_note }
      it { is_expected.not_to be_pitched_note }
      it { is_expected.not_to be_pitched }
      it { is_expected.not_to be_chord }
      it { is_expected.to be_sounded }
    end

    context "with a pitched chord" do
      let(:pitch) { %w[C4 E4 G4] }

      it { is_expected.to be_chord }
      it { is_expected.not_to be_note }
    end

    context "with two unpitched sounds" do
      let(:pitch) { [kick, snare] }

      it { is_expected.not_to be_note }
      it { is_expected.not_to be_chord }
      it { is_expected.to be_sounded }
      it { is_expected.not_to be_pitched }
    end

    context "with one pitch and one unpitched sound" do
      let(:pitch) { ["C4", kick] }

      it { is_expected.not_to be_note }
      it { is_expected.not_to be_chord }
      it { is_expected.to be_pitched }

      it "derives the pitch from the pitched sound" do
        expect(voice_event.pitch.to_s).to eq "C4"
      end

      it "exposes only the pitched subset as pitches" do
        expect(voice_event.pitches.map(&:to_s)).to eq ["C4"]
      end
    end

    context "with no sounds" do
      let(:pitch) { nil }

      it { is_expected.to be_rest }
      it { is_expected.not_to be_sounded }
      it { is_expected.not_to be_note }
      it { is_expected.not_to be_pitched_note }
      it { is_expected.not_to be_unpitched_note }
      it { is_expected.not_to be_chord }
      it { is_expected.not_to be_pitched }
    end
  end

  describe "#merge" do
    context "when the same unpitched sound arrives under an alias" do
      let(:pitch) { HeadMusic::Rudiment::UnpitchedSound.get("tabor") }
      let(:other) do
        described_class.build(voice, position, rhythmic_value, HeadMusic::Rudiment::UnpitchedSound.get("snare drum"))
      end

      it "deduplicates to one sound" do
        expect(voice_event.merge(other).sounds.length).to eq 1
      end
    end

    context "with an authored beam flag" do
      let(:other) { described_class.build(voice, position, rhythmic_value, "A4") }

      it "keeps the receiver's beam_break_before (chord members share one beam edge)" do
        voice_event.beam_break_before = true
        other.beam_break_before = false
        expect(voice_event.merge(other).beam_break_before).to be true
      end
    end
  end

  describe "#beam_break_before" do
    it "defaults to nil (meter-derived beaming)" do
      expect(voice_event.beam_break_before).to be_nil
    end

    it "is writable after construction" do
      voice_event.beam_break_before = true
      expect(voice_event.beam_break_before).to be true
    end
  end

  its(:inspect) { is_expected.to eq "#<HeadMusic::Content::NoteEvent eighth F♯4 at 2:2:240>" }

  describe "#to_s" do
    context "with an unpitched sound alongside a pitch" do
      let(:pitch) { ["C4", HeadMusic::Rudiment::UnpitchedSound.get("snare drum")] }
      let(:rhythmic_value) { :quarter }
      let(:position) { "2:1" }

      it "brackets the unpitched name" do
        expect(voice_event.to_s).to eq "quarter C4 [snare drum] at 2:1:000"
      end
    end

    context "with the generic unpitched sound" do
      let(:pitch) { HeadMusic::Rudiment::UnpitchedSound.get }

      it "brackets the generic name" do
        expect(voice_event.to_s).to eq "eighth [unpitched] at 2:2:240"
      end
    end

    context "with pitches only" do
      let(:pitch) { %w[C4 E4] }

      it "is unchanged from the pitch-only format" do
        expect(voice_event.to_s).to eq "eighth C4 E4 at 2:2:240"
      end
    end
  end

  describe "sound resolution" do
    context "when given a bare unpitched instrument name" do
      let(:pitch) { "snare drum" }

      it "resolves to an unpitched sound" do
        expect(voice_event.sounds.map(&:name_key)).to eq [:snare_drum]
        expect(voice_event).to be_unpitched_note
      end
    end

    context "when given a bare pitched instrument name" do
      let(:pitch) { "violin" }

      it "raises ArgumentError naming both intents" do
        expect { voice_event }.to raise_error(
          ArgumentError,
          '"violin" is a pitched instrument; place a pitch such as "D4", ' \
          'or pass HeadMusic::Rudiment::UnpitchedSound.get("violin") for a percussive hit'
        )
      end
    end

    context "when given an unparseable pitch string" do
      let(:pitch) { "H4" }

      it "raises ArgumentError" do
        expect { voice_event }.to raise_error(ArgumentError, 'unknown sound: "H4"')
      end
    end

    context "when given a pitched instrument instance" do
      let(:pitch) { HeadMusic::Instruments::Instrument.get("violin") }

      it "resolves to an unpitched sound on that instrument" do
        expect(voice_event.sounds.map(&:name_key)).to eq [:violin]
        expect(voice_event).to be_unpitched_note
      end
    end

    context "when given an unpitched sound on a pitched instrument" do
      let(:pitch) { HeadMusic::Rudiment::UnpitchedSound.get("violin") }

      it "is accepted as-is" do
        expect(voice_event.sounds).to eq [pitch]
        expect(voice_event).not_to be_pitched
      end
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
