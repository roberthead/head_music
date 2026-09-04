require "spec_helper"

describe HeadMusic::Notation::LilyPond::VoiceStream do
  subject(:stream) { described_class.new("Melody") }

  let(:c4) { HeadMusic::Rudiment::Pitch.get("C4") }
  let(:d4) { HeadMusic::Rudiment::Pitch.get("D4") }
  let(:quarter) { HeadMusic::Rudiment::RhythmicValue.get(:quarter) }
  let(:half) { HeadMusic::Rudiment::RhythmicValue.get(:half) }
  let(:g_major) { HeadMusic::Rudiment::KeySignature.get("G major") }
  let(:three_four) { HeadMusic::Rudiment::Meter.get("3/4") }

  def kinds
    stream.finish.events.map(&:kind)
  end

  # Adds the values as one note tied through, and returns the finished events.
  def tie_through(*values)
    values.each_with_index do |value, index|
      stream.open_tie(1) if index.positive?
      stream.add_note([c4], value, 1)
    end
    stream.finish.events
  end

  it "carries its role" do
    expect(stream.role).to eq "Melody"
  end

  it "defaults the role to nil" do
    expect(described_class.new.role).to be_nil
  end

  describe "event order" do
    before do
      stream.change_key_signature(g_major, 1)
      stream.change_meter(three_four, 1)
      stream.add_note([c4], quarter, 2)
      stream.add_rest(quarter, 2)
      stream.add_whole_bar_rest(Rational(3, 4), 3)
      stream.bar_check(3)
    end

    it "records events in order" do
      expect(kinds).to eq %i[key time note rest whole_bar_rest bar_check]
    end
  end

  it "keeps the pitches, values, and lines on the events" do
    stream.add_note([c4], quarter, 7)
    event = stream.finish.events.first
    expect([event.pitches, event.rhythmic_value, event.line]).to eq [[c4], quarter, 7]
  end

  it "keeps a key signature on its event" do
    stream.change_key_signature(g_major, 1)
    expect(stream.finish.events.first.key_signature).to eq g_major
  end

  it "keeps a meter on its event" do
    stream.change_meter(three_four, 1)
    expect(stream.finish.events.first.meter).to eq three_four
  end

  it "keeps a whole-bar rest's fraction on its event" do
    stream.add_whole_bar_rest(Rational(3, 4), 1)
    expect(stream.finish.events.first.fraction).to eq Rational(3, 4)
  end

  describe "#music?" do
    it "is false with no events" do
      expect(stream).not_to be_music
    end

    it "is false with only commands and bar checks" do
      stream.change_key_signature(g_major, 1)
      stream.bar_check(1)
      expect(stream).not_to be_music
    end

    it "is true with a pending note" do
      stream.add_note([c4], quarter, 1)
      expect(stream).to be_music
    end

    it "is true with a rest" do
      stream.add_rest(quarter, 1)
      expect(stream).to be_music
    end
  end

  describe "ties" do
    it "folds a tied pair into one note" do
      events = tie_through(half, quarter)
      expect(events.length).to eq 1
      expect(events.first.rhythmic_value.to_s).to eq "half tied to quarter"
    end

    it "folds a longer chain" do
      expect(tie_through(half, quarter, quarter).first.rhythmic_value.to_s).to eq "half tied to quarter tied to quarter"
    end

    it "ties chords with the same pitches in any order into one chord" do
      stream.add_note([c4, d4], half, 1)
      stream.open_tie(1)
      stream.add_note([d4, c4], quarter, 1)
      events = stream.finish.events
      expect(events.map { |event| [event.pitches, event.rhythmic_value.to_s] }).to eq [[[c4, d4], "half tied to quarter"]]
    end

    it "raises when the tied note differs in pitch" do
      stream.add_note([c4], half, 1)
      stream.open_tie(1)
      expect { stream.add_note([d4], quarter, 2) }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /A tie must connect two notes of the same pitch \(line 2\)/)
    end

    it "raises for a tie with no note before it" do
      expect { stream.open_tie(3) }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /A tie must follow a note \(line 3\)/)
    end

    it "raises for a tie after a rest" do
      stream.add_rest(quarter, 1)
      expect { stream.open_tie(1) }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /must follow a note/)
    end

    it "raises for a doubled tie mark" do
      stream.add_note([c4], half, 1)
      stream.open_tie(1)
      expect { stream.open_tie(1) }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /must follow a note/)
    end

    {
      "a rest" => ->(stream) { stream.add_rest(HeadMusic::Rudiment::RhythmicValue.get(:quarter), 1) },
      "a key change" => ->(stream) { stream.change_key_signature(HeadMusic::Rudiment::KeySignature.get("G major"), 1) },
      "a meter change" => ->(stream) { stream.change_meter(HeadMusic::Rudiment::Meter.get("3/4"), 1) },
      "a whole-bar rest" => ->(stream) { stream.add_whole_bar_rest(1, 1) }
    }.each do |follower, follow|
      it "raises for a tie followed by #{follower}" do
        stream.add_note([c4], half, 1)
        stream.open_tie(1)
        expect { follow.call(stream) }
          .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /A tie must be followed by a note/)
      end
    end

    it "raises for a tie left open at the end, at the tie's line" do
      stream.add_note([c4], half, 4)
      stream.open_tie(4)
      expect { stream.finish }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /must be followed by a note \(line 4\)/)
    end

    it "raises for a tie across a bar check" do
      stream.add_note([c4], half, 1)
      stream.open_tie(1)
      expect { stream.bar_check(1) }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Ties across bar checks are not yet supported/)
    end
  end
end
