require "spec_helper"

describe HeadMusic::Content::GraceNote do
  subject(:grace_note) { described_class.new(sounds: "A4", rhythmic_value: :sixteenth) }

  its(:pitches) { is_expected.to eq [HeadMusic::Rudiment::Pitch.get("A4")] }
  its(:rhythmic_value) { is_expected.to eq HeadMusic::Rudiment::RhythmicValue.get(:sixteenth) }
  its(:to_s) { is_expected.to eq "grace sixteenth A4" }
  its(:to_h) { is_expected.to eq("sounds" => ["A4"], "rhythmic_value" => "sixteenth") }

  it { is_expected.not_to be_slashed }
  it { is_expected.not_to be_tied }
  it { is_expected.to be_frozen }

  it "has no position" do
    expect(grace_note).not_to respond_to(:position)
  end

  it "holds a chord of sounds" do
    expect(described_class.new(sounds: %w[A4 C5], rhythmic_value: :eighth).pitches.map(&:to_s)).to eq %w[A4 C5]
  end

  it "holds an unpitched sound" do
    expect(described_class.new(sounds: "snare drum", rhythmic_value: :eighth).to_h["sounds"]).to eq [{"unpitched" => "snare_drum"}]
  end

  it "writes its flags and articulations when set" do
    slashed = described_class.new(sounds: "A4", rhythmic_value: :eighth, slashed: true, tied: true, articulations: %i[staccato accent])
    expect(slashed.to_h).to eq(
      "sounds" => ["A4"], "rhythmic_value" => "eighth", "slashed" => true, "tied" => true, "articulations" => %w[accent staccato]
    )
  end

  it "names a slashed grace note" do
    expect(described_class.new(sounds: "A4", rhythmic_value: :eighth, slashed: true).to_s).to eq "slashed grace eighth A4"
  end

  it "equals a grace note of the same values" do
    expect(grace_note).to eq described_class.new(sounds: "A4", rhythmic_value: "sixteenth")
  end

  it "refuses a grace note with no sound" do
    expect { described_class.new(sounds: nil, rhythmic_value: :eighth) }.to raise_error(ArgumentError, "a grace note needs at least one sound")
  end

  it "refuses a tied value" do
    expect { described_class.new(sounds: "A4", rhythmic_value: "eighth tied to sixteenth") }
      .to raise_error(ArgumentError, /a grace note needs a plain or dotted value/)
  end

  it "refuses a tuplet value" do
    expect { described_class.new(sounds: "A4", rhythmic_value: "triplet eighth") }
      .to raise_error(ArgumentError, /a grace note needs a plain or dotted value/)
  end

  it "refuses an unknown articulation" do
    expect { described_class.new(sounds: "A4", rhythmic_value: :eighth, articulations: [:bogus]) }
      .to raise_error(ArgumentError, "unknown articulation: :bogus")
  end
end
