require "spec_helper"

describe HeadMusic::Content::NoteEvent do
  let(:voice) { HeadMusic::Content::Flow.new.add_voice }

  it "is a voice event" do
    expect(described_class.new(voice, "1:1", :quarter, "C4")).to be_a HeadMusic::Content::VoiceEvent
  end

  it "requires a sound" do
    expect { described_class.new(voice, "1:1", :quarter, []) }
      .to raise_error(ArgumentError, "a note event needs at least one sound; place a rest instead")
  end

  it "holds a chord" do
    expect(described_class.new(voice, "1:1", :quarter, %w[C4 E4 G4])).to be_chord
  end

  it "holds an unpitched sound" do
    expect(described_class.new(voice, "1:1", :quarter, "snare drum")).to be_unpitched_note
  end

  it "is not a rest" do
    expect(described_class.new(voice, "1:1", :quarter, "C4")).not_to be_rest
  end

  it "refuses to merge a note event of another length" do
    note = described_class.new(voice, "1:1", :quarter, "C4")
    other = described_class.new(voice, "1:1", :half, "E4")
    expect { note.merge(other) }
      .to raise_error(ArgumentError, "cannot place a half at 1:1:000: position occupied by a quarter")
  end

  describe "markings" do
    subject(:note_event) { described_class.new(voice, "1:1", :quarter, "C5") }

    it "carries no markings until marked" do
      expect(note_event).to have_attributes(articulations: [], ornaments: [], note_dynamic: nil)
    end

    it "carries several articulations, sorted by key" do
      note_event.articulate(:tenuto, :accent)
      expect(note_event.articulations.map(&:name_key)).to eq %w[accent tenuto]
    end

    it "ignores an articulation it already carries" do
      note_event.articulate(:staccato).articulate("staccato")
      expect(note_event.articulations.map(&:name_key)).to eq %w[staccato]
    end

    it "carries ornaments" do
      note_event.embellish(:trill, :upper_mordent)
      expect(note_event.ornaments.map(&:name_key)).to eq %w[inverted_mordent trill]
    end

    it "answers itself so calls chain" do
      expect(note_event.articulate(:staccato).embellish(:turn)).to be note_event
    end

    it "answers a frozen list" do
      expect(note_event.articulate(:staccato).articulations).to be_frozen
    end

    it "refuses an unknown articulation" do
      expect { note_event.articulate(:bogus) }.to raise_error(ArgumentError, "unknown articulation: :bogus")
    end

    it "refuses an unknown ornament" do
      expect { note_event.embellish(:bogus) }.to raise_error(ArgumentError, "unknown ornament: :bogus")
    end

    it "holds an accent as its note dynamic" do
      note_event.note_dynamic = :sfz
      expect(note_event.note_dynamic).to be HeadMusic::Rudiment::Dynamic.get(:sfz)
    end

    it "clears its note dynamic with nil" do
      note_event.note_dynamic = :fp
      note_event.note_dynamic = nil
      expect(note_event.note_dynamic).to be_nil
    end

    it "refuses a level as its note dynamic" do
      expect { note_event.note_dynamic = :f }
        .to raise_error(ArgumentError, "f is a level, not an accent; place it on the voice with place_dynamic")
    end

    it "refuses an unknown note dynamic" do
      expect { note_event.note_dynamic = :loud }.to raise_error(ArgumentError, "unknown dynamic: :loud")
    end

    it "leaves the sounds and timing alone" do
      note_event.articulate(:staccato).embellish(:trill).note_dynamic = :sf
      expect(note_event.to_s).to eq "quarter C5 at 1:1:000"
    end
  end
end
