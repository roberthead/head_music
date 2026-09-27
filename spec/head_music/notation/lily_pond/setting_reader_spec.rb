require "spec_helper"

describe HeadMusic::Notation::LilyPond::SettingReader do
  subject(:reader) { described_class.new(cursor) }

  let(:cursor) { HeadMusic::Notation::LilyPond::TokenCursor.new(HeadMusic::Notation::LilyPond::Lexer.new(source).tokens) }
  let(:stream) { HeadMusic::Notation::LilyPond::VoiceStream.new }

  context "with a key" do
    let(:source) { "\\key g \\major c4" }

    it "changes the stream's key signature" do
      reader.read(stream)
      expect(stream.finish.events.map(&:key_signature)).to eq [HeadMusic::Rudiment::KeySignature.get("G major")]
    end

    it "consumes the setting and nothing after it" do
      reader.read(stream)
      expect(cursor.peek.lexeme).to eq "c4"
    end
  end

  context "with a meter" do
    let(:source) { "\\time 3/4" }

    it "changes the stream's meter" do
      reader.read(stream)
      expect(stream.finish.events.map(&:meter)).to eq [HeadMusic::Rudiment::Meter.get("3/4")]
    end
  end

  context "with a clef" do
    let(:source) { "\\clef bass" }

    it "names the stream's opening clef" do
      reader.read(stream)
      expect(stream.opening_clef).to eq "bass"
    end
  end

  context "with no stream to change" do
    let(:source) { "\\key g \\major \\time 3/4 \\clef bass c4" }

    it "reads each setting for its syntax alone" do
      3.times { reader.read }
      expect(cursor.peek.lexeme).to eq "c4"
    end
  end

  context "with an invalid key" do
    let(:source) { "\n\\key g \\bogus" }

    it "raises at the line of the command" do
      expect { reader.read }.to raise_error(HeadMusic::Notation::LilyPond::ParseError) { |error| expect(error.line_number).to eq 2 }
    end
  end

  context "with something other than a clef name" do
    let(:source) { "\\clef }" }

    it "raises at the token that is not a clef name" do
      expect { reader.read(stream) }.to raise_error(HeadMusic::Notation::LilyPond::ParseError) { |error| expect(error.snippet).to eq "}" }
    end

    it "raises at the same token with no stream to change" do
      expect { reader.read }.to raise_error(HeadMusic::Notation::LilyPond::ParseError) { |error| expect(error.snippet).to eq "}" }
    end
  end
end
