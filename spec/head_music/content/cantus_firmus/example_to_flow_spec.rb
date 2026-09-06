require "spec_helper"

# An example is a catalog datum -- a pitch list with a mode and a citation --
# which nothing in the gem turned into music. Realizing it as a standalone flow
# is what a chunk of music outside a project looks like.
describe HeadMusic::Content::CantusFirmus::Example do
  subject(:flow) { example.to_flow }

  let(:example) { described_class.all.first }

  it "needs no project" do
    expect(flow.project).to be_nil
  end

  it "puts the melody in one part" do
    expect(flow.parts.length).to eq 1
  end

  it "leaves that part without a player, which makes it a staff of music" do
    expect(flow.parts.first).not_to be_player
  end

  it "sounds the example's pitches in order" do
    expect(flow.voices.first.pitches.map(&:to_s)).to eq example.pitches.map { |pitch| HeadMusic::Rudiment::Pitch.get(pitch).to_s }
  end

  it "names the voice for what it is" do
    expect(flow.voices.first.role).to eq "cantus firmus"
  end

  it "places one note per bar" do
    expect(flow.voices.first.placements.map { |placement| placement.position.bar_number }).to eq (1..example.length).to_a
  end

  # The mode is carried by the tonal context, not inferred from the signature,
  # which is what lets an example in E phrygian and one in D dorian share a
  # signature of zero without collapsing into each other.
  it "keeps the mode as the opening tonal context" do
    expect(flow.timeline.tonal_context_at(1).name).to eq "D dorian"
  end

  it "takes the signature from the mode's own collection" do
    expect(flow.timeline.signature_at(1)).to eq 0
  end

  it "distinguishes two modes that share a signature" do
    phrygian = described_class.all.find { |candidate| candidate.mode == :phrygian }
    skip "no phrygian example in the catalog" unless phrygian
    expect(phrygian.to_flow.timeline.tonal_context_at(1).name).not_to eq flow.timeline.tonal_context_at(1).name
  end

  describe "the realization's own choices" do
    it "uses whole notes by default" do
      expect(flow.voices.first.placements.first.rhythmic_value.to_s).to eq "whole"
    end

    it "takes a rhythmic value" do
      expect(example.to_flow(rhythmic_value: :half).voices.first.placements.first.rhythmic_value.to_s).to eq "half"
    end

    it "takes a meter" do
      expect(example.to_flow(meter: "3/4").meter.to_s).to eq "3/4"
    end
  end

  describe "rendering without a project" do
    it "renders to LilyPond" do
      expect(flow.to_lilypond).to include "\\score {"
    end

    it "renders to ABC" do
      expect(flow.to_abc).to include "K:"
    end

    it "renders to MusicXML" do
      expect(flow.to_musicxml).to include "<score-partwise"
    end
  end
end
