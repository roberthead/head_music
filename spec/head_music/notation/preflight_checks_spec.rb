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

  {
    "a hairpin starting where the music ends" => [->(flow) { flow.parts.first.add_span(:crescendo, from: "3:1", to: "3:2") }, /crescendo start at 3:1:000 falls after the music ends in bar 2/],
    "a hairpin ending a beat past the music's end" => [->(flow) { flow.voices.first.add_span(:diminuendo, from: "2:1", to: "3:2") }, /diminuendo end at 3:2:000 falls after the music ends in bar 2/],
    "a part hairpin starting before the music" => [->(flow) { flow.parts.first.add_span(:crescendo, from: "0:2", to: "1:3") }, /crescendo start at 0:2:000 falls before the music starts in bar 1/]
  }.each do |description, (placement, message)|
    context "with #{description}" do
      before { placement.call(flow) }

      render_errors.each do |method, error|
        it "refuses to write it with #{method}" do
          expect { flow.public_send(method) }.to raise_error(error, message)
        end
      end
    end
  end

  {
    "a hairpin ending on the final barline" => ["C4|D4|", ->(flow) { flow.parts.first.add_span(:crescendo, from: "2:1", to: "3:1") }],
    "a hairpin ending where a short final bar's music ends" => ["C D E|", ->(flow) { flow.voices.first.add_span(:crescendo, from: "1:1", to: "1:4") }],
    "a hairpin ending on the barline after a short final bar" => ["C D E|", ->(flow) { flow.voices.first.add_span(:crescendo, from: "1:2", to: "2:1") }]
  }.each do |description, (body, placement)|
    context "with #{description}" do
      let(:flow) { HeadMusic::Notation::ABC.parse("X:1\nL:1/4\nM:4/4\nK:C\n#{body}\n").tap { |hairpinned| placement.call(hairpinned) } }

      render_errors.each_key do |method|
        it "lets #{method} write it" do
          expect { flow.public_send(method) }.not_to raise_error
        end
      end
    end
  end

  describe "#ensure_one_hairpin_at_a_time" do
    let(:checker) do
      Class.new do
        include HeadMusic::Notation::PreflightChecks

        def check(owners) = ensure_one_hairpin_at_a_time(owners, line: "the line")

        def render_error_class = HeadMusic::Notation::ABC::RenderError
      end.new
    end

    let(:part) { flow.parts.first }
    let(:voice) { flow.voices.first }

    it "refuses hairpins of two owners that overlap, naming both" do
      part.add_span(:crescendo, from: "1:1", to: "2:1")
      voice.add_span(:diminuendo, from: "1:3", to: "2:3")
      expect { checker.check([part, voice]) }.to raise_error(HeadMusic::Notation::ABC::RenderError,
        /one hairpin at a time, so the crescendo from 1:1:000 to 2:1:000 and the diminuendo from 1:3:000 to 2:3:000 cannot/)
    end

    it "lets the same hairpin from two owners, and touching hairpins, through" do
      part.add_span(:crescendo, from: "1:1", to: "2:1")
      voice.add_span(:crescendo, from: "1:1", to: "2:1")
      voice.add_span(:diminuendo, from: "2:1", to: "2:3")
      expect { checker.check([part, voice]) }.not_to raise_error
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
