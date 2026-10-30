require "spec_helper"

describe HeadMusic::Notation::VoiceTrack do
  subject(:track) { described_class.new("P1 voice 1") }

  let(:quarter) { HeadMusic::Rudiment::RhythmicValue.get("quarter") }
  let(:eighth) { HeadMusic::Rudiment::RhythmicValue.get("eighth") }

  def pitches(*names)
    names.map { |name| HeadMusic::Rudiment::Pitch.get(name) }
  end

  def add(names, tie_starts: [], tie_stops: [])
    track.add(rhythmic_duration: quarter, sounds: pitches(*names), tie_starts: tie_starts, tie_stops: tie_stops)
  end

  def grace(names, tie_starts: [])
    track.queue_grace(sounds: pitches(*names), rhythmic_value: eighth, slashed: false, articulations: [], tie_starts: tie_starts)
  end

  describe "#add" do
    it "hands the event every grace note queued before it" do
      graces = [grace(["D4"]), grace(["E4"])]
      event = add(["F4"])
      expect(event.graces).to eq graces
      expect(graces.map(&:event)).to all(equal(event))
      expect(track.queued_graces).to be_empty
    end

    it "counts the links of the event's written value" do
      duration = HeadMusic::Notation::DottedDuration.rhythmic_duration_for(Rational(5, 4))
      event = track.add(rhythmic_duration: duration, sounds: pitches("C4"), tie_starts: [], tie_stops: [])
      expect(event.link_count).to eq 2
    end
  end

  describe "an event's ties" do
    it "ties out when every pitch starts a tie" do
      expect(add(%w[C4 E4], tie_starts: %w[C4 E4])).to be_ties_out
    end

    it "does not tie out when only some pitches start one" do
      expect(add(%w[C4 E4], tie_starts: %w[C4])).not_to be_ties_out
    end

    it "ties in when every pitch stops a tie" do
      expect(add(%w[C4], tie_stops: %w[C4])).to be_ties_in
    end

    it "never ties a rest" do
      expect(add([], tie_starts: [])).not_to be_ties_out
    end

    it "keys its pitches in sorted order" do
      expect(add(%w[G4 C4]).keys).to eq %w[C4 G4]
    end
  end

  describe "#tie_graces" do
    it "ties a grace note to the next one where they share a pitch" do
      first = grace(%w[D4], tie_starts: %w[D4])
      second = grace(%w[D4])
      add(%w[F4])
      track.tie_graces
      expect([first.tied, second.tied]).to eq [true, false]
    end

    it "lets a tie into the main note take the place of the stop it carries" do
      lead = grace(%w[C4], tie_starts: %w[C4])
      event = add(%w[C4], tie_stops: %w[C4])
      track.tie_graces
      expect(lead.tied).to be true
      expect(event.tie_stops).to be_empty
    end

    it "answers the grace notes that lead to nothing" do
      add(%w[C4])
      trailing = grace(%w[D4])
      expect(track.tie_graces).to eq [trailing]
    end
  end

  describe "Grace#tie_to" do
    it "answers the pitches it ties to" do
      lead = grace(%w[C4 E4], tie_starts: %w[C4 E4])
      expect(lead.tie_to(pitches("E4", "G4"))).to eq %w[E4]
      expect(lead.tied).to be true
    end
  end

  describe "Event#place_on" do
    let(:flow) { HeadMusic::Content::Flow.new }
    let(:voice) { flow.add_voice }

    it "places the event with its grace notes" do
      grace(%w[D4])
      event = add(%w[C4])
      voice_event = event.place_on(voice, flow.position(1, 1, 0))
      expect(event.voice_event).to equal voice_event
      expect(voice_event.grace_notes.length).to eq 1
    end

    it "drops the grace notes before a rest" do
      grace(%w[D4])
      event = add([])
      expect(event.place_on(voice, flow.position(1, 1, 0))).to be_rest
    end
  end
end
