require "spec_helper"

describe HeadMusic::Time::KeySignatureEvent do
  subject(:event) { described_class.new(position, -3, tonal_context: HeadMusic::Rudiment::Mode.get("C dorian")) }

  let(:position) { HeadMusic::Time::MusicalPosition.new(9) }

  its(:signature) { is_expected.to eq(-3) }
  its(:position) { is_expected.to be position }

  it "refuses a signature that is not a count of fifths" do
    expect { described_class.new(position, "3 flats") }
      .to raise_error ArgumentError, /must be an Integer number of fifths/
  end

  describe "when the signature and the interpretation diverge" do
    # The signature wins, because the signature is what is printed -- but the
    # tonic is kept, since C minor prints the same three flats as its relative
    # E flat major and is the key the music is actually in.
    it "prints the signature on the tonic the music is in" do
      expect(event.printed_key_signature.name).to eq "C minor"
    end

    it "reports the collection the interpretation names" do
      expect(event.key_signature.name).to eq "C dorian"
    end

    it "describes itself by both" do
      expect(event.to_s).to eq "-3 C dorian"
    end
  end

  describe "when the signature and the interpretation agree" do
    subject(:event) { described_class.new(position, 0, tonal_context: HeadMusic::Rudiment::Mode.get("D dorian")) }

    # Kept as dorian rather than flattened to its conventional reading, so a
    # format that can express a mode still gets to.
    it "prints the interpretation" do
      expect(event.printed_key_signature.name).to eq "D dorian"
    end
  end

  describe "with no interpretation" do
    subject(:event) { described_class.new(position, 2) }

    it "falls back to the conventional reading for its key signature" do
      expect(event.key_signature.name).to eq "D major"
    end

    it "describes itself by the signature alone" do
      expect(event.to_s).to eq "2"
    end

    it "has no reading beyond the fallback table" do
      expect { described_class.new(position, 8).key_signature }
        .to raise_error ArgumentError, /no conventional key/
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

  describe ".from_key_signature" do
    subject(:event) { described_class.from_key_signature(HeadMusic::Rudiment::KeySignature.get("E dorian"), position) }

    it "counts the signature's fifths" do
      expect(event.signature).to eq 2
    end

    it "recovers the interpretation the signature was built from" do
      expect(event.tonal_context.name).to eq "E dorian"
    end

    it "prefers an interpretation it is given" do
      a_major = HeadMusic::Rudiment::Key.get("A major")
      expect(described_class.from_key_signature(HeadMusic::Rudiment::KeySignature.get("E dorian"), position, tonal_context: a_major).tonal_context)
        .to be a_major
    end
  end
end
