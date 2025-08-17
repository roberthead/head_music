require "spec_helper"

describe HeadMusic::Rudiment::RhythmicElement do
  describe "abstract class" do
    it "cannot be instantiated directly" do
      expect { described_class.new }.to raise_error(NoMethodError)
    end
  end

  describe "shared behavior" do
    # We'll test this through a concrete subclass
    let(:test_class) do
      Class.new(described_class) do
        def self.get(rhythmic_value)
          new(rhythmic_value)
        end

        public_class_method :new

        def name
          "test element #{rhythmic_value}"
        end

        def sounded?
          true
        end
      end
    end

    let(:quarter_value) { HeadMusic::Content::RhythmicValue.get(:quarter) }
    let(:half_value) { HeadMusic::Content::RhythmicValue.get(:half) }

    let(:element) { test_class.get(quarter_value) }

    describe "#rhythmic_value" do
      it "returns the rhythmic value" do
        expect(element.rhythmic_value).to eq(quarter_value)
      end
    end

    describe "#ticks" do
      it "delegates to the rhythmic value" do
        expect(element.ticks).to eq(quarter_value.ticks)
      end
    end

    describe "#unit" do
      it "delegates to the rhythmic value" do
        expect(element.unit).to eq(quarter_value.unit)
      end
    end

    describe "#dots" do
      it "delegates to the rhythmic value" do
        expect(element.dots).to eq(quarter_value.dots)
      end
    end

    describe "#with_rhythmic_value" do
      it "creates a new instance with the specified rhythmic value" do
        new_element = element.with_rhythmic_value(half_value)
        expect(new_element.rhythmic_value).to eq(half_value)
        expect(new_element).not_to eq(element)
      end
    end

    describe "#==" do
      context "when comparing elements with the same rhythmic value" do
        let(:other_element) { test_class.get(quarter_value) }

        it "returns true" do
          expect(element).to eq(other_element)
        end
      end

      context "when comparing elements with different rhythmic values" do
        let(:other_element) { test_class.get(half_value) }

        it "returns false" do
          expect(element).not_to eq(other_element)
        end
      end
    end

    describe "comparison and sorting" do
      let(:whole_element) { test_class.get(HeadMusic::Content::RhythmicValue.get(:whole)) }
      let(:half_element) { test_class.get(half_value) }
      let(:quarter_element) { test_class.get(quarter_value) }
      let(:eighth_element) { test_class.get(HeadMusic::Content::RhythmicValue.get(:eighth)) }

      describe "#<=>" do
        it "compares by rhythmic value" do
          expect(quarter_element <=> half_element).to eq(-1)
          expect(half_element <=> quarter_element).to eq(1)
          expect(quarter_element <=> test_class.get(quarter_value)).to eq(0)
        end

        it "returns nil when comparing with non-RhythmicElement" do
          expect(quarter_element <=> "not a rhythmic element").to be_nil
        end
      end

      describe "sorting" do
        describe "with like types" do
          it "sorts by rhythmic value" do
            unsorted = [quarter_element, whole_element, eighth_element, half_element]
            sorted = unsorted.sort

            # Shortest to longest duration
            expect(sorted).to eq([eighth_element, quarter_element, half_element, whole_element])
          end
        end

        describe "with mixed types of rhythmic elements" do
          let(:quarter_note) { HeadMusic::Rudiment::Note.get("C4", :quarter) }
          let(:half_rest) { HeadMusic::Rudiment::Rest.get(:half) }
          let(:unpitched_eighth) { HeadMusic::Rudiment::UnpitchedNote.get(:eighth, instrument: "snare") }

          it "sorts by rhythmic value" do
            mixed_elements = [half_rest, quarter_note, unpitched_eighth]
            sorted = mixed_elements.sort

            # Should sort by rhythmic value: eighth, quarter, half
            expect(sorted).to eq([unpitched_eighth, quarter_note, half_rest])
          end
        end
      end
    end
  end
end
