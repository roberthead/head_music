require "spec_helper"

describe HeadMusic::Notation::LilyPond::SegmentTokens do
  def segment_tokens(voice)
    segments = HeadMusic::Notation::BarSplitter.segments(voice.voice_events)
    described_class.new(voice, segments, HeadMusic::Notation::LilyPond::TimedMarks.voice(voice))
  end

  let(:voice) { MarkingFixtures.four_quarters.voices.first }

  it "answers each segment's words in the voice's order" do
    expect(segment_tokens(voice).to_h.values).to eq ["c'4", "d'4", "e'4", "f'4", "g'1"]
  end

  it "writes a slur on the segments it opens and closes on" do
    voice.add_span(:slur, from: "1:1", to: "1:3")
    expect(segment_tokens(voice).to_h.values.first(3)).to eq ["c'4(", "d'4", "e'4)"]
  end

  it "writes the voice's levels among its links" do
    voice.place_dynamic("1:2", "p")
    expect(segment_tokens(voice).to_h.values[1]).to eq "d'4\\p"
  end

  it "splits a voice event at a barline into tied segments" do
    flow = HeadMusic::Content::Flow.new(key_signature: "C major", meter: "4/4")
    tied_over = flow.add_voice
    tied_over.place("1:1", "dotted half", "C4")
    tied_over.place("1:4", :half, "D4")
    expect(segment_tokens(tied_over).to_h.values).to eq ["c'2.", "d'4~", "d'4"]
  end

  it "keys each tuplet bracket's edges by the segment and link they stand at" do
    edges = segment_tokens(TupletFixtures.tuplet_crossing_barline.voices.first).tuplet_edges
    expect([edges[:opens].values, edges[:closes].values]).to eq [["\\tuplet 3/2 { "], [" }"]]
  end
end
