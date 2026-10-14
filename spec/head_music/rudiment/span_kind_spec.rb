require "spec_helper"

describe HeadMusic::Rudiment::SpanKind do
  let(:voice) { HeadMusic::Content::Voice.new }
  let(:note) { voice.place("1:1", :quarter, "C4") }
  let(:rest) { voice.place("1:2", :quarter) }

  describe ".all" do
    it "lists the curves, then the hairpins" do
      expect(described_class.all.map(&:name_key)).to eq %w[slur phrase crescendo diminuendo]
    end
  end

  describe ".get" do
    it "finds the phrase mark by its LilyPond name" do
      expect(described_class.get(:phrasing_slur)).to be described_class.get(:phrase)
    end

    it "finds the diminuendo by its other names" do
      expect(%i[decrescendo decresc dim].map { |name| described_class.get(name) }.uniq).to eq [described_class.get(:diminuendo)]
    end

    it "finds the crescendo by its abbreviation" do
      expect(described_class.get(:cresc)).to be described_class.get(:crescendo)
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

    it "anchors a hairpin anywhere" do
      kind = described_class.get(:crescendo)
      expect([kind.anchors_on?(nil), kind.anchors_on?(rest), kind.anchors_on?(note)]).to eq [true, true, true]
    end
  end

  describe "#covers_last_note?" do
    it "covers a slur's last note" do
      expect(described_class.get(:slur).covers_last_note?).to be true
    end

    it "ends a hairpin at its end position" do
      expect(described_class.get(:diminuendo).covers_last_note?).to be false
    end
  end

  describe "#curve? and #hairpin?" do
    it "sorts each kind into one family" do
      expect(described_class.all.to_h { |kind| [kind.name_key, [kind.curve?, kind.hairpin?]] }).to eq(
        "slur" => [true, false], "phrase" => [true, false], "crescendo" => [false, true], "diminuendo" => [false, true]
      )
    end

    context "when a voice has a slur and a crescendo" do
      let(:flow) do
        HeadMusic::Notation::ABC.parse("X:1\nL:1/4\nM:4/4\nK:C\nC D E F|G4|\n").tap do |flow|
          flow.voices.first.add_span(:slur, from: "1:1", to: "1:3")
          flow.voices.first.add_span(:crescendo, from: "1:2", to: "2:1")
        end
      end

      {
        to_abc: ->(output) { output.lines.last.gsub(/![<>]\(!/, "").count("(") },
        to_lilypond: ->(output) { output.scan(/(?<!\\)\((?!\))/).length },
        to_kern: ->(output) { output.lines.grep_v(/^[*!]/).join.count("(") },
        to_musicxml: ->(output) { output.scan('<slur type="start"').length }
      }.each do |method, slur_count|
        it "writes only the slur as a curve with #{method}" do
          expect(slur_count.call(flow.public_send(method))).to eq 1
        end
      end
    end
  end

  describe "#held_by?" do
    it "is held by a voice" do
      expect(described_class.get(:slur).held_by?(:voice)).to be true
    end

    it "is not held by a part" do
      expect(described_class.get(:phrase).held_by?(:part)).to be false
    end

    it "holds a hairpin in a voice or a part" do
      expect(%i[voice part].map { |owner| described_class.get(:crescendo).held_by?(owner) }).to eq [true, true]
    end
  end

  describe "#name" do
    it "names the phrase mark" do
      expect(described_class.get(:phrase).name).to eq "phrase mark"
    end

    it "names the slur in German" do
      expect(described_class.get(:slur).name(locale_code: :de)).to eq "Bindebogen"
    end

    it "names the diminuendo in Russian" do
      expect(described_class.get(:diminuendo).name(locale_code: :ru)).to eq "диминуэндо"
    end
  end
end
