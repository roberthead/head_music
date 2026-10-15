require "spec_helper"

describe HeadMusic::Notation::MusicXML::InstrumentSounds do
  it "names a catalog instrument for every sound in its table" do
    unknown = described_class::NAME_KEYS_BY_SOUND.reject do |_sound, name_key|
      HeadMusic::Instruments::Instrument.get(name_key)&.name_key.to_s == name_key
    end
    expect(unknown).to be_empty
  end

  it "reads a sound as its instrument" do
    expect(described_class.instrument("wind.reed.clarinet.bflat").name_key).to eq :clarinet
  end

  it "reads a more general sound as the same instrument" do
    expect(described_class.instrument("keyboard.piano.grand").name_key).to eq :piano
  end

  it "answers nil for a sound outside the table" do
    expect(described_class.instrument("voice.male")).to be_nil
  end

  it "writes the first sound listed for an instrument" do
    expect(described_class.sound(HeadMusic::Instruments::Instrument.get("piano"))).to eq "keyboard.piano"
  end

  it "writes no sound for no instrument" do
    expect(described_class.sound(nil)).to be_nil
  end

  it "reads back every sound it writes as the instrument it was written for" do
    instruments = described_class::SOUNDS_BY_NAME_KEY.keys.map { |name_key| HeadMusic::Instruments::Instrument.get(name_key) }
    expect(instruments.map { |instrument| described_class.instrument(described_class.sound(instrument)) }).to eq instruments
  end
end
