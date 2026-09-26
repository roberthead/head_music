require "spec_helper"

describe HeadMusic::Notation::LilyPond::MarkReader do
  def cursor_for(source)
    HeadMusic::Notation::LilyPond::TokenCursor.new(HeadMusic::Notation::LilyPond::Lexer.new(source).tokens)
  end

  def marks(source)
    described_class.new(cursor_for(source)).read.to_h
  end

  def none
    {articulations: [], ornaments: [], note_dynamic: nil, level: nil}
  end

  describe "articulation shorthands" do
    {"-." => "staccato", "-!" => "staccatissimo", "->" => "accent", "--" => "tenuto", "-^" => "marcato"}.each do |source, key|
      it "reads #{source} as #{key}" do
        expect(marks(source)[:articulations]).to eq [key]
      end
    end

    %w[^. _. ^> _-].each do |source|
      it "reads #{source} whatever its direction" do
        expect(marks(source)[:articulations].length).to eq 1
      end
    end
  end

  describe "commands" do
    {
      "\\staccato" => [:articulations, ["staccato"]], "\\staccatissimo" => [:articulations, ["staccatissimo"]],
      "\\accent" => [:articulations, ["accent"]], "\\tenuto" => [:articulations, ["tenuto"]],
      "\\marcato" => [:articulations, ["marcato"]],
      "\\trill" => [:ornaments, ["trill"]], "\\mordent" => [:ornaments, ["mordent"]],
      "\\prall" => [:ornaments, ["inverted_mordent"]], "\\turn" => [:ornaments, ["turn"]],
      "\\sf" => [:note_dynamic, "sf"], "\\sfz" => [:note_dynamic, "sfz"],
      "\\rfz" => [:note_dynamic, "rfz"], "\\fp" => [:note_dynamic, "fp"]
    }.each do |source, (field, value)|
      it "reads #{source}" do
        expect(marks(source)[field]).to eq value
      end
    end

    %w[ppp pp p mp mf f ff fff].each do |level|
      it "reads \\#{level} as a level" do
        expect(marks("\\#{level}")[:level]).to eq level
      end
    end

    it "reads a command after a direction sign" do
      expect(marks("^\\trill _\\p")).to include(ornaments: ["trill"], level: "p")
    end
  end

  describe "marks the catalogs do not hold" do
    %w[-_ -+ \\fermata \\upbow \\downbow \\breathe \\portato \\stopped \\sfp \\spp \\sff \\fz \\pppp \\ffff ^\\fermata].each do |source|
      it "consumes and drops #{source}" do
        cursor = cursor_for("#{source} c'4")
        expect(described_class.new(cursor).read.to_h).to eq none
        expect(cursor.peek.type).to eq :note
      end
    end
  end

  describe "a run of marks" do
    it "reads every mark in order until something else" do
      cursor = cursor_for("-.\\trill->\\sfz\\p c'4")
      expect(described_class.new(cursor).read.to_h).to eq(articulations: %w[staccato accent], ornaments: ["trill"], note_dynamic: "sfz", level: "p")
      expect(cursor.peek.type).to eq :note
    end

    it "keeps a repeated articulation once" do
      expect(marks("-. \\staccato")[:articulations]).to eq ["staccato"]
    end

    it "adds to the marks it is given" do
      earlier = described_class::Marks.new(articulations: ["tenuto"])
      expect(described_class.new(cursor_for("-.")).read(earlier).articulations).to eq %w[tenuto staccato]
    end

    it "raises for two levels on one note" do
      expect { marks("\\p \\f") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /only one dynamic level/)
    end

    it "raises for two sforzandos on one note" do
      expect { marks("\\sf \\sfz") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /only one sforzando/)
    end
  end

  describe "what is not a mark" do
    ["-1", "!", "?", "-\\markup", "\\key", "( ", "~"].each do |source|
      it "leaves #{source.strip} unread" do
        cursor = cursor_for(source)
        expect(described_class.new(cursor).read.to_h).to eq none
        expect(cursor.peek).not_to be_nil
      end
    end
  end

  describe described_class::Marks do
    it "merges a tied note's marks, keeping the first dynamics" do
      first = described_class.new(articulations: ["staccato"], note_dynamic: "sf", level: "p")
      second = described_class.new(articulations: %w[staccato accent], ornaments: ["trill"], note_dynamic: "sfz", level: "f")
      expect(first.merge(second).to_h).to eq(articulations: %w[staccato accent], ornaments: ["trill"], note_dynamic: "sf", level: "p")
    end
  end
end
