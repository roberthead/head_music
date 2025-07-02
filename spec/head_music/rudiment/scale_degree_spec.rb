require "spec_helper"

describe HeadMusic::Rudiment::ScaleDegree do
  subject(:scale_degree) { described_class.new(key_signature, spelling) }

  context "when given the key of C minor" do
    let(:key_signature) { HeadMusic::Rudiment::KeySignature.get("C minor") }

    context "and the spelling 'D'" do
      let(:spelling) { HeadMusic::Rudiment::Spelling.get("D") }

      its(:degree) { is_expected.to eq 2 }
      its(:alteration) { is_expected.to be_nil }
      its(:name_for_degree) { is_expected.to eq "supertonic" }

      it { is_expected.to eq "2" }

      specify do
        third_scale_degree = described_class.new(key_signature, HeadMusic::Rudiment::Spelling.get("Eb"))
        expect(scale_degree).to be < third_scale_degree
      end
    end

    context "and the spelling 'Db'" do
      let(:spelling) { HeadMusic::Rudiment::Spelling.get("Db") }

      it { is_expected.to eq "♭2" }
    end

    context "and the spelling 'B'" do
      let(:spelling) { HeadMusic::Rudiment::Spelling.get("B") }

      it { is_expected.to eq "♯7" }
      its(:degree) { is_expected.to eq 7 }
      its(:alteration) { is_expected.to eq "♯" }
      its(:name_for_degree) { is_expected.to eq "leading tone" }

      it { is_expected.to be > described_class.new(key_signature, "E") }
    end
  end

  describe "comparison" do
    let(:key_signature) { HeadMusic::Rudiment::KeySignature.get("C minor") }
    let(:degree_two) { described_class.new(key_signature, "D") }      # diatonic 2nd degree
    let(:flat_two) { described_class.new(key_signature, "Db") }      # ♭2
    let(:degree_three) { described_class.new(key_signature, "Eb") }    # diatonic 3rd degree
    let(:sharp_seven) { described_class.new(key_signature, "B") }      # ♯7

    describe "comparison with other ScaleDegrees" do
      it "compares degrees first, then alterations" do
        expect(degree_two).to be < degree_three
        expect(degree_three).to be > degree_two
        expect(flat_two).to be < degree_two  # ♭2 < 2 (same degree, flat is lower)
        expect(sharp_seven).to be > degree_three # ♯7 > 3 (higher degree)
      end

      it "handles equal comparisons correctly" do
        another_degree2 = described_class.new(key_signature, "D")
        expect(degree_two).to eq another_degree2
        expect(degree_two <=> another_degree2).to eq 0
      end
    end

    describe "comparison with Numeric values" do
      it "compares degree number with integers" do
        expect(degree_two <=> 2).to eq 0     # degree 2 equals number 2
        expect(degree_two <=> 1).to eq 1     # degree 2 > number 1
        expect(degree_two <=> 3).to eq(-1)    # degree 2 < number 3
      end

      it "works with comparison operators" do
        expect(degree_two).to eq 2
        expect(degree_two).to be < 3
        expect(degree_two).to be > 1
        expect(degree_three).to be >= 3
        expect(sharp_seven).to be <= 7
      end

      it "ignores alterations when comparing with numbers" do
        expect(flat_two <=> 2).to eq 0    # ♭2 degree is still 2
        expect(sharp_seven <=> 7).to eq 0   # ♯7 degree is still 7
      end

      it "works with floats" do
        expect(degree_two <=> 2.0).to eq 0
        expect(degree_two <=> 2.5).to eq(-1)
      end
    end

    describe "comparison with String values" do
      it "compares string representations" do
        expect(degree_two <=> "2").to eq 0
        expect(flat_two <=> "♭2").to eq 0
        expect(sharp_seven <=> "♯7").to eq 0
      end

      it "works with string comparison operators" do
        expect(degree_two).to eq "2"
        expect(flat_two).to eq "♭2"
        expect(sharp_seven).to eq "♯7"
      end

      it "handles string ordering" do
        expect(degree_two <=> "1").to be > 0
        expect(degree_two <=> "3").to be < 0
        expect(flat_two <=> "♭1").to be > 0
      end
    end

    describe "comparison with incompatible types" do
      it "returns nil for incompatible types" do
        expect(degree_two <=> {}).to be_nil
        expect(degree_two <=> []).to be_nil
        expect(degree_two <=> nil).to be_nil
        expect(degree_two <=> Object.new).to be_nil
      end

      it "gracefully handles comparison operators with incompatible types" do
        # These will raise exceptions in Ruby when <=> returns nil, which is expected
        expect { degree_two < {} }.to raise_error(ArgumentError)
        expect { degree_two > [] }.to raise_error(ArgumentError)
      end
    end

    describe "sorting behavior" do
      it "sorts ScaleDegrees correctly" do
        degrees = [sharp_seven, degree_two, flat_two, degree_three]
        sorted = degrees.sort
        expect(sorted).to eq [flat_two, degree_two, degree_three, sharp_seven]
      end

      it "sorts mixed ScaleDegrees and numbers" do
        # When sorting mixed types, Ruby will call <=>
        # Numbers will compare with ScaleDegrees using degree numbers
        mixed = [3, 1, 2, 4]
        sorted = mixed.sort
        expect(sorted).to eq [1, degree_two, degree_three, 4]
      end
    end

    describe "edge cases" do
      it "handles comparison when alteration method returns nil" do
        # Test case where a scale degree has no alteration
        expect(degree_two.alteration).to be_nil
        expect(degree_two <=> degree_three).to eq(-1)
      end

      it "compares altered vs natural degrees of same number" do
        natural_2 = degree_two  # D in C minor (natural 2nd)
        flat_2 = flat_two       # Db in C minor (♭2)

        expect(flat_2).to be < natural_2
        expect(natural_2).to be > flat_2
        expect(flat_2 <=> natural_2).to eq(-1)
      end
    end

    describe "consistency with Comparable module" do
      it "provides consistent behavior across comparison methods" do
        expect(degree_two < degree_three).to be true
        expect(degree_two >= degree_three).to be false
        expect(degree_two == degree_three).to be false
        expect(degree_two != degree_three).to be true
      end

      it "satisfies transitivity" do
        # If a < b and b < c, then a < c
        expect(flat_two < degree_two).to be true
        expect(degree_two < degree_three).to be true
        expect(flat_two < degree_three).to be true
      end

      it "satisfies symmetry for equality" do
        another_degree2 = described_class.new(key_signature, "D")
        expect(degree_two == another_degree2).to be true
        expect(another_degree2 == degree_two).to be true
      end
    end
  end
end
