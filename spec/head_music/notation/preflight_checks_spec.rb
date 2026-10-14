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

  render_errors = {
    to_abc: HeadMusic::Notation::ABC::RenderError,
    to_lilypond: HeadMusic::Notation::LilyPond::RenderError,
    to_musicxml: HeadMusic::Notation::MusicXML::RenderError,
    to_kern: HeadMusic::Notation::Kern::RenderError
  }

  {
    "a voice dynamic in a bar after the music" => [->(flow) { flow.voices.first.place_dynamic("4:1", :f) }, /dynamic f at 4:1:000 falls after the music ends in bar 2/],
    "a part dynamic in a bar after the music" => [->(flow) { flow.parts.first.place_dynamic("3:2", :p) }, /dynamic p at 3:2:000 falls after the music ends in bar 2/],
    "a voice dynamic exactly where the music ends" => [->(flow) { flow.voices.first.place_dynamic("3:1", :ff) }, /dynamic ff at 3:1:000 falls after the music ends in bar 2/],
    "a part dynamic in a bar before the music" => [->(flow) { flow.parts.first.place_dynamic("0:2", :pp) }, /dynamic pp at 0:2:000 falls before the music starts in bar 1/]
  }.each do |description, (placement, message)|
    context "with #{description}" do
      before { placement.call(flow) }

      render_errors.each do |method, error|
        it "refuses to write it with #{method} rather than drop it" do
          expect { flow.public_send(method) }.to raise_error(error, message)
        end
      end
    end
  end

  context "with a dynamic in a bar the music reaches only through a tie" do
    let(:flow) do
      HeadMusic::Content::Flow.new.tap do |tied|
        voice = tied.add_voice
        voice.place("1:1:000", :half, "C4")
        voice.place("1:3:000", :whole, "D4")
        voice.place_dynamic("2:2", :mf)
      end
    end

    render_errors.each_key do |method|
      it "writes it with #{method}" do
        expect { flow.public_send(method) }.not_to raise_error
      end
    end
  end

  context "with a dynamic under a pickup's written rest" do
    let(:flow) do
      HeadMusic::Content::Flow.new.tap do |pickup|
        voice = pickup.add_voice
        voice.place("0:1:000", :half)
        voice.place("0:3:000", :half, "C4")
        voice.place("1:1:000", :whole, "D4")
        voice.place_dynamic("0:1", :p)
      end
    end

    render_errors.each_key do |method|
      it "writes it with #{method}" do
        expect { flow.public_send(method) }.not_to raise_error
      end
    end
  end
end
