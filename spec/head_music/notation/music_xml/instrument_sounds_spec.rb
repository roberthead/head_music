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

  it "reads the tenor banjo's sound as the tenor banjo, not the five-string" do
    expect(described_class.instrument("pluck.banjo.tenor").name_key).to eq :tenor_banjo
  end

  it "writes the tenor banjo's sound for the Irish tenor banjo, which has no standard id of its own" do
    expect(described_class.sound(HeadMusic::Instruments::Instrument.get("irish_tenor_banjo"))).to eq "pluck.banjo.tenor"
  end

  it "writes the general clarinet's sound for the clarinet in C" do
    expect(described_class.sound(HeadMusic::Instruments::Instrument.get("clarinet_in_c"))).to eq "wind.reed.clarinet"
  end

  it "writes a sound for every catalog instrument but the synthesizer" do
    soundless = HeadMusic::Instruments::Instrument.all.reject { |instrument| described_class.sound(instrument) }
    expect(soundless.map(&:name_key)).to eq [:synthesizer]
  end

  it "shares sounds only with catalog instruments that have none of their own" do
    sharers = described_class::SHARED_SOUNDS_BY_NAME_KEY.keys
    catalogued = sharers.select { |name_key| HeadMusic::Instruments::Instrument.get(name_key)&.name_key.to_s == name_key }
    expect([catalogued, sharers & described_class::SOUNDS_BY_NAME_KEY.keys]).to eq [sharers, []]
  end

  it "reads the soprillo's and the maracas' own sounds" do
    expect(%w[wind.reed.saxophone.sopranissimo rattle.maraca].map { |sound| described_class.instrument(sound).name_key }).to eq [:soprillo, :maracas]
  end

  it "names the family a general sound's more specific sounds share" do
    expect(described_class.family_key("wind.reed.saxophone")).to eq "saxophone"
  end

  it "names no family for a sound whose more specific sounds span several" do
    expect(described_class.family_key("wind.reed")).to be_nil
  end

  it "names no family for a sound with no more specific sounds" do
    expect(described_class.family_key("voice.male")).to be_nil
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
