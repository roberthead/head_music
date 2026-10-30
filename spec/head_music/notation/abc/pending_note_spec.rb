require "spec_helper"

describe HeadMusic::Notation::ABC::PendingNote do
  subject(:note) { described_class.new(pitches: [pitch("C#4")], length: "2", scale: Rational(1), slur_marks: [:open], beam_break: true) }

  let(:duration_resolver) { HeadMusic::Notation::ABC::DurationResolver.new("1/8") }

  def pitch(name)
    HeadMusic::Rudiment::Pitch.get(name)
  end

  it "resolves its own length" do
    expect(note.rhythmic_duration(duration_resolver).to_s).to eq "quarter"
  end

  it "ties to the same letters in the same octaves, whatever their accidentals" do
    expect([note.ties_to?([pitch("C4")]), note.ties_to?([pitch("C5")])]).to eq [true, false]
  end

  it "closes a slur after its own marks" do
    expect(note.closing_slur.slur_marks).to eq %i[open close]
  end

  it "takes decorations after its own" do
    expect(note.with(decorations: [:accent]).decorated([:fermata]).decorations).to eq %i[accent fermata]
  end

  it "scales its length" do
    expect(note.scaled(Rational(3, 2)).rhythmic_duration(duration_resolver).to_s).to eq "dotted quarter"
  end

  it "carries its beam break and grace notes onto its voice event" do
    grace_note = HeadMusic::Content::GraceNote.new(sounds: pitch("D4"), rhythmic_value: :eighth)
    voice_event = HeadMusic::Content::Flow.new.add_voice(role: nil).place("1:1", :quarter, "C4")
    note.with(graces: [grace_note]).carry_onto(voice_event)
    expect([voice_event.beam_break_before, voice_event.grace_notes.length]).to eq [true, 1]
  end

  describe "#tied_to" do
    subject(:tied) { note.tied_to(link, prefix, [:fixed]) }

    let(:link) { described_class.new(pitches: [pitch("C4")], length: "1", scale: Rational(1), slur_marks: [:close], tuplet_ends: [:link_end]) }
    let(:prefix) { note.rhythmic_duration(duration_resolver) }

    it "keeps its own pitches and beam break" do
      expect([tied.pitches, tied.beam_break]).to eq [[pitch("C#4")], true]
    end

    it "renders the whole chain as one value" do
      expect(tied.rhythmic_duration(duration_resolver).to_s).to eq "quarter tied to eighth"
    end

    it "gathers the link's marks after its own" do
      expect([tied.slur_marks, tied.tuplet_ends]).to eq [%i[open close], %i[fixed link_end]]
    end
  end
end
