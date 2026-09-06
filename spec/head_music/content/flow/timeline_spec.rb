require "spec_helper"

describe HeadMusic::Content::Flow::Timeline do
  subject(:timeline) { described_class.new }

  describe "the opening values" do
    subject(:timeline) { described_class.new(key_signature: "D dorian", meter: "6/8") }

    it "answers the meter it opens in" do
      expect(timeline.meter_at(1).to_s).to eq "6/8"
    end

    it "answers the key signature it opens in" do
      expect(timeline.key_signature_at(1).name).to eq "D dorian"
    end

    it "answers a tempo it was never given" do
      expect(timeline.tempo_at(1).beats_per_minute).to eq 120
    end

    # The distinction the writers depend on: opening in a meter is not the same
    # as changing to it, and only the latter prints a signature mid-piece.
    it "reports no authored meter change in the opening bar" do
      expect(timeline.meter_change_at(1)).to be_nil
    end

    it "reports no authored key change in the opening bar" do
      expect(timeline.key_signature_change_at(1)).to be_nil
    end

    it "has no changed bars" do
      expect(timeline.changed_bar_numbers).to be_empty
    end
  end

  describe "#change_meter" do
    before { timeline.change_meter(5, "3/4") }

    it "leaves the bars before it alone" do
      expect(timeline.meter_at(4).to_s).to eq "4/4"
    end

    it "takes effect from its bar" do
      expect(timeline.meter_at(5).to_s).to eq "3/4"
    end

    it "stays in force in later bars" do
      expect(timeline.meter_at(99).to_s).to eq "3/4"
    end

    it "is authored in its own bar only" do
      expect([timeline.meter_change_at(5)&.to_s, timeline.meter_change_at(6)]).to eq ["3/4", nil]
    end
  end

  describe "#change_tempo" do
    before { timeline.change_tempo(5, HeadMusic::Rudiment::Tempo.new("quarter", 96)) }

    it "takes effect from its bar" do
      expect(timeline.tempo_at(5).beats_per_minute).to eq 96
    end

    it "leaves the bars before it alone" do
      expect(timeline.tempo_at(4).beats_per_minute).to eq 120
    end

    it "is authored in its own bar" do
      expect(timeline.tempo_change_at(5).beats_per_minute).to eq 96
    end

    it "is not authored in the bars that follow" do
      expect(timeline.tempo_change_at(6)).to be_nil
    end
  end

  describe "#change_key_signature" do
    context "when given a key signature to interpret" do
      before { timeline.change_key_signature(9, "G major") }

      it "takes its fifths from the signature" do
        expect(timeline.signature_at(9)).to eq 1
      end

      it "keeps the interpretation it was named by" do
        expect(timeline.tonal_context_at(9).name).to eq "G major"
      end
    end

    context "when given bare fifths and a divergent interpretation" do
      # Cantus mollis: C dorian written with the parallel minor's three flats,
      # the A naturals written as accidentals on the notes.
      before do
        timeline.change_key_signature(9, -3, tonal_context: HeadMusic::Rudiment::Mode.get("C dorian"))
      end

      it "prints the signature it was given" do
        expect(timeline.signature_at(9)).to eq(-3)
      end

      it "keeps the interpretation that disagrees with it" do
        expect(timeline.tonal_context_at(9).name).to eq "C dorian"
      end

      it "reports the collection the interpretation names" do
        expect(timeline.key_signature_at(9).name).to eq "C dorian"
      end
    end

    context "when given bare fifths and no interpretation" do
      before { timeline.change_key_signature(9, 2) }

      it "has no tonal context" do
        expect(timeline.tonal_context_at(9)).to be_nil
      end

      it "falls back to the conventional reading of the signature" do
        expect(timeline.key_signature_at(9).name).to eq "D major"
      end
    end
  end

  describe "#changed_bar_numbers" do
    it "lists every bar something was authored in, once, in order" do
      timeline.change_key_signature(9, 2)
      timeline.change_meter(5, "3/4")
      timeline.change_tempo(9, HeadMusic::Rudiment::Tempo.new("quarter", 96))
      expect(timeline.changed_bar_numbers).to eq [5, 9]
    end
  end

  describe "an event off a downbeat" do
    let(:flow) { HeadMusic::Content::Flow.new }

    it "cannot be written as a position" do
      expect { flow.change_meter("3:2", "3/4") }
        .to raise_error ArgumentError, /takes a bar number/
    end

    it "cannot be written as a fraction of a bar" do
      expect { flow.change_key_signature(2.5, "G major") }
        .to raise_error ArgumentError, /takes a bar number/
    end
  end

  describe "the authored changes by bar" do
    before do
      timeline.change_meter(5, "3/4")
      timeline.change_key_signature(9, 2)
      timeline.change_tempo(3, HeadMusic::Rudiment::Tempo.new("quarter", 96))
    end

    it "keys the meters by bar" do
      expect(timeline.meter_changes.transform_values(&:to_s)).to eq(5 => "3/4")
    end

    it "keys the key signatures by bar" do
      expect(timeline.key_signature_changes.transform_values(&:signature)).to eq(9 => 2)
    end

    it "keys the tempos by bar" do
      expect(timeline.tempo_changes.transform_values(&:beats_per_minute)).to eq(3 => 96.0)
    end
  end

  describe ".tonal_context_of" do
    it "narrows a major signature to a key" do
      expect(described_class.tonal_context_of(HeadMusic::Rudiment::KeySignature.get("D major")))
        .to be_a HeadMusic::Rudiment::Key
    end

    it "narrows a modal signature to a mode" do
      expect(described_class.tonal_context_of(HeadMusic::Rudiment::KeySignature.get("D dorian")))
        .to be_a HeadMusic::Rudiment::Mode
    end

    # Neither subclass can hold a harmonic minor, and refusing it here would
    # make the flow unconstructable rather than merely unrenderable as a
    # MusicXML <key> element.
    it "keeps a scale type neither subclass can hold" do
      expect(described_class.tonal_context_of(HeadMusic::Rudiment::KeySignature.get("C harmonic_minor")))
        .to be_a HeadMusic::Rudiment::KeySignature
    end
  end
end
