require "spec_helper"

describe HeadMusic::MIDI::VoiceSeparator do
  let(:part_key) { HeadMusic::MIDI::PartKey.new(track: 0, channel: 0) }

  def note(key, onset, release)
    HeadMusic::MIDI::QuantizedNote.new(part_key: part_key, key: key, onset: Rational(onset), release: Rational(release))
  end

  def keys_by_voice(voices)
    voices.map { |voice| voice.map(&:keys) }
  end

  describe "a chord against overlapping lines" do
    subject(:voices) { described_class.new(notes).voices }

    let(:notes) do
      [
        note(72, 0, "1/2"), note(74, "3/4", 1),
        note(60, 0, "1/4"),
        note(64, "1/2", "3/4"), note(57, "1/2", "3/4"), note(57, "1/2", "3/4")
      ]
    end

    it "merges notes that start and end together into one chord with sorted, unique keys" do
      expect(voices.flatten.map(&:keys)).to include([57, 64])
    end

    it "deals the chord to the free voice nearest its mean key" do
      expect(keys_by_voice(voices)).to eq [[[72], [74]], [[60], [57, 64]]]
    end

    it "keeps each voice's chords in onset order" do
      expect(voices.map { |voice| voice.map(&:onset) }).to eq [[0r, Rational(3, 4)], [0r, Rational(1, 2)]]
    end
  end

  describe "a voice that opens late" do
    subject(:voices) { described_class.new(notes).voices }

    let(:notes) do
      [note(72, 0, 1), note(60, "1/2", 1), note(62, 1, 2), note(71, "5/4", 2)]
    end

    it "opens a voice when none is free, then keeps each line in its own voice" do
      expect(keys_by_voice(voices)).to eq [[[72], [71]], [[60], [62]]]
    end

    it "starts the late voice at its first onset" do
      expect(voices.last.first.onset).to eq Rational(1, 2)
    end
  end

  describe "ties" do
    subject(:voices) { described_class.new(notes).voices }

    let(:notes) do
      [note(76, 0, "1/4"), note(64, 0, "3/8"), note(60, 0, "5/16"), note(62, "1/2", 1)]
    end

    it "go to the lower of two equally near voices, over a farther free voice" do
      expect(keys_by_voice(voices)).to eq [[[76]], [[64], [62]], [[60]]]
    end
  end

  describe "percussion" do
    let(:notes) { [note(36, 0, "1/8"), note(42, 0, "1/4"), note(38, 0, "1/16"), note(42, "1/4", "1/2")] }

    it "groups by onset alone, taking the longest release" do
      voices = described_class.new(notes, percussion: true).voices
      expect(voices.map { |voice| voice.map(&:to_h) }).to eq [[
        {onset: 0r, release: Rational(1, 4), keys: [36, 38, 42]},
        {onset: Rational(1, 4), release: Rational(1, 2), keys: [42]}
      ]]
    end

    it "is not how pitched notes group" do
      expect(described_class.new(notes).voices.length).to eq 3
    end
  end

  describe "the voice cap" do
    def stacked(count)
      Array.new(count) { |index| note(40 + index, 0, Rational(index + 1, 16)) }
    end

    it "allows 64 voices" do
      expect(described_class.new(stacked(64)).voices.length).to eq 64
    end

    it "refuses a 65th voice, naming the part" do
      expect { described_class.new(stacked(65)).voices }
        .to raise_error(HeadMusic::MIDI::UnsupportedFeatureError, "track 1, channel 1 needs more than 64 voices")
    end

    it "checks the cap before opening each voice" do
      allow(HeadMusic::MIDI::Budget).to receive(:check_voices!).and_call_original
      described_class.new(stacked(3)).voices
      [1, 2, 3].each do |count|
        expect(HeadMusic::MIDI::Budget).to have_received(:check_voices!).with(part_key, count).ordered
      end
    end
  end

  describe "determinism" do
    let(:notes) do
      [
        note(60, 0, "1/2"), note(60, 0, "1/4"), note(55, 0, "1/2"),
        note(67, "1/4", "1/2"), note(48, 0, 1), note(64, "1/2", 1), note(62, "1/2", 1)
      ]
    end

    let(:expected) { [[[60], [67], [62, 64]], [[55, 60]], [[48]]] }

    it "deals the same voices whatever order the notes arrive in" do
      notes.permutation.first(200).each do |order|
        expect(keys_by_voice(described_class.new(order).voices)).to eq expected
      end
    end
  end

  describe "cost" do
    let(:lines) { [84, 72, 60, 48] }
    let(:length) { 250 }
    let(:notes) do
      lines.each_with_index.flat_map do |key, line|
        Array.new(length) { |index| note(key + index % 3, Rational(index, 8) + Rational(line, 64), Rational(index + 1, 8) + Rational(line, 64)) }
      end
    end

    let(:calls) { [] }

    before do
      reads = calls
      counting = Class.new(described_class::Chord) do
        %i[onset release keys].each do |reader|
          define_method(reader) do
            reads << reader
            super()
          end
        end
      end
      stub_const("HeadMusic::MIDI::VoiceSeparator::Chord", counting)
    end

    it "keeps the lines apart" do
      expect(described_class.new(notes).voices.length).to eq lines.length
    end

    it "reads each chord a bounded number of times however long the voices grow" do
      described_class.new(notes).voices
      expect(calls.length).to be <= lines.length * length * (lines.length + 6)
    end
  end
end
