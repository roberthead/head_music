require "spec_helper"

describe HeadMusic::Notation::MEI::LayerSigns do
  subject(:signs) { described_class.new }

  let(:bass_clef) { REXML::Document.new(%(<clef shape="F" line="4"/>)).root }
  let(:alto_clef) { REXML::Document.new(%(<clef shape="C" line="3"/>)).root }
  let(:key_sig) { REXML::Document.new(%(<keySig sig="2s"/>)).root }

  it "opens with the first clef before any entry" do
    signs.clef(bass_clef, 0)
    signs.clef(alto_clef, 0)
    expect(signs.opening_clef.name_key.to_sym).to eq :bass_clef
  end

  it "closes with a clef after the last entry" do
    signs.clef(alto_clef, 3)
    expect(signs.closing_clef(3).name_key.to_sym).to eq :alto_clef
  end

  it "skips a clef between entries" do
    signs.clef(alto_clef, 2)
    expect(signs.closing_clef(3)).to be_nil
  end

  it "opens with a key before any entry" do
    signs.key_sig(key_sig, 0)
    expect(signs.opening_key).not_to be_nil
  end

  it "raises for a key after an entry" do
    expect { signs.key_sig(key_sig, 1) }.to raise_error(HeadMusic::Notation::MEI::UnsupportedFeatureError)
  end
end
