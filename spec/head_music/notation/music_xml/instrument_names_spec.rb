require "spec_helper"

describe HeadMusic::Notation::MusicXML::InstrumentNames do
  {
    "clarinet in C" => :clarinet_in_c,
    "C Clarinet" => :clarinet_in_c,
    "Eb Trumpet" => :trumpet_in_e_flat,
    "Trumpet in Bb" => :trumpet,
    "Clarinet in B♭" => :clarinet,
    "Horn in F" => :french_horn,
    "English Horn in F" => :cor_anglais,
    "Oboe d'amore in A" => :oboe_d_amore,
    "Trumpet in B-flat" => :trumpet,
    "Trumpet in B flat" => :trumpet,
    "Violin 1" => :violin,
    "Horn II" => :french_horn,
    "Flute 2." => :flute,
    "Klarinette" => :clarinet
  }.each do |name, name_key|
    it "reads #{name.inspect} as the #{name_key}" do
      expect(described_class.instrument(name).name_key).to eq name_key
    end
  end

  it "reads no instrument in a key the catalog's instrument is not in" do
    expect(described_class.instrument("Trumpet in G")).to be_nil
  end

  it "reads no instrument for a name that is no instrument's" do
    expect(described_class.instrument("SmartMusic SoftSynth")).to be_nil
  end

  it "reads no instrument for a blank name" do
    expect(described_class.instrument(" ")).to be_nil
  end

  it "reads no catalog instrument name as another" do
    misread = HeadMusic::Instruments::Instrument.all.reject { |instrument| described_class.instrument(instrument.name) == instrument }
    expect(misread.map(&:name_key)).to be_empty
  end
end
