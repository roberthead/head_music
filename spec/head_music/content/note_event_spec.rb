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
end
