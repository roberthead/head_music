require "spec_helper"

describe HeadMusic::MIDI::Budget do
  let(:division) { 96 }

  def note(on, off, key: 60, channel: 0)
    [
      HeadMusic::MIDI::NoteOn.new(tick: on, channel: channel, key: key, velocity: 80),
      HeadMusic::MIDI::NoteOff.new(tick: off, channel: channel, key: key)
    ]
  end

  def smf(*tracks)
    HeadMusic::MIDI::SMF.file(division: division, tracks: tracks)
  end

  def budget(bytes)
    described_class.new(HeadMusic::MIDI::Reader.new(bytes).read)
  end

  def parse(bytes)
    HeadMusic::MIDI.parse(bytes)
  end

  # Each sixteenth releases one more note, so no two make a chord.
  def stacked(count, channel:, last_release: nil)
    Array.new(count) { |index| note(0, (index == count - 1 && last_release) || (index + 1) * division / 4, key: 40 + index, channel: channel) }.flatten
  end

  shared_examples "a budget refusal" do |error_class, message|
    it "raises #{error_class.name.split("::").last} before any flow is built" do
      allow(HeadMusic::Content::Flow).to receive(:new).and_call_original
      expect { parse(bytes) }.to raise_error(error_class, message)
      expect(HeadMusic::Content::Flow).not_to have_received(:new)
    end
  end

  context "with more than MAX_NOTES notes" do
    let(:bytes) { smf(Array.new(described_class::MAX_NOTES + 1) { |index| note(index, index + 1) }.flatten) }

    it_behaves_like "a budget refusal", HeadMusic::MIDI::ParseError, "the file needs 200001 notes, more than 200000"
  end

  context "with more than MAX_PARTS parts" do
    let(:bytes) { smf(*Array.new(described_class::MAX_PARTS + 1) { note(0, division) }) }

    it_behaves_like "a budget refusal", HeadMusic::MIDI::ParseError, "the file needs 129 parts, more than 128"
  end

  context "with more than MAX_BARS bars" do
    let(:bytes) { smf([HeadMusic::MIDI::TimeSignature.new(0, 1, 4, 24), *note(0, (described_class::MAX_BARS + 1) * division)]) }

    it_behaves_like "a budget refusal", HeadMusic::MIDI::ParseError, "the file needs 10001 bars, more than 10000"
  end

  context "with more than MAX_VOICES_PER_PART voices in a part" do
    let(:bytes) { smf(note(0, division), stacked(described_class::MAX_VOICES_PER_PART + 1, channel: 2)) }

    it_behaves_like "a budget refusal", HeadMusic::MIDI::UnsupportedFeatureError, "track 2, channel 3 needs more than 64 voices"
  end

  it "reads a part of exactly MAX_VOICES_PER_PART voices" do
    expect(parse(smf(stacked(described_class::MAX_VOICES_PER_PART, channel: 0))).voices.length).to eq 64
  end

  context "with more than MAX_VOICE_BARS voice-bars" do
    let(:end_tick) { described_class::MAX_BARS * division * 4 }
    let(:bytes) { smf(stacked(51, channel: 0, last_release: end_tick), stacked(51, channel: 1)) }

    it_behaves_like "a budget refusal", HeadMusic::MIDI::ParseError, "102 voices across 10000 bars are more than 1000000 voice-bars"
  end

  describe "#part_count" do
    it "counts each channel of a track as a part" do
      expect(budget(smf([*note(0, division), *note(0, division, channel: 9)])).part_count).to eq 2
    end

    it "counts a later format 1 track that names a part but plays no note" do
      bytes = smf(note(0, division), [HeadMusic::MIDI::Text.new(0, :track_name, "Tacet")], [HeadMusic::MIDI::ProgramChange.new(0, 1, 41)])
      expect(budget(bytes).part_count).to eq 3
    end

    it "does not count a conductor track as a part" do
      bytes = smf([HeadMusic::MIDI::Text.new(0, :track_name, "Song"), HeadMusic::MIDI::Tempo.new(0, 500_000)], note(0, division))
      expect(budget(bytes).part_count).to eq 1
    end
  end

  describe "#bar_count" do
    it "counts 4/4 bars when the file has no time signature" do
      expect(budget(smf(note(0, 9 * division))).bar_count).to eq 3
    end

    it "counts the bars of each meter in turn, a pickup among them" do
      meters = [HeadMusic::MIDI::TimeSignature.new(0, 1, 4, 24), HeadMusic::MIDI::TimeSignature.new(division, 3, 4, 24)]
      expect(budget(smf([*meters, *note(0, 7 * division)])).bar_count).to eq 3
    end

    it "takes the last of several time signatures at one tick" do
      events = [HeadMusic::MIDI::TimeSignature.new(0, 2, 4, 24), HeadMusic::MIDI::TimeSignature.new(0, 4, 4, 24), *note(0, 8 * division)]
      expect(budget(smf(events)).bar_count).to eq 2
    end

    it "counts a bar for a file whose events all sit at tick 0" do
      expect(budget(smf(note(0, 0))).bar_count).to eq 1
    end
  end
end
