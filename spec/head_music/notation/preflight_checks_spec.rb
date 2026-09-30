require "spec_helper"

describe HeadMusic::Notation::PreflightChecks do
  let(:flow) do
    HeadMusic::Content::Flow.new.tap do |short|
      voice = short.add_voice
      voice.place("1:1:000", :whole, "C4")
      voice.place("2:1:000", :whole, "D4")
    end
  end

  context "with a marking on a bar after the music" do
    before { flow.bar(3).jump = HeadMusic::Content::Jump.new(:da_capo) }

    {
      to_abc: HeadMusic::Notation::ABC::RenderError,
      to_lilypond: HeadMusic::Notation::LilyPond::RenderError,
      to_musicxml: HeadMusic::Notation::MusicXML::RenderError,
      to_kern: HeadMusic::Notation::Kern::RenderError
    }.each do |method, error|
      it "refuses to write it with #{method} rather than drop it" do
        expect { flow.public_send(method) }.to raise_error(error, /bar 3 carries .* the music ends in bar 2/)
      end
    end
  end

  context "with a marking on the last bar of the music" do
    before { flow.bar(2).jump = HeadMusic::Content::Jump.new(:da_capo) }

    it "writes it" do
      expect(flow.to_abc).to include "!D.C.!"
    end
  end
end
