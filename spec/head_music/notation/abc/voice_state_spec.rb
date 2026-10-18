require "spec_helper"

describe HeadMusic::Notation::ABC::VoiceState do
  # Tie bookkeeping does not touch the voice or pitch builder.
  subject(:state) { described_class.new(nil, nil) }

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

    let(:voice) { HeadMusic::Content::Flow.new.add_voice(role: nil) }
    let(:duration_resolver) { HeadMusic::Notation::ABC::DurationResolver.new("1/4") }
    let(:pitch) { HeadMusic::Rudiment::Pitch.get("C4") }

    it "places directly, bypassing the buffer" do
      state.place("1", [pitch])
      expect(voice.notes.map { |note| note.pitch.to_s }).to eq ["C4"]
    end

    it "buffers a deferred note until it is flushed" do
      state.defer_voice_event([pitch], "1")
      expect(voice.notes).to be_empty
      state.flush_pending_note
      expect(voice.notes.map { |note| note.pitch.to_s }).to eq ["C4"]
    end

    it "carries the beam break onto the flushed voice event" do
      state.defer_voice_event([pitch], "1")
      state.beams.mark_break
      state.defer_voice_event([pitch], "1")
      state.flush_pending_note
      expect(voice.voice_events.last.beam_break_before).to be true
    end

    it "flushing with nothing pending is a no-op" do
      expect { state.flush_pending_note }.not_to change(voice, :voice_events)
    end
  end

  describe "invisible rests" do
    subject(:state) { described_class.new(voice, nil, duration_resolver) }

    let(:voice) { HeadMusic::Content::Flow.new.add_voice(role: nil) }
    let(:duration_resolver) { HeadMusic::Notation::ABC::DurationResolver.new("1/4") }
    let(:pitch) { HeadMusic::Rudiment::Pitch.get("C4") }

    it "runs the cursor ahead of the voice events" do
      state.place("1", [pitch])
      state.skip("2")
      expect([voice.voice_events.length, state.cursor.to_s]).to eq [1, "1:4:000"]
    end

    it "numbers the bar entered by the cursor" do
      state.skip("4")
      expect([state.completed_bar_number, state.entered_bar_number]).to eq [1, 2]
    end

    it "places the waiting invisible rests as rests before the next voice event" do
      state.skip("2")
      state.place("1", [pitch])
      expect(voice.voice_events.map(&:to_s)).to eq ["half rest at 1:1:000", "quarter C4 at 1:3:000"]
    end

    it "places a level on an invisible rest where it starts" do
      state.place("1", [pitch])
      state.decorate(HeadMusic::Notation::ABC::Decoration.new(kind: :level, key: "f", line: 1, lexeme: "!f!"))
      state.skip("1")
      expect(voice.dynamic_events.map(&:to_h)).to eq [{"position" => "1:2:000", "level" => "f"}]
    end
  end

  describe "hairpin marks" do
    subject(:state) { described_class.new(voice, nil, duration_resolver) }

    let(:voice) { HeadMusic::Content::Flow.new.add_voice(role: nil) }
    let(:duration_resolver) { HeadMusic::Notation::ABC::DurationResolver.new("1/4") }
    let(:pitch) { HeadMusic::Rudiment::Pitch.get("C4") }

    def mark(lexeme)
      HeadMusic::Notation::ABC::Decoration.new(**HeadMusic::Notation::ABC::DecorationMapper.classify(lexeme), line: 1, lexeme: lexeme)
    end

    def defer(lexeme, length)
      state.decorate(mark(lexeme))
      state.defer_voice_event([pitch], length)
    end

    def hairpins
      state.flush_pending_note
      state.add_hairpins
      voice.spans.map(&:to_s)
    end

    it "places a mark on a tie's later link where that link starts" do
      defer("!<(!", "2")
      state.open_tie(1)
      defer("!<)!", "2")
      expect([hairpins, voice.voice_events.map(&:to_s)])
        .to eq [["crescendo from 1:1:000 to 1:3:000"], ["half tied to half C4 at 1:1:000"]]
    end

    it "keeps a mark on a rest" do
      state.decorate(mark("!>(!"))
      state.place("2", nil)
      defer("!>)!", "2")
      expect(hairpins).to eq ["diminuendo from 1:1:000 to 1:3:000"]
    end

    it "settles a waiting mark where the voice's time has reached" do
      defer("!<(!", "4")
      state.decorate(mark("!<)!"))
      state.settle_hairpins
      expect(hairpins).to eq ["crescendo from 1:1:000 to 2:1:000"]
    end
  end
end
