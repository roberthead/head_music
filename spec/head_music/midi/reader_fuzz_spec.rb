require "spec_helper"

# Every truncation of a rendered file, and every byte flipped by three masks,
# must read as a sequence of values in range or raise a MIDI parse error.
describe HeadMusic::MIDI::Reader do
  bytes = HeadMusic::MIDI.render(HeadMusic::Notation::Kern.parse(File.read(File.expand_path("../../fixtures/notation/kern/satb_chorale.krn", __dir__))))

  def in_range?(event)
    case event
    when HeadMusic::MIDI::Tempo then event.microseconds_per_quarter.positive?
    when HeadMusic::MIDI::TimeSignature then event.numerator.positive? && [1, 2, 4, 8, 16, 32, 64].include?(event.denominator)
    when HeadMusic::MIDI::KeySignature then event.fifths.between?(-7, 7) && [true, false].include?(event.minor)
    when HeadMusic::MIDI::Text then event.text.encoding == Encoding::UTF_8 && event.text.valid_encoding? && !event.text.include?("\0")
    else true
    end
  end

  def problems(sequence)
    [
      ("format #{sequence.format}" unless [0, 1].include?(sequence.format)),
      ("division #{sequence.division}" unless sequence.division.between?(1, 0x7FFF)),
      *sequence.tracks.flat_map(&:events).reject { |event| in_range?(event) }.map(&:inspect),
      *sequence.notes.reject { |note| note.off >= note.on && sequence.tracks[note.track] }.map(&:inspect)
    ].compact
  end

  def outcomes(variants)
    variants.each_with_object(Hash.new(0)) do |(label, variant), tally|
      found = problems(described_class.new(variant).read)
      tally[found.empty? ? :read : [label, found]] += 1
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

  it "decodes a multi-track fixture" do
    sequence = described_class.new(bytes).read
    expect([sequence.tracks.length, problems(sequence)]).to eq [5, []]
  end

  it "reads or refuses every truncation" do
    tally = outcomes((0...bytes.bytesize).map { |length| [length, bytes.byteslice(0, length)] })
    expect(tally.keys).to contain_exactly(:refused)
  end

  [0x01, 0x80, 0xFF].each do |mask|
    it "reads or refuses every byte XORed with 0x#{format("%02X", mask)}" do
      expect(outcomes(flips(bytes, mask)).keys).to contain_exactly(:read, :refused)
    end
  end
end
