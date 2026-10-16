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

  describe "#key and #candidates" do
    let(:story_notes) { [[60, "1:1", :quarter], [62, "1:2", :quarter], [63, "1:3", :quarter], [65, "1:4", :quarter], [67, "2:1", :half]] }

    it "finds the story example in C minor" do
      expect(described_class.new(story_notes, meter: "4/4").key).to eq HeadMusic::Rudiment::Key.get("C minor")
    end

    it "uses Aarden-Essen by default" do
      expect(described_class.new(story_notes, meter: "4/4").profile.name).to eq :aarden_essen
    end

    it "takes another profile by name" do
      expect(described_class.new(story_notes, meter: "4/4", profile: :temperley).key.name).to eq "C minor"
    end

    context "when the profile ties two keys" do
      subject(:finder) { described_class.new(story_notes, meter: "4/4", profile: :krumhansl_kessler) }

      it "ties G minor and C minor exactly" do
        expect(finder.candidates.first(2).map(&:correlation).uniq.length).to eq 1
      end

      it "prefers the key with fewer accidentals" do
        expect(finder.candidates.first(2).map { |candidate| candidate.key.name }).to eq ["G minor", "C minor"]
      end
    end

    it "breaks a tie by fewer accidentals, then major before minor, then the lower tonic" do
      finder = described_class.new([[60, 0, 1], [62, 0, 1], [64, 0, 1], [65, 0, 1], [67, 0, 1], [69, 0, 1], [71, 0, 1], [61, 0, 1], [63, 0, 1], [66, 0, 1], [68, 0, 1], [70, 0, 1]])
      expect(finder.candidates.first(3).map { |candidate| candidate.key.name }).to eq ["C major", "A minor", "F major"]
    end

    it "ranks all 24 keys with their correlations, best first" do
      candidates = described_class.new(story_notes, meter: "4/4").candidates
      expect(candidates.map(&:key)).to match_array described_class::KEYS
      expect(candidates.map(&:correlation)).to eq candidates.map(&:correlation).sort.reverse
    end

    it "weights each pitch class by how long it sounds" do
      long_g = [[60, 0, Rational(1, 4)], [64, Rational(1, 4), Rational(1, 4)], [67, Rational(1, 2), 2], [71, Rational(5, 2), Rational(1, 4)], [62, Rational(11, 4), Rational(1, 4)]]
      long_b = [[60, 0, Rational(1, 4)], [64, Rational(1, 4), Rational(1, 4)], [67, Rational(1, 2), Rational(1, 4)], [71, Rational(3, 4), 2], [62, Rational(11, 4), Rational(1, 4)]]
      expect([long_g, long_b].map { |notes| described_class.new(notes).key.name }).to eq ["C major", "G major"]
    end

    it "answers the same result for the same input" do
      first = described_class.new(story_notes, meter: "4/4", profile: :krumhansl_kessler).candidates
      expect(described_class.new(story_notes, meter: "4/4", profile: :krumhansl_kessler).candidates).to eq first
    end

    it "raises on an unknown profile" do
      expect { described_class.new(story_notes, meter: "4/4", profile: :nonesuch) }.to raise_error(ArgumentError, /unknown key profile/)
    end

    context "with no notes" do
      subject(:finder) { described_class.new([]) }

      it "answers no key and no candidates" do
        expect(finder.key).to be_nil
        expect(finder.candidates).to eq []
      end
    end

    context "with grace notes alone, which take no time" do
      subject(:finder) { described_class.new([[61, 0, 0], [62, 0, 0]]) }

      it "answers no key" do
        expect(finder.key).to be_nil
      end
    end

    context "with a flow of unpitched sounds" do
      let(:flow) do
        HeadMusic::Content::Flow.new.tap do |flow|
          voice = flow.add_voice
          voice.place("1:1", :half, HeadMusic::Rudiment::UnpitchedSound.get("snare drum"))
          voice.place("1:3", :half)
        end
      end

      it "answers no key and no candidates" do
        finder = described_class.new(flow)
        expect([finder.key, finder.candidates]).to eq [nil, []]
      end
    end
  end
end
