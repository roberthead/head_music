require "spec_helper"

describe HeadMusic::MIDI::Parser do
  describe "MIDI.parse parts and voices" do
    def parse(*tracks, **options)
      HeadMusic::MIDI.parse(smf(*tracks, **options))
    end

    def pitches(voice)
      voice.note_events.map { |event| event.pitches.join(" ") }
    end

    context "with a format 0 file" do
      subject(:flow) do
        parse([HeadMusic::MIDI::Text.new(0, :sequence_name, "Song"), *midi_line([60, 62], 192, channel: 1), *midi_line([48, 50], 192, channel: 0)], format: 0)
      end

      it "makes a part of each channel, in channel order" do
        expect(flow.parts.map { |part| pitches(part.voices.first) }).to eq [%w[C3 D3], %w[C4 D4]]
      end

      it "names the flow for the track, and no part for it" do
        expect([flow.name, flow.parts.map(&:player)]).to eq ["Song", [nil, nil]]
      end
    end

    context "with a format 1 file" do
      subject(:flow) do
        parse(
          [HeadMusic::MIDI::Text.new(0, :track_name, "Duet"), tempo(0, 500_000)],
          [track_name("Upper"), *midi_line([72, 74], 192), *midi_line([67], 384, channel: 2)],
          [track_name("Lower"), *midi_line([48], 384, channel: 1)]
        )
      end

      it "makes a part of each track and channel, by track and then channel" do
        expect(flow.parts.map { |part| pitches(part.voices.first) }).to eq [%w[C5 D5], %w[G4], %w[C3]]
      end

      it "names the flow for a first track with no notes, and each part's player for its track" do
        expect([flow.name, flow.parts.map { |part| part.player&.name }]).to eq ["Duet", %w[Upper Upper Lower]]
      end
    end

    context "with notes in the first track of a format 1 file" do
      subject(:flow) { parse([track_name("Piano"), *midi_line([60], 384)], [track_name("Bass"), *midi_line([36], 384, channel: 1)]) }

      it "names a player for the first track, not the flow" do
        expect([flow.name, flow.parts.map { |part| part.player&.name }]).to eq ["Composition", %w[Piano Bass]]
      end
    end

    context "with a later track that has a name or a program but no notes" do
      subject(:flow) do
        parse(
          [tempo(0, 500_000)],
          [track_name("Melody"), *midi_line([60, 62, 64, 65, 67], 96)],
          [track_name("Tacet")],
          [program(0, 41, channel: 3)],
          [lyric(0, "la")]
        )
      end

      it "makes a part of rests for each, but not for one with neither" do
        expect(flow.parts.map { |part| [part.player&.name, part.instrument&.name_key] }).to eq [["Melody", nil], ["Tacet", nil], [nil, :violin]]
      end

      it "rests through every bar of the flow" do
        expect(flow.parts.drop(1).map { |part| bar_events(part.voices.first) }).to all(eq [["1:1:000", "whole", "rest"], ["2:1:000", "whole", "rest"]])
      end
    end

    context "with a format 0 file that has no notes on a channel it sets a program on" do
      subject(:flow) { parse([program(0, 41, channel: 1), *midi_line([60], 384)], format: 0) }

      it "makes no part of rests" do
        expect(flow.parts.length).to eq 1
      end
    end

    context "with 16 parts on 16 channels" do
      subject(:flow) do
        parse(*(0..15).map { |channel| [program(0, channel + 1, channel: channel), *midi_line([40 + channel], 384, channel: channel)] })
      end

      it "makes a part of each, in order, percussion on channel 10" do
        expect(flow.parts.map { |part| part.voices.first.note_events.first.sounds.first.pitched? }).to eq Array.new(16) { |channel| channel != 9 }
      end

      it "gives each pitched part the instrument of its program" do
        expect(flow.parts.first.instrument.name_key).to eq :piano
      end
    end

    context "with overlapping lines in one part" do
      subject(:flow) do
        parse([*midi_note(0, 72, 384), *midi_note(0, 60, 96), *midi_note(96, 62, 96), *midi_note(192, 64, 192), *midi_note(384, 79, 384)])
      end

      it "separates them into voices, top first, each chord to the nearest free voice" do
        expect(flow.parts.first.voices.map { |voice| pitches(voice) }).to eq [%w[C5 G5], %w[C4 D4 E4]]
      end

      it "spans the flow with the first voice, and trims a later voice's whole bars of rest" do
        expect(flow.parts.first.voices.map { |voice| bar_events(voice).length }).to eq [2, 3]
      end

      it "leaves no gap in any voice" do
        expect(flow.voices.map(&:first_gap)).to all(be_nil)
      end

      it "places every voice in order" do
        expect(flow.voices.map(&:revision)).to all(be_zero)
      end
    end

    context "with a later voice that opens after whole bars of rest" do
      subject(:flow) { parse([*midi_note(0, 72, 384 * 3), *midi_note(384 * 2, 60, 192)]) }

      it "leaves the empty bars out of the later voice" do
        expect(bar_events(flow.parts.first.voices.last)).to eq [["3:1:000", "half", "C4"], ["3:3:000", "half", "rest"]]
      end
    end

    context "with chords" do
      subject(:flow) { parse([*midi_note(0, 60, 384), *midi_note(0, 64, 384), *midi_note(0, 67, 384)]) }

      it "makes one voice event of notes that start and end together" do
        expect(bar_events(flow.voices.first)).to eq [["1:1:000", "whole", "C4 E4 G4"]]
      end
    end

    context "with a note released in another track" do
      subject(:flow) { parse([HeadMusic::MIDI::NoteOn.new(0, 0, 60, 80)], [HeadMusic::MIDI::NoteOff.new(tick: 192, channel: 0, key: 60), *midi_note(192, 62, 192)]) }

      it "pairs it across tracks, keeping it in the track of its note on" do
        expect(flow.parts.map { |part| bar_events(part.voices.first) }).to eq [
          [["1:1:000", "half", "C4"], ["1:3:000", "half", "rest"]],
          [["1:1:000", "half", "rest"], ["1:3:000", "half", "D4"]]
        ]
      end
    end

    context "with a note never released" do
      subject(:flow) { parse([HeadMusic::MIDI::NoteOn.new(0, 0, 60, 80), *midi_note(0, 64, 96), HeadMusic::MIDI::EndOfTrack.new(384)]) }

      it "ends it at the end of its track" do
        expect(flow.voices.map { |voice| bar_events(voice).first }).to eq [["1:1:000", "quarter", "E4"], ["1:1:000", "whole", "C4"]]
      end
    end

    context "with a key struck again while it sounds" do
      subject(:flow) do
        parse([
          HeadMusic::MIDI::NoteOn.new(0, 0, 60, 80), HeadMusic::MIDI::NoteOn.new(96, 0, 60, 80),
          HeadMusic::MIDI::NoteOff.new(tick: 192, channel: 0, key: 60), HeadMusic::MIDI::NoteOff.new(tick: 384, channel: 0, key: 60)
        ])
      end

      it "releases the earliest note on first" do
        expect(flow.voices.map { |voice| bar_events(voice).reject { |_, _, sounds| sounds == "rest" } }).to eq [
          [["1:1:000", "half", "C4"]], [["1:2:000", "dotted half", "C4"]]
        ]
      end
    end
  end
end
