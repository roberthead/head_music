require "spec_helper"

describe HeadMusic::Analysis::KeyProfile do
  describe ".names" do
    it "lists the three profiles, the default first" do
      expect(described_class.names).to eq %i[aarden_essen krumhansl_kessler temperley]
    end
  end

  describe ".get" do
    it "reads a name as a symbol or a string" do
      expect(described_class.get("temperley")).to eq described_class.get(:temperley)
    end

    it "answers a profile passed in" do
      profile = described_class.get(:krumhansl_kessler)
      expect(described_class.get(profile)).to be profile
    end

    it "raises on an unknown name" do
      expect { described_class.get(:simple) }.to raise_error(ArgumentError, /unknown key profile :simple/)
    end

    it "raises on nil" do
      expect { described_class.get(nil) }.to raise_error(ArgumentError)
    end
  end

  describe "the published values" do
    def values(name, quality)
      described_class.get(name).public_send(quality).map(&:to_f)
    end

    it "pins Aarden-Essen" do
      expect(values(:aarden_essen, :major)).to eq [17.7661, 0.145624, 14.9265, 0.160186, 19.8049, 11.3587, 0.291248, 22.062, 0.145624, 8.15494, 0.232998, 4.95122]
      expect(values(:aarden_essen, :minor)).to eq [18.2648, 0.737619, 14.0499, 16.8599, 0.702494, 14.4362, 0.702494, 18.6161, 4.56621, 1.93186, 7.37619, 1.75623]
    end

    it "pins Krumhansl-Kessler" do
      expect(values(:krumhansl_kessler, :major)).to eq [6.35, 2.23, 3.48, 2.33, 4.38, 4.09, 2.52, 5.19, 2.39, 3.66, 2.29, 2.88]
      expect(values(:krumhansl_kessler, :minor)).to eq [6.33, 2.68, 3.52, 5.38, 2.60, 3.53, 2.54, 4.75, 3.98, 2.69, 3.34, 3.17]
    end

    it "pins Temperley (2007)" do
      expect(values(:temperley, :major)).to eq [0.748, 0.060, 0.488, 0.082, 0.670, 0.460, 0.096, 0.715, 0.104, 0.366, 0.057, 0.400]
      expect(values(:temperley, :minor)).to eq [0.712, 0.084, 0.474, 0.618, 0.049, 0.460, 0.105, 0.747, 0.404, 0.067, 0.133, 0.330]
    end

    it "holds them exactly, as Rationals" do
      expect(described_class.get(:krumhansl_kessler).major.first).to eq Rational(635, 100)
    end

    it "cites a source for each" do
      expect(described_class.names.map { |name| described_class.get(name).source }).to all(match(/\(\d{4}\)/))
    end
  end

  describe "#correlations" do
    subject(:profile) { described_class.get(:aarden_essen) }

    it "answers 24 values, the major keys from C, then the minor keys" do
      expect(profile.correlations(profile.minor).length).to eq 24
    end

    it "correlates a profile perfectly with its own key" do
      correlations = profile.correlations(profile.major)
      expect(correlations[0]).to be_within(1e-12).of(1.0)
      expect(profile.correlations(profile.minor)[12]).to be_within(1e-12).of(1.0)
    end

    it "rotates the profile to each tonic" do
      in_g = profile.major.rotate(-7)
      expect(profile.correlations(in_g).each_with_index.max[1]).to eq 7
    end

    it "scores a flat histogram 0 for every key" do
      expect(profile.correlations(Array.new(12, 1))).to eq Array.new(24, 0.0)
    end

    it "scores an empty histogram 0 for every key" do
      expect(profile.correlations(Array.new(12, 0))).to eq Array.new(24, 0.0)
    end

    it "scores 0 against a profile with no variance" do
      flat = described_class.new(name: :flat, major: Array.new(12, 1), minor: profile.minor, source: "none")
      correlations = flat.correlations(profile.major)
      expect(correlations.first(12)).to eq Array.new(12, 0.0)
      expect(correlations.last(12)).to all(be_a(Float))
    end

    it "ties keys whose correlations are equal in exact arithmetic" do
      histogram = [Rational(1, 4), 0, Rational(1, 4), Rational(1, 4), 0, Rational(1, 4), 0, Rational(1, 2), 0, 0, 0, 0]
      correlations = described_class.get(:krumhansl_kessler).correlations(histogram)
      expect(correlations[12]).to eq correlations[19]
    end
  end
end
