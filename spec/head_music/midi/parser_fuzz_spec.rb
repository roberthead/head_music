require "spec_helper"

# Every truncation of a small file of many features, and every byte flipped
# by four masks, must parse as a flow or raise a MIDI parse error. Each
# variant runs the whole pipeline, about a second in all.
describe HeadMusic::MIDI::Parser do
  def source
    smf(
      [
        HeadMusic::MIDI::Text.new(0, :sequence_name, "Song"), time_signature(0, 3, 4), tempo(0, 500_000), key_signature(0, -1),
        time_signature(576, 2, 4), tempo(576, 400_000), key_signature(576, 2)
      ],
      [
        track_name("Voice"), program(0, 53), *midi_line([60, 62, 64, 65, 67, 69, 71, 72], 96),
        lyric(0, "la-"), lyric(96, "di"), program(576, 41), *midi_note(768, 48, 192)
      ],
      [*midi_note(0, 36, 48, channel: 9), *midi_note(96, 38, 48, channel: 9), *midi_note(96, 42, 48, channel: 9)]
    )
  end

  def outcomes(variants)
    variants.each_with_object(Hash.new(0)) do |(label, variant), tally|
      HeadMusic::MIDI.parse(variant)
      tally[:parsed] += 1
    rescue HeadMusic::MIDI::ParseError
      tally[:refused] += 1
    rescue => error
      tally[[label, error.class, error.message]] += 1
    end
  end

  def flips(bytes, mask)
    (0...bytes.bytesize).map do |index|
      variant = bytes.dup
      variant.setbyte(index, variant.getbyte(index) ^ mask)
      [index, variant]
    end
  end

  it "parses the source's parts, timeline and lyrics" do
    flow = HeadMusic::MIDI.parse(source)
    expect([flow.parts.length, flow.meter_changes.keys, flow.voices.first.note_events.first.syllables.length]).to eq [2, [3], 1]
  end

  it "parses or refuses every truncation" do
    bytes = source
    tally = outcomes((0...bytes.bytesize).map { |length| [length, bytes.byteslice(0, length)] })
    expect(tally.keys).to contain_exactly(:refused)
  end

  [0x01, 0x10, 0x80, 0xFF].each do |mask|
    it "parses or refuses every byte XORed with 0x#{format("%02X", mask)}" do
      expect(outcomes(flips(source, mask)).keys - %i[parsed refused]).to eq []
    end
  end
end
