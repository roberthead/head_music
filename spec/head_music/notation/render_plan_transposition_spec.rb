require "spec_helper"

# The written key is a rendering fact, not a fact about the music: one flow in
# C major is read by a flute in C and by a clarinet in D, so the plan answers
# per part rather than per flow.
describe HeadMusic::Notation::RenderPlan do
  subject(:plan) { HeadMusic::Notation::MusicXML::RenderPlan.new(flow, transposed: true) }

  let(:project) { LayoutFixtures.trio }
  let(:flow) { project.flows.first }
  let(:flute) { flow.parts.first }
  let(:clarinet) { flow.parts[1] }
  let(:horn) { flow.parts.last }

  def fifths(part)
    plan.first_measure_key(part)[:fifths]
  end

  describe "a concert-pitch plan" do
    subject(:plan) { HeadMusic::Notation::MusicXML::RenderPlan.new(flow) }

    it "answers the sounding key for every part" do
      expect([fifths(flute), fifths(clarinet), fifths(horn)]).to eq [0, 0, 0]
    end

    it "answers the same key whether or not it is asked about a part" do
      expect(fifths(clarinet)).to eq plan.first_measure_key[:fifths]
    end
  end

  describe "a transposed plan" do
    it "leaves a non-transposing part in the sounding key" do
      expect(fifths(flute)).to eq 0
    end

    it "answers D major for the clarinet" do
      expect(fifths(clarinet)).to eq 2
    end

    it "answers G major for the horn in F" do
      expect(fifths(horn)).to eq 1
    end

    it "still answers the sounding key when asked about no part" do
      expect(plan.first_measure_key[:fifths]).to eq 0
    end
  end

  describe "an instrument change" do
    let(:project) { LayoutFixtures.clarinet_project(pitches: %w[C4 C4 C4 C4]) }
    let(:part) { flow.parts.first }
    let(:other_part) { flow.parts.last }

    before do
      part.change_instrument(3, "clarinet_in_a")
      flow.add_part(instrument: "flute").add_voice(role: "flute").place("1:1", :whole, "C4")
    end

    it "changes the written key at the bar the player picks up the other instrument" do
      expect(plan.measure_key_changes(part)[3][:fifths]).to eq(-3)
    end

    it "changes no other part's key" do
      expect(plan.measure_key_changes(other_part)).to be_empty
    end

    it "leaves the sounding timeline alone" do
      expect(flow.key_signature_changes).to be_empty
    end

    it "adds no change where the new instrument reads in the same key" do
      part.change_instrument(3, "clarinet")
      expect(plan.measure_key_changes(part)).to be_empty
    end
  end

  describe "a written key that cannot be printed" do
    let(:project) { LayoutFixtures.clarinet_project }

    before { flow.change_key_signature(1, 6, tonal_context: HeadMusic::Rudiment::Key.get("F♯ major")) }

    it "raises when the plan is built, before any assembly" do
      expect { plan }.to raise_error HeadMusic::Notation::RenderError, /no key signature prints/
    end
  end
end
