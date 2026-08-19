require "spec_helper"

describe HeadMusic::Style::Guidelines::MinimumThreshold do
  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "D dorian") }
  let(:voice) { HeadMusic::Content::Voice.new(composition: composition) }

  describe ".with" do
    it "carries the minimum as configuration" do
      expect(described_class.with(5).config).to include(minimum: 5)
    end

    it "keeps the other options alongside it" do
      expect(described_class.with(5, violation_key: :too_few).config)
        .to include(minimum: 5, violation_key: :too_few)
    end
  end

  describe "the count it leaves to subclasses" do
    let(:unmeasured_subclass) do
      stub_const("UnmeasuredThreshold", Class.new(described_class) do
        def marks
          deficiency_mark
        end
      end)
    end

    it "cannot judge a voice without one" do
      expect { assess(unmeasured_subclass, voice, minimum: 2) }.to raise_error(NotImplementedError)
    end
  end

  describe "the judgment it makes on a subclass's count" do
    subject(:assessment) { assess(note_counting_subclass, voice, minimum: 4) }

    let(:note_counting_subclass) do
      stub_const("NoteCountThreshold", Class.new(described_class) do
        def marks
          deficiency_mark
        end

        private

        def actual_count
          notes.length
        end
      end)
    end

    def place(count)
      %w[D E F G A B C D].first(count).each.with_index(1) do |pitch, bar|
        voice.place("#{bar}:1", :whole, pitch)
      end
    end

    context "when the count falls short of the minimum" do
      before { place(3) }

      it { is_expected.not_to be_adherent }

      it "marks every placement" do
        expect(assessment.first_mark.placements).to eq voice.placements
      end

      it "scores fitness as the count's proportion of the minimum" do
        expect(assessment.fitness).to eq 0.75
      end
    end

    context "when the count meets the minimum exactly" do
      before { place(4) }

      it { is_expected.to be_adherent }

      it "leaves the voice unmarked" do
        expect(assessment.marks).to be_empty
      end
    end

    context "when the count exceeds the minimum" do
      before { place(6) }

      it { is_expected.to be_adherent }
    end

    # There is nothing to attach a mark to, so a subclass that wants to fault
    # an empty voice has to say so itself, as MinimumNotes does.
    context "when the voice is empty" do
      it "finds nothing to mark" do
        expect(assessment.marks).to be_empty
      end

      it { is_expected.to be_adherent }
    end
  end
end
