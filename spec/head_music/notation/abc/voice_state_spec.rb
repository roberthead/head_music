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
end
