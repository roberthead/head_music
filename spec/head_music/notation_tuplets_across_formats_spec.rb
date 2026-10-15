require "spec_helper"

# Each format's reader and writer were built apart, so these carry music
# read in one format through another's writer and back.
describe HeadMusic::Notation do
  def fixture(path)
    File.read(File.expand_path("../fixtures/notation/#{path}", __dir__))
  end

  def sounding(flow)
    sounding_summary(flow).map { |voice| voice.reject { |event| event.last.empty? } }
  end

  def grace_sounds(flow)
    grace_summary(flow).map { |graced, slurs| [graced.map { |position, graces| [position, graces.map(&:first)] }, slurs.size] }
  end

  describe "the hand-written LilyPond tuplets and grace notes" do
    let(:flow) { described_class::LilyPond.parse(fixture("lily_pond/tuplets_and_grace_notes.ly")) }

    it "sound the same after kern and back" do
      back = described_class::Kern.parse(described_class::Kern.render(flow))
      expect([sounding(back), grace_sounds(back)]).to eq [sounding(flow), grace_sounds(flow)]
    end

    it "write MusicXML that matches the flow" do
      expect(musicxml_summaries(described_class::MusicXML.render(flow))).to eq expected_musicxml_summaries(flow)
    end
  end

  %w[tuplets grace_notes].each do |name|
    describe "the kern #{name} fixture" do
      let(:flow) { described_class::Kern.parse(fixture("kern/#{name}.krn")) }
      let(:rendered) { described_class::LilyPond.render(flow) }

      it "sounds the same after LilyPond and back" do
        back = described_class::LilyPond.parse(rendered)
        expect([sounding(back), grace_sounds(back)]).to eq [sounding(flow), grace_sounds(flow)]
      end

      it "writes MusicXML that matches the flow" do
        expect(musicxml_summaries(described_class::MusicXML.render(flow))).to eq expected_musicxml_summaries(flow)
      end

      it "writes LilyPond that compiles without warnings" do
        skip "lilypond is not installed" unless installed_lilypond
        expect(compile_warnings(rendered)).to be_empty
      end
    end
  end
end
