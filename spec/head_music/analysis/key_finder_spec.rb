require "spec_helper"

describe HeadMusic::Analysis::KeyFinder do
  describe "::KEYS" do
    subject(:keys) { described_class::KEYS }

    let(:major_tonics) { %w[C D♭ D E♭ E F G♭ G A♭ A B♭ B] }
    let(:minor_tonics) { %w[C C♯ D E♭ E F F♯ G G♯ A B♭ B] }

    it "lists the twelve major keys, then the twelve minor keys" do
      expect(keys.map(&:name)).to eq major_tonics.map { |tonic| "#{tonic} major" } + minor_tonics.map { |tonic| "#{tonic} minor" }
    end

    it "holds Keys" do
      expect(keys).to all(be_a(HeadMusic::Rudiment::Key))
    end

    it "covers every tonic pitch class in each quality" do
      keys.group_by(&:quality).each_value do |quality_keys|
        expect(quality_keys.map { |key| key.tonic_spelling.pitch_class.to_i }).to eq (0..11).to_a
      end
    end

    it "takes no signature past six accidentals" do
      expect(keys.map { |key| key.key_signature.num_alterations }.max).to eq 6
    end
  end
end
