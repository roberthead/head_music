require "spec_helper"

# A signature underdetermines its interpretation, and the two can legitimately
# diverge, so a key signature event carries both. The two export formats then
# want different things from it: MusicXML wants <fifths> and an optional
# <mode>, and LilyPond can only say one key, so it says the printed one.
describe HeadMusic::Content::Flow do
  subject(:flow) { described_class.new }

  before { flow.add_voice.place("1:1", :whole, "C4") }

  context "with a signature carrying no interpretation" do
    before { flow.change_key_signature(1, 2) }

    it "emits the fifths" do
      expect(flow.to_musicxml).to include "<fifths>2</fifths>"
    end

    # <mode> is optional in MusicXML, and inventing a major here would be
    # asserting a tonic nobody gave.
    it "emits no mode element" do
      expect(flow.to_musicxml).not_to include "<mode>"
    end

    it "reads the signature through the fifths table for LilyPond" do
      expect(flow.to_lilypond).to include "\\key d \\major"
    end
  end

  # Cantus mollis: C dorian written with the parallel minor's three flats, the
  # A naturals written as accidentals on the notes.
  context "with a signature and interpretation that diverge" do
    before do
      flow.change_key_signature(1, -3, tonal_context: HeadMusic::Rudiment::Mode.get("C dorian"))
    end

    it "emits the printed signature" do
      expect(flow.to_musicxml).to include "<fifths>-3</fifths>"
    end

    it "emits the interpretation alongside it" do
      expect(flow.to_musicxml).to include "<mode>dorian</mode>"
    end

    # LilyPond has no rendering for the divergent case -- \key c \dorian prints
    # two flats -- so it prints the signature, on the tonic the music is in.
    it "prefers the signature in LilyPond, keeping the tonic" do
      expect(flow.to_lilypond).to include "\\key c \\minor"
    end

    it "round-trips both fields through schema-4 JSON" do
      restored = described_class.from_h(JSON.parse(flow.to_h.to_json))
      expect([restored.timeline.signature_at(1), restored.timeline.tonal_context_at(1).name])
        .to eq [-3, "C dorian"]
    end
  end

  context "with a signature and interpretation that agree" do
    subject(:flow) { described_class.new(key_signature: "D dorian") }

    it "still says dorian in LilyPond, which can express it" do
      expect(flow.to_lilypond).to include "\\key d \\dorian"
    end

    it "still says dorian in MusicXML" do
      expect(flow.to_musicxml).to include "<mode>dorian</mode>"
    end
  end

  # The signature itself is unbounded -- G sharp major counts each double sharp
  # twice and reaches eight -- but the fallback table stops at seven, because
  # past that there is no conventional major key to name.
  #
  # Only LilyPond consults the table, because only LilyPond needs a tonic.
  # MusicXML stores fifths, which is what the event already holds.
  context "with a theoretical signature beyond the fallback table" do
    context "when the event carries an interpretation" do
      before { flow.change_key_signature(1, 8, tonal_context: HeadMusic::Rudiment::Key.get("G# major")) }

      it "renders to MusicXML" do
        expect(flow.to_musicxml).to include "<fifths>8</fifths>"
      end

      it "renders to LilyPond on the tonic it names" do
        expect(flow.to_lilypond).to include "\\key gis \\major"
      end
    end

    context "when it does not" do
      before { flow.change_key_signature(1, 8) }

      it "still renders to MusicXML, which needs no tonic" do
        expect(flow.to_musicxml).to include "<fifths>8</fifths>"
      end

      it "raises for LilyPond, which does" do
        expect { flow.to_lilypond }
          .to raise_error ArgumentError, /no conventional key for a signature of 8 fifths/
      end
    end
  end
end
