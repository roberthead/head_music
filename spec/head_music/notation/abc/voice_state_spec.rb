require "spec_helper"

describe HeadMusic::Notation::ABC::VoiceState do
  # Beam and tie bookkeeping do not touch the voice or pitch builder.
  subject(:state) { described_class.new(nil, nil) }

  describe "beam adjacency" do
    it "reports no beam break for the first note" do
      expect(state.next_beam_break).to be_nil
    end

    it "beams a note to the previous one (false) after the first" do
      state.next_beam_break
      expect(state.next_beam_break).to be false
    end

    it "forces a break when one was explicitly marked" do
      state.next_beam_break
      state.mark_beam_break
      expect(state.next_beam_break).to be true
    end

    it "treats the next note as un-beamed after a reset" do
      state.next_beam_break
      state.reset_beam_adjacency
      expect(state.next_beam_break).to be_nil
    end
  end

  describe "ties" do
    it "is not open initially" do
      expect(state).not_to be_tie_open
    end

    it "opens on the line it was seen" do
      state.open_tie(7)
      expect(state).to be_tie_open
      expect(state.tie_line).to eq 7
    end

    it "clears on close" do
      state.open_tie(7)
      state.close_tie
      expect(state).not_to be_tie_open
      expect(state.tie_line).to be_nil
    end
  end

  describe "note assembly" do
    subject(:state) { described_class.new(voice, nil, duration_resolver) }

    let(:voice) { HeadMusic::Content::Composition.new.add_voice(role: nil) }
    let(:duration_resolver) { HeadMusic::Notation::ABC::DurationResolver.new("1/4") }
    let(:pitch) { HeadMusic::Rudiment::Pitch.get("C4") }

    it "places directly, bypassing the buffer" do
      state.place("1", [pitch])
      expect(voice.notes.map { |note| note.pitch.to_s }).to eq ["C4"]
    end

    it "buffers a deferred note until it is flushed" do
      state.defer_placement([pitch], "1")
      expect(voice.notes).to be_empty
      state.flush_pending_note
      expect(voice.notes.map { |note| note.pitch.to_s }).to eq ["C4"]
    end

    it "carries the beam break onto the flushed placement" do
      state.defer_placement([pitch], "1")
      state.mark_beam_break
      state.defer_placement([pitch], "1")
      state.flush_pending_note
      expect(voice.placements.last.beam_break_before).to be true
    end

    it "flushing with nothing pending is a no-op" do
      expect { state.flush_pending_note }.not_to change(voice, :placements)
    end
  end
end
