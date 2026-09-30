require "spec_helper"

describe HeadMusic::Notation::LilyPond::BarMarkReader do
  subject(:reader) { described_class.new(cursor) }

  let(:cursor) { HeadMusic::Notation::LilyPond::TokenCursor.new(HeadMusic::Notation::LilyPond::Lexer.new(source).tokens) }
  let(:stream) { HeadMusic::Notation::LilyPond::VoiceStream.new }

  def marks(count = 1)
    count.times { reader.read(stream) }
    stream.finish.events.map { |event| event.bar_mark.to_h.values }
  end

  describe ".letters" do
    it "follows LilyPond's rehearsal letters, which skip I and go on to AA" do
      expect([1, 8, 9, 25, 26, 27, 50, 51].map { |number| described_class.letters(number) })
        .to eq %w[A H J Z AA AB AZ BA]
    end
  end

  {
    %(\\bar "||") => [:barline, :double],
    %(\\bar "|.") => [:barline, :final],
    %(\\bar "!") => [:barline, :dashed],
    %(\\bar ";") => [:barline, :dotted],
    "\\section" => [:barline, :double],
    %(\\mark "Verse") => [:rehearsal_mark, "Verse"],
    %(\\sectionLabel "Chorus") => [:rehearsal_mark, "Chorus"],
    "\\mark 3" => [:rehearsal_mark, "C"],
    "\\segnoMark 1" => [:segno, true],
    "\\segnoMark \\default" => [:segno, true],
    "\\codaMark 2" => [:coda, true],
    "\\fine" => [:fine, true],
    %(\\jump "To Coda") => [:to_coda, true],
    %(\\jump "D.S. al Coda") => [:jump, HeadMusic::Content::Jump.new(:dal_segno, to: :coda)],
    %(\\jump "D.C. al Fine") => [:jump, HeadMusic::Content::Jump.new(:da_capo, to: :fine)],
    %(\\textEndMark "Fine") => [:fine, true],
    %(\\textEndMark "To Coda") => [:to_coda, true]
  }.each do |text, mark|
    context "with #{text}" do
      let(:source) { "#{text} c4" }

      it "marks the bar with #{mark.inspect}" do
        expect(marks).to eq [mark]
      end

      it "consumes the mark and nothing after it" do
        reader.read(stream)
        expect(cursor.peek.lexeme).to eq "c4"
      end
    end
  end

  context "with a run of default marks" do
    let(:source) { "\\mark \\default \\mark \\default \\mark 8 \\mark \\default" }

    it "counts on from the last mark, as LilyPond does" do
      expect(marks(4).map(&:last)).to eq %w[A B H J]
    end
  end

  context "with a bar type the model cannot hold" do
    let(:source) { %(\\bar ":|." \\bar ".|:" \\bar "|" c4) }

    it "reads it and drops it" do
      expect(marks(3)).to be_empty
      expect(cursor.peek.lexeme).to eq "c4"
    end
  end

  context "with markup the model cannot hold" do
    let(:source) do
      %(\\mark \\markup { \\bold "A" } \\jump \\markup \\italic "Fine" \\sectionLabel \\markup "Trio" \\textEndMark \\markup { x } c4)
    end

    it "skips each markup" do
      expect(marks(4)).to be_empty
      expect(cursor.peek.lexeme).to eq "c4"
    end
  end

  context "with navigation text it does not recognize" do
    let(:source) { %(\\jump "Da capo senza replica" \\textEndMark "rit." c4) }

    it "reads it and drops it" do
      expect(marks(2)).to be_empty
    end
  end

  context "without a stream, as in a Dynamics context" do
    let(:source) { "\\mark \\default \\fine c4" }

    it "reads the marks for their syntax alone" do
      2.times { reader.read }
      expect(cursor.peek.lexeme).to eq "c4"
    end
  end

  {
    "\\bar c4" => /\\bar expects a quoted bar type/,
    "\\mark c4" => /\\mark expects \\default, a number, or a string/,
    "\\mark \\fine" => /\\mark expects \\default, a number, or a string/,
    "\\segnoMark c4" => /\\segnoMark expects \\default or a number/,
    "\\codaMark 0" => /\\codaMark expects \\default or a number/,
    "\\jump 3" => /\\jump expects a quoted instruction/,
    "\\sectionLabel 3" => /\\sectionLabel expects a quoted label/,
    "\\mark \\markup 3" => /\\markup expects a string or a block/
  }.each do |text, message|
    context "with #{text}" do
      let(:source) { text }

      it "raises a parse error" do
        expect { reader.read(stream) }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, message)
      end
    end
  end
end
