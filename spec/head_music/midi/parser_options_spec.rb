require "spec_helper"

describe HeadMusic::MIDI::Parser do
  describe "MIDI.parse" do
    let!(:bytes) { HeadMusic::MIDI.render(HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/4\nK:C\nC D E F |]\n")) }

    context "with options it does not take" do
      it "raises ArgumentError for an unknown option" do
        expect { HeadMusic::MIDI.parse(bytes, tempo: 90) }.to raise_error(ArgumentError, /tempo/)
      end

      it "raises ArgumentError for bytes that are not a String" do
        expect { HeadMusic::MIDI.parse(bytes.bytes) }.to raise_error(ArgumentError, "expected a String of bytes, not Array")
      end

      it "raises ArgumentError for an unknown key name" do
        expect { HeadMusic::MIDI.parse(bytes, key: "H major") }.to raise_error(ArgumentError, 'unknown key "H major"')
      end

      it "raises ArgumentError for a key that is no key" do
        expect { HeadMusic::MIDI.parse(bytes, key: 3) }.to raise_error(ArgumentError, "expected a key, a mode, or key regions, got 3")
      end

      it "raises ArgumentError for an empty list of key regions" do
        expect { HeadMusic::MIDI.parse(bytes, key: []) }.to raise_error(ArgumentError, "key: needs at least one key region")
      end

      it "raises ArgumentError for a list of things that are not key regions" do
        expect { HeadMusic::MIDI.parse(bytes, key: ["C major"]) }.to raise_error(ArgumentError, 'expected a KeyRegion, got "C major"')
      end

      it "raises ArgumentError for an unknown grid symbol" do
        expect { HeadMusic::MIDI.parse(bytes, grid: :fine) }.to raise_error(ArgumentError, "grid: takes :auto or a positive Rational, not :fine")
      end

      it "raises ArgumentError for a Float grid" do
        expect { HeadMusic::MIDI.parse(bytes, grid: 0.0625) }.to raise_error(ArgumentError, "grid: takes :auto or a positive Rational, not 0.0625")
      end

      it "raises ArgumentError for a grid of zero" do
        expect { HeadMusic::MIDI.parse(bytes, grid: Rational(0)) }.to raise_error(ArgumentError, "grid: takes :auto or a positive Rational, not (0/1)")
      end

      it "raises ArgumentError for a negative grid" do
        expect { HeadMusic::MIDI.parse(bytes, grid: Rational(-1, 16)) }.to raise_error(ArgumentError, "grid: takes :auto or a positive Rational, not (-1/16)")
      end

      it "checks the options before reading a byte" do
        expect { HeadMusic::MIDI.parse("not a MIDI file", grid: :fine) }.to raise_error(ArgumentError)
      end
    end

    context "with options it takes" do
      let(:region) { HeadMusic::Analysis::KeyRegion.new(bar_number: 1, onset: 0, key: HeadMusic::Rudiment::Key.get("G major")) }

      [nil, :infer, "D major", :e_minor, "D dorian"].each do |key|
        it "reads with key: #{key.inspect}" do
          expect(HeadMusic::MIDI.parse(bytes, key: key)).to be_a HeadMusic::Content::Flow
        end
      end

      it "reads with a key" do
        expect(HeadMusic::MIDI.parse(bytes, key: HeadMusic::Rudiment::Key.get("F major"))).to be_a HeadMusic::Content::Flow
      end

      it "reads with key regions" do
        expect(HeadMusic::MIDI.parse(bytes, key: [region])).to be_a HeadMusic::Content::Flow
      end

      [:auto, Rational(1, 24), Rational(1, 28)].each do |grid|
        it "reads with grid: #{grid.inspect}" do
          expect(HeadMusic::MIDI.parse(bytes, grid: grid)).to be_a HeadMusic::Content::Flow
        end
      end
    end

    context "when a model constructor refuses a value" do
      HeadMusic::MIDI::Parser::TRANSLATED.each do |error_class|
        it "raises a ParseError caused by the #{error_class}" do
          allow(HeadMusic::Content::Flow).to receive(:new).and_raise(error_class, "no such value")
          expect { HeadMusic::MIDI.parse(bytes) }.to raise_error(HeadMusic::MIDI::ParseError, "no such value") { |error|
            expect(error.cause).to be_a error_class
          }
        end
      end
    end

    context "when a stage before the flow is built raises one of the errors model constructors raise" do
      HeadMusic::MIDI::Parser::TRANSLATED.each do |error_class|
        it "lets the #{error_class} escape as itself" do
          allow(HeadMusic::MIDI::Quantizer).to receive(:new).and_raise(error_class, "a bug")
          expect { HeadMusic::MIDI.parse(bytes) }.to raise_error(error_class, "a bug")
        end
      end
    end

    context "when the import has a bug" do
      [NoMethodError, TypeError, StandardError].each do |error_class|
        it "lets the #{error_class} escape as itself" do
          allow(HeadMusic::Content::Flow).to receive(:new).and_raise(error_class, "a bug")
          expect { HeadMusic::MIDI.parse(bytes) }.to raise_error(error_class, "a bug")
        end
      end
    end

    it "raises a ParseError for bytes that are no MIDI file" do
      expect { HeadMusic::MIDI.parse("not a MIDI file") }.to raise_error(HeadMusic::MIDI::ParseError, "no MThd header (byte 0)")
    end
  end
end
