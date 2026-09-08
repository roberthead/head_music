require "spec_helper"

# Written pitch, with no flow anywhere near it: the whole of transposition is
# a move from one spelled pitch to another and the key signature that follows.
describe HeadMusic::Content::Layout::Transposition do
  subject(:clarinet) { described_class.for(instrument("clarinet")) }

  def instrument(name)
    HeadMusic::Instruments::Instrument.get(name)
  end

  describe ".for" do
    it "moves the sounding pitch by the opposite of the instrument's transposition" do
      expect(clarinet.semitones).to eq 2
    end

    it "is the identity for an instrument that does not transpose" do
      expect(described_class.for(instrument("flute"))).to be_identity
    end

    it "is the identity for no instrument at all" do
      expect(described_class.for(nil)).to be_identity
    end
  end

  describe "#written" do
    it "spells a clarinet's sounding D as the E it reads, not an F-flat" do
      expect(clarinet.written("D4").to_s).to eq "E4"
    end

    it "reads a horn in F a fifth above what it sounds" do
      expect(described_class.for(instrument("french_horn")).written("C4").to_s).to eq "G4"
    end

    it "reads a piccolo an octave below what it sounds" do
      expect(described_class.for(instrument("piccolo")).written("C5").to_s).to eq "C4"
    end

    it "reads a bass clarinet a ninth above what it sounds" do
      expect(described_class.for(instrument("bass_clarinet")).written("C4").to_s).to eq "D5"
    end

    it "leaves the pitch alone under the identity" do
      expect(described_class.for(nil).written("C4").to_s).to eq "C4"
    end
  end

  describe "#sounding" do
    it "answers what the written pitch is heard as" do
      expect(clarinet.sounding("C4").to_s).to eq "B♭3"
    end
  end

  describe "#written_sound" do
    it "moves a pitch string as a document writes it" do
      expect(clarinet.written_sound("D4")).to eq "E4"
    end

    it "passes an unpitched sound through untouched" do
      snare = HeadMusic::Rudiment::UnpitchedSound.get(:snare_drum)
      expect(clarinet.written_sound(snare)).to be snare
    end
  end

  describe "#key_signature" do
    it "moves C major to the D major a clarinet reads" do
      expect(clarinet.key_signature("C major").name).to eq "D major"
    end

    it "keeps the scale type" do
      expect(clarinet.key_signature("C dorian").name).to eq "D dorian"
    end

    it "leaves the key alone under the identity" do
      expect(described_class.for(nil).key_signature("C major").name).to eq "C major"
    end

    it "refuses a written key no signature can print" do
      expect { clarinet.key_signature("F♯ major") }
        .to raise_error HeadMusic::Notation::RenderError, /G♯ major needs 8 sharps/
    end

    it "names the enharmonic to write instead" do
      expect { clarinet.key_signature("F♯ major") }
        .to raise_error HeadMusic::Notation::RenderError, /A♭ major/
    end
  end

  describe "#key_signature_event" do
    subject(:written) { clarinet.key_signature_event(event) }

    let(:position) { HeadMusic::Time::MusicalPosition.new(5, 1, 0, 0) }
    let(:event) { HeadMusic::Time::KeySignatureEvent.new(position, 0) }

    it "moves the signature" do
      expect(written.signature).to eq 2
    end

    it "leaves the event where it was" do
      expect(written.position).to eq position
    end

    context "with a tonal context that diverges from its signature" do
      let(:event) do
        HeadMusic::Time::KeySignatureEvent.new(
          position, -3, tonal_context: HeadMusic::Rudiment::Mode.get("C dorian")
        )
      end

      it "moves the interpretation with the signature" do
        expect(written.tonal_context.name).to eq "D dorian"
      end

      it "keeps the divergence: three flats read as dorian is still three flats" do
        expect(written.signature).to eq(-1)
      end
    end
  end

  describe "#fifths_delta" do
    it "counts how far around the circle a key moves" do
      expect(clarinet.fifths_delta).to eq 2
    end

    it "is nothing under the identity" do
      expect(described_class.for(nil).fifths_delta).to eq 0
    end
  end

  describe "#diatonic_steps" do
    it "counts the staff steps a B-flat instrument's transposition spans" do
      expect(described_class.for_semitones(-2).diatonic_steps).to eq(-1)
    end

    it "counts a horn in F's" do
      expect(described_class.for_semitones(-7).diatonic_steps).to eq(-4)
    end

    it "counts nothing for a plain octave" do
      expect(described_class.for_semitones(12).diatonic_steps).to eq 7
    end
  end
end
