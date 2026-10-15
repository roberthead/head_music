require "spec_helper"

describe HeadMusic::Instruments::Instrument do
  # Tuned, though their default notation has a neutral clef, so #pitched? is false.
  let(:pitched_with_neutral_clef) { %w[timpani crotales didgeridoo tabla] }
  let(:no_gm_program) { %w[didgeridoo theremin tabla] }
  let(:no_gm_percussion_key) { %w[drum_kit castanets tam_tam tenor_drum] }

  let(:instruments) { described_class::INSTRUMENTS.keys.map { |key| described_class.get(key) } }
  let(:unpitched_percussion) do
    instruments.reject { |instrument| instrument.pitched? || pitched_with_neutral_clef.include?(instrument.name_key.to_s) }
  end
  let(:pitched) { instruments - unpitched_percussion }

  def keys(list)
    list.map { |instrument| instrument.name_key.to_s }
  end

  it "has instruments whose #pitched? is false although they are tuned" do
    expect(keys(instruments.reject(&:pitched?))).to include(*pitched_with_neutral_clef)
  end

  it "gives every pitched instrument a GM program, except the exclusions" do
    expect(keys(pitched.reject(&:gm_program)).sort).to eq no_gm_program.sort
  end

  it "gives every unpitched percussion instrument a GM percussion key, except the exclusions" do
    expect(keys(unpitched_percussion.reject(&:gm_percussion_key)).sort).to eq no_gm_percussion_key.sort
  end

  it "gives unpitched percussion no GM program" do
    expect(unpitched_percussion.filter_map(&:gm_program)).to be_empty
  end

  it "gives no pitched instrument a GM percussion key" do
    expect(pitched.filter_map(&:gm_percussion_key)).to be_empty
  end

  it "keeps every program in 1..128" do
    expect(instruments.filter_map(&:gm_program)).to all(be_between(1, 128))
  end

  it "keeps every percussion key in 35..81" do
    expect(instruments.filter_map(&:gm_percussion_key)).to all(be_between(35, 81))
  end

  {
    "piano" => 1, "harpsichord" => 7, "celesta" => 9, "glockenspiel" => 10, "vibraphone" => 12,
    "marimba" => 13, "xylophone" => 14, "chimes" => 15, "organ" => 20, "accordion" => 22, "guitar" => 25,
    "violin" => 41, "viola" => 42, "cello" => 43, "double_bass" => 44, "harp" => 47, "timpani" => 48,
    "soprano_voice" => 53, "trumpet" => 57, "trombone" => 58, "tuba" => 59, "french_horn" => 61,
    "soprano_saxophone" => 65, "alto_saxophone" => 66, "tenor_saxophone" => 67, "baritone_saxophone" => 68,
    "oboe" => 69, "cor_anglais" => 70, "bassoon" => 71, "clarinet" => 72, "piccolo_flute" => 73,
    "flute" => 74, "recorder" => 75, "sitar" => 105, "banjo" => 106, "great_highland_bagpipe" => 110,
    "steelpan" => 115
  }.each do |key, program|
    it "gives #{key} GM program #{program}" do
      expect(described_class.get(key).gm_program).to eq program
    end
  end

  {
    "bass_drum" => 35, "snare_drum" => 38, "floor_tom" => 41, "hi_hat" => 42, "crash_cymbal" => 49,
    "high_tom" => 50, "ride_cymbal" => 51, "tambourine" => 54, "cowbell" => 56, "maracas" => 70,
    "woodblock" => 76, "triangle" => 81
  }.each do |key, percussion_key|
    it "gives #{key} GM percussion key #{percussion_key}" do
      expect(described_class.get(key).gm_percussion_key).to eq percussion_key
    end
  end
end
