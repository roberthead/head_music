require "spec_helper"

describe HeadMusic::Rudiment::SpanKind do
  let(:voice) { HeadMusic::Content::Voice.new }
  let(:note) { voice.place("1:1", :quarter, "C4") }
  let(:rest) { voice.place("1:2", :quarter) }

  describe ".all" do
    it "lists the slur and the phrase mark" do
      expect(described_class.all.map(&:name_key)).to eq %w[slur phrase]
    end
  end

  describe ".get" do
    it "finds the phrase mark by its LilyPond name" do
      expect(described_class.get(:phrasing_slur)).to be described_class.get(:phrase)
    end
  end

  describe "#anchors_on?" do
    it "anchors a slur on a note" do
      expect(described_class.get(:slur).anchors_on?(note)).to be true
    end

    it "does not anchor a slur on a rest" do
      expect(described_class.get(:slur).anchors_on?(rest)).to be false
    end

    it "anchors a phrase on a rest" do
      expect(described_class.get(:phrase).anchors_on?(rest)).to be true
    end

    it "anchors nothing where there is no voice event" do
      expect(described_class.get(:phrase).anchors_on?(nil)).to be false
    end
  end

  describe "#covers_last_note?" do
    it "covers a slur's last note" do
      expect(described_class.get(:slur).covers_last_note?).to be true
    end
  end

  describe "#held_by?" do
    it "is held by a voice" do
      expect(described_class.get(:slur).held_by?(:voice)).to be true
    end

    it "is not held by a part" do
      expect(described_class.get(:phrase).held_by?(:part)).to be false
    end
  end

  describe "#name" do
    it "names the phrase mark" do
      expect(described_class.get(:phrase).name).to eq "phrase mark"
    end

    it "names the slur in German" do
      expect(described_class.get(:slur).name(locale_code: :de)).to eq "Bindebogen"
    end
  end
end
