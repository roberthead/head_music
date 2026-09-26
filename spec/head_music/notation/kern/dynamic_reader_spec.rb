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
end
