require "spec_helper"

describe HeadMusic::Notation::Kern::DynamicReader do
  def row(header, fields)
    records = HeadMusic::Notation::Kern::Lexer.new("#{header.join("\t")}\n#{fields.join("\t")}\n#{header.map { "*-" }.join("\t")}").records
    HeadMusic::Notation::Kern::Document.new(records).rows.first
  end

  def dynamics(field)
    described_class.new(row(%w[**kern **dynam], ["4c", field])).dynamics
  end

  def keys(field)
    dynamics(field).map { |reading| reading.dynamic.name_key }
  end

  %w[ppp pp p mp mf f ff fff sf sfz rfz fp].each do |key|
    it "reads #{key}" do
      expect(keys(key)).to eq [key]
    end
  end

  %w[. < > ( ) [ ] <( >) pppp ffff fz sfp sffz cresc. dim. 3].each do |field|
    it "skips #{field}" do
      expect(keys(field)).to eq []
    end
  end

  it "reads a level beside a hairpin mark" do
    expect(keys("p<")).to eq ["p"]
  end

  it "reads each of several dynamics in one field" do
    expect(keys("sf p")).to eq %w[sf p]
  end

  it "belongs to the nearest kern spine on its left" do
    reading = described_class.new(row(%w[**kern **kern **dynam], %w[4c 4e f])).dynamics.first
    expect([reading.track.origin, reading.column]).to eq [1, 3]
  end

  it "skips a **dynam spine with no kern spine on its left" do
    expect(described_class.new(row(%w[**dynam **kern], %w[p 4c])).dynamics).to eq []
  end

  describe "hairpin marks" do
    def marks(field)
      described_class.new(row(%w[**kern **dynam], ["4c", field])).hairpin_marks.map { |mark| [mark.role, mark.kind] }
    end

    {
      "<" => [[:open, :crescendo]],
      ">" => [[:open, :diminuendo]],
      "o<" => [[:open, :crescendo]],
      "[" => [[:close, :crescendo]],
      "]" => [[:close, :diminuendo]],
      "[[" => [[:close_at_row_end, :crescendo]],
      "]]" => [[:close_at_row_end, :diminuendo]],
      "(" => [],
      ")" => [],
      "." => [],
      "3" => []
    }.each do |field, expected|
      it "reads #{field}" do
        expect(marks(field)).to eq expected
      end
    end

    it "reads a level or accent as interrupting an open hairpin" do
      expect([marks("p"), marks("sf")]).to eq [[[:interrupt, nil]], [[:interrupt, nil]]]
    end

    it "reads text the catalog does not hold as interrupting too" do
      expect([marks("cresc."), marks("pppp")]).to eq [[[:interrupt, nil]], [[:interrupt, nil]]]
    end

    it "orders a field's closes, then its level, then its opens, whatever order they are written in" do
      expect([marks("]p<"), marks("<p]"), marks("[mf>")]).to eq [
        [[:close, :diminuendo], [:interrupt, nil], [:open, :crescendo]],
        [[:interrupt, nil], [:open, :crescendo], [:close_at_row_end, :diminuendo]],
        [[:close, :crescendo], [:interrupt, nil], [:open, :diminuendo]]
      ]
    end

    it "reads a level written before its close as closing first" do
      expect(marks("f[")).to eq [[:close, :crescendo], [:interrupt, nil]]
    end

    it "reads a close written after an open in one token as ending where the row ends" do
      expect([marks("[<"), marks("<[")]).to eq [[[:close, :crescendo], [:open, :crescendo]], [[:open, :crescendo], [:close_at_row_end, :crescendo]]]
    end

    it "still reads the level beside the marks" do
      expect([keys("]p<"), keys("[mf<"), keys("f["), keys("o<")]).to eq [["p"], ["mf"], ["f"], []]
    end

    it "gives each mark its **dynam spine and the kern track on its left" do
      mark = described_class.new(row(%w[**kern **kern **dynam], %w[4c 4e <])).hairpin_marks.first
      expect([mark.spine.origin, mark.track.origin]).to eq [2, 1]
    end

    it "skips marks in a **dynam spine with no kern spine on its left" do
      expect(described_class.new(row(%w[**dynam **kern], %w[< 4c])).hairpin_marks).to eq []
    end
  end
end
