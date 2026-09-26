require "spec_helper"

describe HeadMusic::Notation::ABC::DecorationMapper do
  describe ".classify" do
    {
      "." => [:articulation, "staccato"],
      "!staccato!" => [:articulation, "staccato"],
      "!wedge!" => [:articulation, "staccatissimo"],
      "L" => [:articulation, "accent"],
      "!accent!" => [:articulation, "accent"],
      "!>!" => [:articulation, "accent"],
      "!emphasis!" => [:articulation, "accent"],
      "!tenuto!" => [:articulation, "tenuto"],
      "!marcato!" => [:articulation, "marcato"],
      "!^!" => [:articulation, "marcato"],
      "T" => [:ornament, "trill"],
      "!trill!" => [:ornament, "trill"],
      "+trill+" => [:ornament, "trill"],
      "M" => [:ornament, "mordent"],
      "!lowermordent!" => [:ornament, "mordent"],
      "!mordent!" => [:ornament, "mordent"],
      "P" => [:ornament, "inverted_mordent"],
      "!uppermordent!" => [:ornament, "inverted_mordent"],
      "!pralltriller!" => [:ornament, "inverted_mordent"],
      "!turn!" => [:ornament, "turn"],
      "!sf!" => [:note_dynamic, "sf"],
      "!sfz!" => [:note_dynamic, "sfz"],
      "!rfz!" => [:note_dynamic, "rfz"],
      "!fp!" => [:note_dynamic, "fp"],
      "!ppp!" => [:level, "ppp"],
      "!pp!" => [:level, "pp"],
      "!p!" => [:level, "p"],
      "!mp!" => [:level, "mp"],
      "!mf!" => [:level, "mf"],
      "!f!" => [:level, "f"],
      "!ff!" => [:level, "ff"],
      "!fff!" => [:level, "fff"]
    }.each do |lexeme, (kind, key)|
      it "reads #{lexeme} as the #{kind} #{key}" do
        expect(described_class.classify(lexeme)).to eq(kind: kind, key: key)
      end
    end

    %w[
      ~ H O S u v !roll! !turnx! !invertedturn! !invertedturnx! !arpeggio! !trill(! !trill)!
      !fermata! !invertedfermata! !breath! !upbow! !downbow! !open! !thumb! !snap! !slide! !+! !plus!
      !0! !1! !2! !3! !4! !5! !trem1! !trem2! !trem3! !trem4! !pppp! !ffff!
      !crescendo(! !crescendo)! !diminuendo(! !diminuendo)! !<(! !<)! !>(! !>)!
      !segno! !coda! !D.S.! !D.C.! !dacoda! !dacapo! !fine!
      !shortphrase! !mediumphrase! !longphrase! !editorial! !courtesy! +fermata+
    ].each do |lexeme|
      it "recognizes #{lexeme} and drops it" do
        expect(described_class.classify(lexeme)).to eq(kind: :dropped, key: nil)
      end
    end

    it "does not recognize an unknown decoration" do
      expect(described_class.classify("!bogus!")).to be_nil
    end

    it "does not recognize a decoration name without its delimiters" do
      expect(described_class.classify("trill")).to be_nil
    end
  end
end
