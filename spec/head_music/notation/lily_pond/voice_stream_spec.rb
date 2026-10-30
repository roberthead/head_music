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
    expect([event.pitches, event.rhythmic_duration.single_value, event.line]).to eq [[c4], quarter, 7]
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
      expect(events.first.rhythmic_duration.to_s).to eq "half tied to quarter"
    end

    it "folds a longer chain" do
      expect(tie_through(half, quarter, quarter).first.rhythmic_duration.to_s).to eq "half tied to quarter tied to quarter"
    end

    it "ties chords with the same pitches in any order into one chord" do
      stream.add_note([c4, d4], half, 1)
      stream.open_tie(1)
      stream.add_note([d4, c4], quarter, 1)
      events = stream.finish.events
      expect(events.map { |event| [event.pitches, event.rhythmic_duration.to_s] }).to eq [[[c4, d4], "half tied to quarter"]]
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

    it "raises for a tie across a bar check that no note closes" do
      stream.add_note([c4], half, 1)
      stream.open_tie(1)
      stream.bar_check(1)
      expect { stream.finish }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /A tie must be followed by a note/)
    end
  end

  describe "a tie across a bar check and the changes after it" do
    before do
      stream.add_note([c4], half, 1)
      stream.open_tie(1)
      stream.bar_check(1)
      stream.change_key_signature(g_major, 2)
      stream.change_meter(three_four, 2)
      stream.add_note([c4], quarter, 2)
    end

    let(:note) { stream.finish.events.first }

    it "folds into one note" do
      expect(stream.finish.events.map(&:kind)).to eq %i[note]
    end

    it "records each in order, with how much of the note precedes it" do
      expect(note.inner_events.map { |inner| [inner.event.kind, inner.elapsed.to_s, inner.event.line] })
        .to eq [[:bar_check, "half", 1], [:key, "half", 2], [:time, "half", 2]]
    end
  end

  describe "#clef" do
    it "keeps the clef the voice opens with" do
      stream.clef("bass")
      stream.clef("treble")
      expect(stream.opening_clef).to eq "bass"
    end

    it "ignores a clef that comes after music" do
      stream.add_note([c4], half, 1)
      stream.clef("bass")
      expect(stream.opening_clef).to be_nil
    end
  end

  describe "tuplets" do
    let(:triplet) { HeadMusic::Rudiment::TupletRatio.get("3:2") }

    before { stream.open_tuplet(triplet, nil, 1) }

    it "gives notes and rests inside one the ratio, and none after it closes" do
      [stream.add_note([c4], quarter, 1), stream.add_rest(quarter, 1), stream.close_tuplet(1)]
      stream.add_note([d4], quarter, 1)
      expect(stream.finish.events.map { |event| [event.kind, event.rhythmic_duration&.to_s] }).to eq [
        [:tuplet_start, nil], [:note, "triplet quarter"], [:rest, "triplet quarter"], [:tuplet_end, nil], [:note, "quarter"]
      ]
    end

    it "keeps the span on the opening event" do
      spanned = described_class.new.tap { |other| other.open_tuplet(triplet, Rational(1, 4), 1) }
      expect(spanned.finish.events.first.then { |event| [event.tuplet, event.fraction] }).to eq [triplet, Rational(1, 4)]
    end

    it "scales a spacer inside one and gives it the ratio" do
      stream.add_spacer(Rational(1, 8), 1)
      spacer = stream.finish.events.last
      expect([spacer.fraction, spacer.tuplet]).to eq [Rational(1, 12), triplet]
    end

    it "holds the close inside a note tied out of it" do
      [stream.add_note([c4], quarter, 1), stream.open_tie(1), stream.close_tuplet(1)]
      inner_events = tie_through(quarter).last.inner_events
      expect(inner_events.map { |inner| [inner.elapsed.to_s, inner.event.kind] }).to eq [["triplet quarter", :tuplet_end]]
    end
  end

  describe "#add_graces" do
    let(:grace) do
      HeadMusic::Notation::LilyPond::GraceReader::Grace.new(
        pitches: [d4], rhythmic_value: HeadMusic::Rudiment::RhythmicValue.get(:sixteenth), slashed: true, tied: false,
        marks: HeadMusic::Notation::LilyPond::MarkReader::NONE
      )
    end
    let(:graces) { HeadMusic::Notation::LilyPond::GraceReader::Graces.new(graces: [grace], implied_slur: false) }

    it "gives the grace notes to the next note" do
      stream.add_graces(graces)
      stream.bar_check(1)
      stream.add_note([c4], quarter, 1)
      expect(stream.finish.events.map { |event| event.graces.length }).to eq [0, 1]
    end

    it "drops them before a rest" do
      [stream.add_graces(graces), stream.add_rest(quarter, 1), stream.add_note([c4], quarter, 1)]
      expect(stream.finish.events.map { |event| event.graces.length }).to eq [0, 0]
    end

    it "ignores an empty run" do
      [stream.add_graces(graces.with(graces: [])), stream.add_note([c4], quarter, 1)]
      expect(stream.finish.events.first.graces).to eq []
    end
  end

  describe "#change_staff" do
    it "holds a staff change inside a tied note" do
      stream.add_note([c4], half, 1)
      stream.open_tie(1)
      stream.change_staff("upper", 2)
      inner_events = tie_through(half).first.inner_events
      expect(inner_events.map { |inner| [inner.event.kind, inner.event.staff_name] }).to eq [[:staff_change, "upper"]]
    end
  end

  describe described_class::Event do
    subject(:note) do
      described_class.new(
        kind: :note, line: 1, pitches: [c4], rhythmic_duration: HeadMusic::Rudiment::RhythmicDuration.get(quarter),
        marks: HeadMusic::Notation::LilyPond::MarkReader::Marks.new(articulations: ["staccato"])
      )
    end

    it "takes a tied link's value and marks" do
      tied = note.tied_to(half, HeadMusic::Notation::LilyPond::MarkReader::Marks.new(articulations: ["accent"]))
      expect([tied.rhythmic_duration.to_s, tied.marks.articulations]).to eq ["quarter tied to half", %w[staccato accent]]
    end

    it "holds an event where its value so far ends" do
      held = note.holding(described_class.new(kind: :bar_check, line: 2))
      expect(held.inner_events.map { |inner| [inner.elapsed.to_s, inner.event.kind] }).to eq [["quarter", :bar_check]]
    end
  end
end
