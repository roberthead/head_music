require "spec_helper"

describe HeadMusic::Content::Placement do
  # rubocop:disable RSpec/MultipleMemoizedHelpers
  subject(:placement) { described_class.new(voice, position, rhythmic_value, pitch) }

  let(:composition) { HeadMusic::Content::Composition.new.tap(&:add_voice) }
  let(:voice) { composition.voices.first }
  let(:position) { "2:2:240" }
  let(:pitch) { HeadMusic::Rudiment::Pitch.get("F#4") }
  let(:rhythmic_value) { HeadMusic::Rudiment::RhythmicValue.new(:eighth) }

  its(:composition) { is_expected.to eq composition }
  its(:voice) { is_expected.to eq voice }
  its(:position) { is_expected.to eq HeadMusic::Content::Position.new(composition, "2:2:240") }
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
    specify { expect(placement.next_position).to eq "2:2:720" }

    context "when the rhythmic value is longer than a measure" do
      let(:rhythmic_value) { HeadMusic::Rudiment::RhythmicValue.new(:breve) }

      specify { expect(placement.next_position).to eq "4:2:240" }
    end

    context "when the value occurs at a fractional position" do
      let(:position) { "5:1:001" }
      let(:rhythmic_value) { HeadMusic::Rudiment::RhythmicValue.new(:"thirty-second") }

      specify { expect(placement.next_position).to eq "5:1:121" }
    end
  end

  describe "#during?" do
    subject(:placement) { described_class.new(voice, position, rhythmic_value, pitch) }

    let(:other_placement) { described_class.new(voice, "2:2:000", :quarter) }

    context "when it starts before the other placement and ends at the start" do
      let(:position) { "2:1:000" }
      let(:rhythmic_value) { :quarter }

      specify { expect(placement.send(:starts_during?, other_placement)).to be_falsey }
      specify { expect(placement.send(:ends_during?, other_placement)).to be_falsey }
      specify { expect(placement.send(:wraps?, other_placement)).to be_falsey }

      it { is_expected.not_to be_during(other_placement) }
    end

    context "when it starts at the same time as the other placement" do
      let(:position) { "2:2:000" }
      let(:rhythmic_value) { :eighth }

      specify { expect(placement.send(:starts_during?, other_placement)).to be_truthy }
      specify { expect(placement.send(:ends_during?, other_placement)).to be_truthy }
      specify { expect(placement.send(:wraps?, other_placement)).to be_falsey }

      it { is_expected.to be_during(other_placement) }
    end

    context "when it starts during the other placement" do
      let(:position) { "2:2:480" }
      let(:rhythmic_value) { :quarter }

      specify { expect(placement.send(:starts_during?, other_placement)).to be_truthy }
      specify { expect(placement.send(:ends_during?, other_placement)).to be_falsey }
      specify { expect(placement.send(:wraps?, other_placement)).to be_falsey }

      it { is_expected.to be_during(other_placement) }
    end

    context "when it starts after and ends before the other placement" do
      let(:position) { "2:2:240" }
      let(:rhythmic_value) { :sixteenth }

      specify { expect(placement.send(:starts_during?, other_placement)).to be_truthy }
      specify { expect(placement.send(:ends_during?, other_placement)).to be_truthy }
      specify { expect(placement.send(:wraps?, other_placement)).to be_falsey }

      it { is_expected.to be_during(other_placement) }
    end

    context "when it starts before and ends after the other placement" do
      let(:position) { "2:1:000" }
      let(:rhythmic_value) { :whole }

      specify { expect(placement.send(:starts_during?, other_placement)).to be_falsey }
      specify { expect(placement.send(:ends_during?, other_placement)).to be_falsey }
      specify { expect(placement.send(:wraps?, other_placement)).to be_truthy }

      it { is_expected.to be_during(other_placement) }
    end

    context "when it ends during the other placement" do
      let(:position) { "2:1:480" }
      let(:rhythmic_value) { :quarter }

      specify { expect(placement.send(:starts_during?, other_placement)).to be_falsey }
      specify { expect(placement.send(:ends_during?, other_placement)).to be_truthy }
      specify { expect(placement.send(:wraps?, other_placement)).to be_falsey }

      it { is_expected.to be_during(other_placement) }
    end

    context "when it starts at the end of the other placement" do
      let(:position) { "2:3" }
      let(:rhythmic_value) { :quarter }

      specify { expect(placement.send(:starts_during?, other_placement)).to be_falsey }
      specify { expect(placement.send(:ends_during?, other_placement)).to be_falsey }
      specify { expect(placement.send(:wraps?, other_placement)).to be_falsey }

      it { is_expected.not_to be_during(other_placement) }
    end
  end

  describe "#to_h" do
    it "serializes a pitched note with string keys and values" do
      expect(placement.to_h).to eq(
        "position" => "2:2:240",
        "rhythmic_value" => "eighth",
        "sounds" => ["F♯4"]
      )
    end

    context "when the placement is a rest" do
      let(:pitch) { nil }

      it "serializes an empty sounds array" do
        expect(placement.to_h["sounds"]).to eq []
      end
    end

    context "when the placement is an unpitched sound on an instrument" do
      let(:pitch) { HeadMusic::Rudiment::UnpitchedSound.get("snare drum") }

      it "serializes the sound as an unpitched hash" do
        expect(placement.to_h["sounds"]).to eq [{"unpitched" => "snare_drum"}]
      end
    end

    context "when the placement is the generic unpitched sound" do
      let(:pitch) { HeadMusic::Rudiment::UnpitchedSound.get }

      it "serializes the sound with a nil name" do
        expect(placement.to_h["sounds"]).to eq [{"unpitched" => nil}]
      end
    end

    context "when the placement mixes a pitch and an unpitched sound" do
      let(:pitch) { ["C4", HeadMusic::Rudiment::UnpitchedSound.get("snare drum")] }

      it "serializes each sound in its own shape" do
        expect(placement.to_h["sounds"]).to eq ["C4", {"unpitched" => "snare_drum"}]
      end
    end

    context "when the position has a tick offset" do
      let(:position) { "1:1:480" }

      it "preserves the exact position string" do
        expect(placement.to_h["position"]).to eq "1:1:480"
      end
    end

    context "with beam_break_before flags" do
      it "omits the key when the flag is nil" do
        expect(placement.to_h).not_to have_key("beam_break_before")
      end

      it "includes the key when the flag is true" do
        placement.beam_break_before = true
        expect(placement.to_h["beam_break_before"]).to be true
      end

      it "includes the key when the flag is false" do
        placement.beam_break_before = false
        expect(placement.to_h["beam_break_before"]).to be false
      end
    end

    context "with syllables" do
      it "omits the key when there are none" do
        expect(placement.to_h).not_to have_key("syllables")
      end

      it "serializes syllables in verse order" do
        placement.sing("peace", verse: 2)
        placement.sing("glo", verse: 1, hyphen_after: true)
        expect(placement.to_h["syllables"]).to eq(
          [{"text" => "glo", "hyphen_after" => true}, {"text" => "peace", "verse" => 2}]
        )
      end
    end
  end

  describe "sung text" do
    it "carries no syllables by default" do
      expect(placement).not_to be_sung
      expect(placement.syllables).to eq({})
    end

    it "assigns a syllable for the default verse" do
      placement.sing("la")
      expect(placement).to be_sung
      expect(placement.syllable).to eq HeadMusic::Content::Syllable.new("la")
    end

    it "returns self from #sing so calls chain" do
      expect(placement.sing("la")).to be placement
    end

    it "holds at most one syllable per verse across multiple verses" do
      placement.sing("glo", hyphen_after: true).sing("peace", verse: 2)
      expect(placement.syllable(1).text).to eq "glo"
      expect(placement.syllable(2).text).to eq "peace"
    end

    it "replaces the syllable when the same verse is sung again" do
      placement.sing("la").sing("dee")
      expect(placement.syllable.text).to eq "dee"
      expect(placement.syllables.length).to eq 1
    end

    it "keys by the coerced verse so a string verse is found by its integer" do
      placement.sing("la", verse: "2")
      expect(placement.syllable(2).text).to eq "la"
      expect(placement.syllables.keys).to eq [2]
    end

    it "sorts mixed integer- and string-supplied verses without raising" do
      placement.sing("one").sing("two", verse: "2")
      expect(placement.to_h["syllables"].map { |syllable| syllable["text"] }).to eq %w[one two]
    end

    context "when two placements at the same position are merged" do
      it "keeps the existing placement's syllables" do
        placement.sing("keep")
        other = described_class.new(voice, position, rhythmic_value, HeadMusic::Rudiment::Pitch.get("A4"))
        other.sing("drop")
        placement.merge(other)
        expect(placement.syllable.text).to eq "keep"
      end
    end
  end

  describe "chords" do
    context "when given a single bare pitch" do
      it { is_expected.not_to be_chord }
      it { is_expected.to be_note }

      it "wraps the pitch in a frozen single-element sounds array" do
        expect(placement.pitches.map(&:to_s)).to eq ["F♯4"]
        expect(placement.sounds).to be_frozen
      end
    end

    context "when given an array of pitches" do
      let(:pitch) { %w[G4 C4 E4] }

      it { is_expected.to be_chord }
      it { is_expected.not_to be_note }
      it { is_expected.not_to be_rest }

      it "preserves the order of the given pitches" do
        expect(placement.pitches.map(&:to_s)).to eq %w[G4 C4 E4]
      end

      it "freezes the sounds array" do
        expect(placement.sounds).to be_frozen
      end

      it "derives the pitch from the highest chord tone" do
        expect(placement.pitch.to_s).to eq "G4"
      end

      it "serializes the pitches in order" do
        expect(placement.to_h).to eq(
          "position" => "2:2:240",
          "rhythmic_value" => "eighth",
          "sounds" => %w[G4 C4 E4]
        )
      end

      it "joins the pitches with spaces in to_s" do
        expect(placement.to_s).to eq "eighth G4 C4 E4 at 2:2:240"
      end
    end

    context "when chord tones tie enharmonically" do
      let(:pitch) { %w[B♭4 A♯4] }

      it "derives the first-listed pitch of the tie" do
        expect(placement.pitch.to_s).to eq "B♭4"
      end
    end

    context "when given a single-element array" do
      let(:pitch) { ["F#4"] }
      let(:bare_placement) { described_class.new(voice, position, rhythmic_value, "F#4") }

      it { is_expected.not_to be_chord }
      it { is_expected.to be_note }

      it "behaves identically to a bare pitch" do
        expect(placement.to_h).to eq bare_placement.to_h
        expect(placement.to_s).to eq bare_placement.to_s
      end
    end

    context "when given an empty array" do
      let(:pitch) { [] }

      it { is_expected.to be_rest }
      it { is_expected.not_to be_note }
      it { is_expected.not_to be_chord }

      its(:pitch) { is_expected.to be_nil }

      it "serializes an empty sounds array" do
        expect(placement.to_h["sounds"]).to eq []
      end
    end

    context "when given a bare unparseable pitch" do
      let(:pitch) { "bogus" }

      it "raises ArgumentError" do
        expect { placement }.to raise_error(ArgumentError, 'unknown sound: "bogus"')
      end
    end

    context "when an array element is unparseable" do
      let(:pitch) { %w[C4 bogus G4] }

      it "raises ArgumentError naming the sound" do
        expect { placement }.to raise_error(ArgumentError, 'unknown sound: "bogus"')
      end
    end

    context "when an array element is nil" do
      let(:pitch) { [nil] }

      it "raises ArgumentError" do
        expect { placement }.to raise_error(ArgumentError, "unknown sound: nil")
      end
    end

    context "when given duplicate pitches" do
      let(:pitch) { %w[C4 C4] }

      it { is_expected.not_to be_chord }

      it "keeps one of each pitch" do
        expect(placement.pitches.map(&:to_s)).to eq %w[C4]
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
        expect(placement.pitch.to_s).to eq "C4"
      end

      it "exposes only the pitched subset as pitches" do
        expect(placement.pitches.map(&:to_s)).to eq ["C4"]
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
        described_class.new(voice, position, rhythmic_value, HeadMusic::Rudiment::UnpitchedSound.get("snare drum"))
      end

      it "deduplicates to one sound" do
        expect(placement.merge(other).sounds.length).to eq 1
      end
    end

    context "with an authored beam flag" do
      let(:other) { described_class.new(voice, position, rhythmic_value, "A4") }

      it "keeps the receiver's beam_break_before (chord members share one beam edge)" do
        placement.beam_break_before = true
        other.beam_break_before = false
        expect(placement.merge(other).beam_break_before).to be true
      end
    end
  end

  describe "#beam_break_before" do
    it "defaults to nil (meter-derived beaming)" do
      expect(placement.beam_break_before).to be_nil
    end

    it "is writable after construction" do
      placement.beam_break_before = true
      expect(placement.beam_break_before).to be true
    end
  end

  describe "#to_s" do
    context "with an unpitched sound alongside a pitch" do
      let(:pitch) { ["C4", HeadMusic::Rudiment::UnpitchedSound.get("snare drum")] }
      let(:rhythmic_value) { :quarter }
      let(:position) { "2:1" }

      it "brackets the unpitched name" do
        expect(placement.to_s).to eq "quarter C4 [snare drum] at 2:1:000"
      end
    end

    context "with the generic unpitched sound" do
      let(:pitch) { HeadMusic::Rudiment::UnpitchedSound.get }

      it "brackets the generic name" do
        expect(placement.to_s).to eq "eighth [unpitched] at 2:2:240"
      end
    end

    context "with pitches only" do
      let(:pitch) { %w[C4 E4] }

      it "is unchanged from the pitch-only format" do
        expect(placement.to_s).to eq "eighth C4 E4 at 2:2:240"
      end
    end
  end

  describe "sound resolution" do
    context "when given a bare unpitched instrument name" do
      let(:pitch) { "snare drum" }

      it "resolves to an unpitched sound" do
        expect(placement.sounds.map(&:name_key)).to eq [:snare_drum]
        expect(placement).to be_unpitched_note
      end
    end

    context "when given a bare pitched instrument name" do
      let(:pitch) { "violin" }

      it "raises ArgumentError naming both intents" do
        expect { placement }.to raise_error(
          ArgumentError,
          '"violin" is a pitched instrument; place a pitch such as "D4", ' \
          'or pass HeadMusic::Rudiment::UnpitchedSound.get("violin") for a percussive hit'
        )
      end
    end

    context "when given an unparseable pitch string" do
      let(:pitch) { "H4" }

      it "raises ArgumentError" do
        expect { placement }.to raise_error(ArgumentError, 'unknown sound: "H4"')
      end
    end

    context "when given a pitched instrument instance" do
      let(:pitch) { HeadMusic::Instruments::Instrument.get("violin") }

      it "resolves to an unpitched sound on that instrument" do
        expect(placement.sounds.map(&:name_key)).to eq [:violin]
        expect(placement).to be_unpitched_note
      end
    end

    context "when given an unpitched sound on a pitched instrument" do
      let(:pitch) { HeadMusic::Rudiment::UnpitchedSound.get("violin") }

      it "is accepted as-is" do
        expect(placement.sounds).to eq [pitch]
        expect(placement).not_to be_pitched
      end
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
