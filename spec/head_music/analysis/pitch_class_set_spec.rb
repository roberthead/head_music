require "spec_helper"

describe HeadMusic::Analysis::PitchClassSet do
  context "when the set has zero pitch classes" do
    subject(:set) { described_class.new([]) }

    it { is_expected.to be_empty }
    it { is_expected.to be_empty_set }
    it { is_expected.not_to be_monad }
    it { is_expected.not_to be_dyad }
    it { is_expected.not_to be_trichord }
    it { is_expected.not_to be_tetrachord }
    it { is_expected.not_to be_pentachord }
    it { is_expected.not_to be_hexachord }
    it { is_expected.not_to be_heptachord }
    it { is_expected.not_to be_octachord }
    it { is_expected.not_to be_nonachord }
    it { is_expected.not_to be_decachord }
    it { is_expected.not_to be_undecachord }
    it { is_expected.not_to be_dodecachord }
  end

  context "when the set has one pitch class" do
    subject(:set) { described_class.new(["A"]) }

    it { is_expected.not_to be_empty }
    it { is_expected.not_to be_empty_set }
    it { is_expected.to be_monad }
    it { is_expected.not_to be_dyad }
    it { is_expected.not_to be_trichord }
    it { is_expected.not_to be_tetrachord }
    it { is_expected.not_to be_pentachord }
    it { is_expected.not_to be_hexachord }
    it { is_expected.not_to be_heptachord }
    it { is_expected.not_to be_octachord }
    it { is_expected.not_to be_nonachord }
    it { is_expected.not_to be_decachord }
    it { is_expected.not_to be_undecachord }
    it { is_expected.not_to be_dodecachord }

    it { is_expected.to be_a(described_class) }

    its(:inspect) { is_expected.to eq "[9]" }
    its(:to_s) { is_expected.to eq "[9]" }

    specify do
      expect(set).to be_equivalent(described_class.new(["Bbb"]))
    end
  end

  context "when the set has two pitches" do
    subject(:set) { described_class.new(%w[A3 D4]) }

    it { is_expected.not_to be_empty }
    it { is_expected.not_to be_empty_set }
    it { is_expected.not_to be_monad }
    it { is_expected.to be_dyad }
    it { is_expected.not_to be_trichord }
    it { is_expected.not_to be_tetrachord }
    it { is_expected.not_to be_pentachord }
    it { is_expected.not_to be_hexachord }
    it { is_expected.not_to be_heptachord }
    it { is_expected.not_to be_octachord }
    it { is_expected.not_to be_nonachord }
    it { is_expected.not_to be_decachord }
    it { is_expected.not_to be_undecachord }
    it { is_expected.not_to be_dodecachord }
  end

  context "when the set has three pitches" do
    subject(:set) { described_class.new(%w[F#3 D4 A4]) }

    it { is_expected.not_to be_empty }
    it { is_expected.not_to be_empty_set }
    it { is_expected.not_to be_monad }
    it { is_expected.not_to be_dyad }
    it { is_expected.to be_trichord }
    it { is_expected.not_to be_tetrachord }
    it { is_expected.not_to be_pentachord }
    it { is_expected.not_to be_hexachord }
    it { is_expected.not_to be_heptachord }
    it { is_expected.not_to be_octachord }
    it { is_expected.not_to be_nonachord }
    it { is_expected.not_to be_decachord }
    it { is_expected.not_to be_undecachord }
    it { is_expected.not_to be_dodecachord }

    its(:inspect) { is_expected.to eq "[2, 6, 9]" }
    its(:to_s) { is_expected.to eq "[2, 6, 9]" }
  end

  context "when the set has nine pitches and seven pitch classes" do
    subject(:set) { described_class.new(%w[C D E F G A B C5 D5]) }

    it { is_expected.not_to be_empty }
    it { is_expected.not_to be_empty_set }
    it { is_expected.not_to be_monad }
    it { is_expected.not_to be_dyad }
    it { is_expected.not_to be_trichord }
    it { is_expected.not_to be_tetrachord }
    it { is_expected.not_to be_pentachord }
    it { is_expected.not_to be_hexachord }
    it { is_expected.to be_heptachord }
    it { is_expected.not_to be_octachord }
    it { is_expected.not_to be_nonachord }
    it { is_expected.not_to be_decachord }
    it { is_expected.not_to be_undecachord }
    it { is_expected.not_to be_dodecachord }
  end

  context "when the set has nine unique pitches classes" do
    subject(:set) { described_class.new(%w[C D E F G A B C#5 F#5]) }

    it { is_expected.not_to be_empty }
    it { is_expected.not_to be_empty_set }
    it { is_expected.not_to be_monad }
    it { is_expected.not_to be_dyad }
    it { is_expected.not_to be_trichord }
    it { is_expected.not_to be_tetrachord }
    it { is_expected.not_to be_pentachord }
    it { is_expected.not_to be_hexachord }
    it { is_expected.not_to be_heptachord }
    it { is_expected.not_to be_octachord }
    it { is_expected.to be_nonachord }
    it { is_expected.not_to be_decachord }
    it { is_expected.not_to be_undecachord }
    it { is_expected.not_to be_dodecachord }
  end

  describe "#inversion" do
    context "with a simple trichord [0, 4, 7] (major triad)" do
      subject(:set) { described_class.new([0, 4, 7]) }

      it "returns the inversion [0, 5, 8] (minor triad)" do
        expect(set.inversion.pitch_classes.map(&:to_i)).to eq [0, 5, 8]
      end
    end

    context "with [0, 3, 7] (minor triad)" do
      subject(:set) { described_class.new([0, 3, 7]) }

      it "returns [0, 5, 9]" do
        # Inversion: 0->0, 3->9, 7->5, sorted: [0, 5, 9]
        expect(set.inversion.pitch_classes.map(&:to_i)).to eq [0, 5, 9]
      end
    end

    context "with [2, 4, 8]" do
      subject(:set) { described_class.new([2, 4, 8]) }

      it "returns the inversion" do
        # Inversion: 2->10, 4->8, 8->4, sorted: [4, 8, 10]
        inverted = set.inversion.pitch_classes.map(&:to_i)
        expect(inverted).to eq [4, 8, 10]
      end
    end
  end

  describe "#normal_form" do
    context "with empty set" do
      subject(:set) { described_class.new([]) }

      it "returns itself" do
        expect(set.normal_form).to eq set
      end
    end

    context "with single pitch class" do
      subject(:set) { described_class.new([5]) }

      it "returns itself" do
        expect(set.normal_form.pitch_classes.map(&:to_i)).to eq [5]
      end
    end

    context "with [0, 2, 7]" do
      subject(:set) { described_class.new([0, 2, 7]) }

      it "finds the normal form [0, 2, 7]" do
        expect(set.normal_form.pitch_classes.map(&:to_i)).to eq [0, 2, 7]
      end
    end

    context "with [7, 2, 0] (same as previous, different order)" do
      subject(:set) { described_class.new([7, 2, 0]) }

      it "finds the normal form [0, 2, 7]" do
        expect(set.normal_form.pitch_classes.map(&:to_i)).to eq [0, 2, 7]
      end
    end

    context "with [2, 7, 11] which needs rotation" do
      subject(:set) { described_class.new([2, 7, 11]) }

      it "finds the most compact rotation" do
        normal = set.normal_form.pitch_classes.map(&:to_i)
        # Most compact rotation should minimize span
        # Rotations: [2,7,11] span=9, [7,11,2] span=7, [11,2,7] span=8
        # Actually in normalized form starting from first element:
        # From 2: [0,5,9] span=9
        # From 7: [0,4,7] span=7 (winner)
        # From 11: [0,3,8] span=8
        expect(normal).to eq [0, 4, 7]
      end
    end

    context "with chromatic cluster [0, 1, 2]" do
      subject(:set) { described_class.new([0, 1, 2]) }

      it "finds normal form [0, 1, 2]" do
        expect(set.normal_form.pitch_classes.map(&:to_i)).to eq [0, 1, 2]
      end
    end

    context "with [0, 4, 7] (major triad)" do
      subject(:set) { described_class.new([0, 4, 7]) }

      it "finds normal form [0, 4, 7]" do
        expect(set.normal_form.pitch_classes.map(&:to_i)).to eq [0, 4, 7]
      end
    end

    context "with [4, 7, 0] (major triad rotated)" do
      subject(:set) { described_class.new([4, 7, 0]) }

      it "finds normal form [0, 4, 7]" do
        expect(set.normal_form.pitch_classes.map(&:to_i)).to eq [0, 4, 7]
      end
    end
  end

  describe "#prime_form" do
    context "with empty set" do
      subject(:set) { described_class.new([]) }

      it "returns itself" do
        expect(set.prime_form).to eq set
      end
    end

    context "with single pitch class" do
      subject(:set) { described_class.new([5]) }

      it "returns [0]" do
        expect(set.prime_form.pitch_classes.map(&:to_i)).to eq [0]
      end
    end

    context "with major triad [0, 4, 7]" do
      subject(:set) { described_class.new([0, 4, 7]) }

      it "finds prime form [0, 3, 7] (prefers minor form)" do
        prime = set.prime_form.pitch_classes.map(&:to_i)
        # Normal of [0,4,7] is [0,4,7]
        # Inversion: [0,8,5] -> normal: [0,5,8] normalized to start at 0: [0,5,8]
        # Actually: inversion of [0,4,7] = [0,8,5] sorted = [0,5,8]
        # Hmm, need to reconsider. Prime form chooses most compact.
        # [0,4,7] and [0,5,8] both have same span
        # Compare lexicographically: [0,3,7] vs [0,4,7] - [0,3,7] is smaller
        expect(prime).to eq [0, 3, 7]
      end
    end

    context "with minor triad [0, 3, 7]" do
      subject(:set) { described_class.new([0, 3, 7]) }

      it "finds prime form [0, 3, 7]" do
        expect(set.prime_form.pitch_classes.map(&:to_i)).to eq [0, 3, 7]
      end
    end

    context "with augmented triad [0, 4, 8]" do
      subject(:set) { described_class.new([0, 4, 8]) }

      it "finds prime form [0, 4, 8] (symmetrical)" do
        expect(set.prime_form.pitch_classes.map(&:to_i)).to eq [0, 4, 8]
      end
    end

    context "with diminished seventh [0, 3, 6, 9]" do
      subject(:set) { described_class.new([0, 3, 6, 9]) }

      it "finds prime form [0, 3, 6, 9] (symmetrical)" do
        expect(set.prime_form.pitch_classes.map(&:to_i)).to eq [0, 3, 6, 9]
      end
    end

    context "with whole tone hexachord [0, 2, 4, 6, 8, 10]" do
      subject(:set) { described_class.new([0, 2, 4, 6, 8, 10]) }

      it "finds prime form [0, 2, 4, 6, 8, 10] (symmetrical)" do
        expect(set.prime_form.pitch_classes.map(&:to_i)).to eq [0, 2, 4, 6, 8, 10]
      end
    end

    context "with chromatic trichord [0, 1, 2]" do
      subject(:set) { described_class.new([0, 1, 2]) }

      it "finds prime form [0, 1, 2]" do
        expect(set.prime_form.pitch_classes.map(&:to_i)).to eq [0, 1, 2]
      end
    end
  end

  describe "set equivalence comparison using prime form" do
    context "when comparing two major triads in different transpositions" do
      let(:c_major) { described_class.new([0, 4, 7]) }  # C E G
      let(:d_major) { described_class.new([2, 6, 9]) }  # D F# A

      it "have equivalent prime forms" do
        expect(c_major.prime_form).to eq d_major.prime_form
      end
    end

    context "when comparing major triad and minor triad" do
      let(:c_major) { described_class.new([0, 4, 7]) }
      let(:c_minor) { described_class.new([0, 3, 7]) }

      it "have equivalent prime forms (inversionally related)" do
        expect(c_major.prime_form).to eq c_minor.prime_form
      end
    end

    context "when comparing two different set types" do
      let(:major_triad) { described_class.new([0, 4, 7]) }
      let(:augmented_triad) { described_class.new([0, 4, 8]) }

      it "have different prime forms" do
        expect(major_triad.prime_form).not_to eq augmented_triad.prime_form
      end
    end

    context "when comparing sets with same interval content" do
      let(:first_set) { described_class.new([0, 1, 4]) }
      let(:second_set) { described_class.new([3, 4, 7]) }

      it "have equivalent prime forms if related by transposition" do
        expect(first_set.prime_form).to eq second_set.prime_form
      end
    end
  end
end
