require "spec_helper"

describe HeadMusic::Notation::MEI::StaffNumbering do
  subject(:numbering) { described_class.new(flow) }

  let(:flow) { LilyPondFixtures.piano_and_melody }

  describe "#entries" do
    it "numbers every staff through the score" do
      expect(numbering.entries.map { |entry| [entry.number, entry.part_number, entry.index_in_part] })
        .to eq [[1, 1, 0], [2, 1, 1], [3, 2, 0]]
    end
  end

  describe "#entries_of" do
    it "lists the staves of one part" do
      expect(numbering.entries_of(flow.parts.last).map(&:number)).to eq [3]
    end
  end

  describe "#part_number" do
    it "counts parts from 1" do
      expect(flow.parts.map { |part| numbering.part_number(part) }).to eq [1, 2]
    end
  end

  describe "#voice_number" do
    it "counts each part's voices from 1" do
      flow = HeadMusic::Content::Flow.new
      piano = flow.add_part
      2.times { piano.add_voice }
      flow.add_part.add_voice
      expect(flow.voices.map { |voice| described_class.new(flow).voice_number(voice) }).to eq [1, 2, 1]
    end
  end

  context "with a voice that crosses staves" do
    let(:flow) { LilyPondFixtures.cross_staff_piano }
    let(:left_hand) { flow.voices.last }

    it "finds the staff a voice is written on in each bar" do
      expect((1..4).map { |bar| numbering.entry(left_hand, bar).number }).to eq [2, 1, 1, 2]
    end

    it "lists the voices written on a staff in a bar" do
      expect(numbering.layer_voices(numbering.entries.first, 2)).to eq flow.voices
    end
  end
end
