require "spec_helper"

# A layout in concert pitch and the same layout transposed render the same
# voice at different written pitches -- and, because the key moves with the
# notes, under different key signatures.
describe HeadMusic::Content::Layout do
  let(:project) { LayoutFixtures.clarinet_project }
  let(:concert) { project.add_layout(kind: :part) }
  let(:written) { project.add_layout(kind: :part, concert_pitch: false) }

  describe "a B-flat clarinet part" do
    it "renders the sounding pitch in concert pitch" do
      expect(concert.to_lilypond).to include "c'1"
    end

    it "renders the written pitch transposed" do
      expect(written.to_lilypond).to include "d'1"
    end

    it "keeps the sounding key in concert pitch" do
      expect(concert.to_lilypond).to include "\\key c \\major"
    end

    it "moves the key with the notes" do
      expect(written.to_lilypond).to include "\\key d \\major"
    end

    it "names what the written pitches sound like" do
      expect(written.to_lilypond).to include "\\transposition bes"
    end

    it "says nothing about transposition in concert pitch" do
      expect(concert.to_lilypond).not_to include "\\transposition"
    end

    it "renders the sounding step in concert MusicXML" do
      expect(xpath_texts(parse_musicxml(concert.to_musicxml), "//note/pitch/step").first).to eq "C"
    end

    it "renders the written step in transposed MusicXML" do
      expect(xpath_texts(parse_musicxml(written.to_musicxml), "//note/pitch/step").first).to eq "D"
    end

    it "prints no accidentals in concert MusicXML" do
      expect(xpath_texts(parse_musicxml(concert.to_musicxml), "//key/fifths")).to eq %w[0]
    end

    it "prints two sharps in transposed MusicXML" do
      expect(xpath_texts(parse_musicxml(written.to_musicxml), "//key/fifths")).to eq %w[2]
    end

    it "states the transposition MusicXML readers need" do
      document = parse_musicxml(written.to_musicxml)
      expect([xpath_text(document, "//transpose/diatonic"), xpath_text(document, "//transpose/chromatic")])
        .to eq %w[-1 -2]
    end

    it "puts the transposition after the clef, where MusicXML orders it" do
      elements = written.to_musicxml.scan(/<(clef|transpose)>/).flatten
      expect(elements).to eq %w[clef transpose]
    end

    it "states no transposition in concert pitch" do
      expect(concert.to_musicxml).not_to include "<transpose>"
    end

    it "names the sounding key in concert ABC" do
      expect(concert.to_abc).to include "K:C\n"
    end

    it "names the written key in transposed ABC" do
      expect(written.to_abc).to include "K:D\n"
    end

    it "moves the ABC note letters with the key" do
      expect(written.to_abc.lines.last).to eq "D8|E8|F8|G8|]\n"
    end
  end

  describe "an octave transposer" do
    let(:project) { LayoutFixtures.clarinet_project(instrument: "piccolo", pitches: %w[C5]) }

    it "reads an octave below what it sounds" do
      expect(written.to_lilypond).to include "c'1"
    end

    it "keeps the key it already had" do
      expect(written.to_lilypond).to include "\\key c \\major"
    end

    it "states the octave change MusicXML needs" do
      expect(xpath_text(parse_musicxml(written.to_musicxml), "//transpose/octave-change")).to eq "1"
    end
  end

  describe "a transposed score of a mixed ensemble" do
    let(:project) { LayoutFixtures.trio }
    let(:score) { project.add_score(ensemble_type: :orchestral, concert_pitch: false) }

    it "carries three written keys in one MusicXML document" do
      expect(xpath_texts(parse_musicxml(score.to_musicxml), "//key/fifths")).to eq %w[0 2 1]
    end

    it "carries three written keys in one LilyPond document" do
      expect(score.to_lilypond.scan(/\\key \w+ \\major/))
        .to eq ["\\key c \\major", "\\key d \\major", "\\key g \\major"]
    end

    it "names each transposing instrument's sounding pitch" do
      expect(score.to_lilypond.scan(/\\transposition \w+/)).to eq ["\\transposition bes", "\\transposition f"]
    end

    it "writes the same note three ways" do
      expect(xpath_texts(parse_musicxml(score.to_musicxml), "//note/pitch/step")).to eq %w[C D D E G A]
    end
  end

  describe "the same score in concert pitch" do
    let(:project) { LayoutFixtures.trio }
    let(:score) { project.add_score(ensemble_type: :orchestral) }

    it "renders the flow's own MusicXML" do
      expect(score.to_musicxml).to eq project.flows.first.to_musicxml
    end

    it "renders the flow's own LilyPond" do
      expect(score.to_lilypond).to eq project.flows.first.to_lilypond
    end
  end

  describe "a part that changes instrument" do
    let(:project) { LayoutFixtures.clarinet_project(pitches: %w[C4 C4 C4 C4]) }
    let(:flow) { project.flows.first }

    before do
      flow.parts.first.change_instrument(3, "clarinet_in_a")
      flow.add_part(player: project.add_player(name: "Flute"), instrument: "flute")
        .add_voice(role: "flute").place("1:1", :whole, "C4")
    end

    it "prints a second key signature where the player picks the other one up" do
      part = REXML::XPath.first(parse_musicxml(written.to_musicxml), "//part[@id='P1']")
      expect(xpath_texts(part, "measure/attributes/key/fifths")).to eq %w[2 -3]
    end

    it "prints it in that part alone" do
      part = REXML::XPath.first(parse_musicxml(written.to_musicxml), "//part[@id='P2']")
      expect(xpath_texts(part, "measure/attributes/key/fifths")).to eq %w[0]
    end

    it "refuses to write a tune that changes key partway in ABC" do
      clarinet_alone = project.add_layout(kind: :part, players: [project.players.first], concert_pitch: false)
      expect { clarinet_alone.to_abc }
        .to raise_error HeadMusic::Notation::RenderError, /instrument change at bar 3/
    end
  end
end
