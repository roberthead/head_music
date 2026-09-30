require "spec_helper"

describe HeadMusic::Notation::LilyPond::BarMarkWriter do
  let(:bar) { HeadMusic::Content::Bar.new(nil) }

  describe ".opening_tokens" do
    it "writes nothing for an unmarked bar" do
      expect(described_class.opening_tokens(bar)).to eq []
    end

    it "writes the rehearsal mark and coda sign" do
      bar.rehearsal_mark = %(The "B" Section)
      bar.coda = true
      expect(described_class.opening_tokens(bar)).to eq [%(\\mark "The \\"B\\" Section"), "\\codaMark 1"]
    end

    context "with a segno and a coda sign on one bar" do
      before do
        bar.segno = true
        bar.coda = true
      end

      it "writes the coda sign as a text mark of its glyph, which LilyPond lets share the bar" do
        expect(described_class.opening_tokens(bar))
          .to eq ["\\segnoMark 1", %(\\textMark \\markup \\musicglyph "scripts.coda")]
      end

      it "writes the text mark in the lead voice only" do
        expect(described_class.opening_tokens(bar, lead: false)).to eq ["\\segnoMark 1"]
      end
    end
  end

  describe ".closing_tokens" do
    it "writes nothing for an unmarked bar before the last" do
      expect(described_class.closing_tokens(bar)).to eq []
    end

    it "closes the last bar with a final barline" do
      expect(described_class.closing_tokens(bar, last: true)).to eq [%(\\bar "|.")]
    end

    {double: "||", final: "|.", dashed: "!", dotted: ";"}.each do |style, bar_type|
      it "writes a #{style} barline as \\bar \"#{bar_type}\", even on the last bar" do
        bar.barline = style
        expect([described_class.closing_tokens(bar), described_class.closing_tokens(bar, last: true)])
          .to eq [[%(\\bar "#{bar_type}")]] * 2
      end
    end

    it "writes a Fine on the last bar as \\fine" do
      bar.fine = true
      expect(described_class.closing_tokens(bar, last: true)).to eq ["\\fine", %(\\bar "|.")]
    end

    it "writes a Fine before the last bar as text, since LilyPond warns of music after \\fine" do
      bar.fine = true
      expect(described_class.closing_tokens(bar)).to eq [%(\\textEndMark "Fine")]
    end

    it "writes a To Coda and a jump as \\jump" do
      bar.to_coda = true
      expect(described_class.closing_tokens(bar)).to eq [%(\\jump "To Coda")]
      bar.to_coda = false
      bar.jump = HeadMusic::Content::Jump.new(:dal_segno, to: :coda)
      expect(described_class.closing_tokens(bar)).to eq [%(\\jump "D.S. al Coda")]
    end

    it "writes a To Coda beside a jump as text, since LilyPond keeps one \\jump per bar" do
      bar.to_coda = true
      bar.jump = HeadMusic::Content::Jump.new(:da_capo)
      bar.barline = :double
      expect(described_class.closing_tokens(bar)).to eq [%(\\textEndMark "To Coda"), %(\\jump "D.C."), %(\\bar "||")]
    end

    it "leaves the text marks to the lead voice, since LilyPond prints one per voice" do
      bar.fine = true
      bar.to_coda = true
      bar.jump = HeadMusic::Content::Jump.new(:da_capo)
      expect(described_class.closing_tokens(bar, lead: false)).to eq [%(\\jump "D.C.")]
    end
  end
end
