require "spec_helper"

describe HeadMusic::Style::Guidelines::DissonanceFigureDetection do
  # A minimal host that includes the mixin. It treats every note as consonant
  # with the cantus firmus so that figure shape alone decides recognition.
  let(:host_class) do
    Class.new do
      include HeadMusic::Style::Guidelines::DissonanceFigureDetection

      attr_reader :notes

      def initialize(notes)
        @notes = notes
      end

      def dissonant_with_cantus?(_note)
        false
      end
    end
  end
  let(:series) { voice.notes.first(5) }
  let(:extra_note) { voice.notes.last }
  let(:host) { host_class.new(series) }

  let(:composition) { HeadMusic::Content::Composition.new(key_signature: "C major") }
  let(:voice) { composition.add_voice(role: :counterpoint) }

  before do
    # A descending nota cambiata (C5 B4 G4 A4 B4) followed by an extra note.
    # Note 2 (B4) is the dissonant member of the figure.
    voice.place("1:1", :quarter, "C5")
    voice.place("1:2", :quarter, "B4")
    voice.place("1:3", :quarter, "G4")
    voice.place("1:4", :quarter, "A4")
    voice.place("2:1", :quarter, "B4")
    voice.place("2:2", :quarter, "C5")
  end

  describe "#cambiata_dissonance?" do
    it "recognizes the dissonant second note of a nota cambiata" do
      expect(host.send(:cambiata_dissonance?, series[1])).to be true
    end

    it "returns false for a note that is not in the series" do
      expect(host.send(:cambiata_dissonance?, extra_note)).to be false
    end

    it "returns false for a note too close to the end to be note 2" do
      expect(host.send(:cambiata_dissonance?, series.last)).to be false
    end

    it "returns false for the first note of the series" do
      expect(host.send(:cambiata_dissonance?, series.first)).to be false
    end
  end

  describe "#double_neighbor_member?" do
    it "returns false for a note that is not in the series" do
      expect(host.send(:double_neighbor_member?, extra_note)).to be false
    end
  end
end
