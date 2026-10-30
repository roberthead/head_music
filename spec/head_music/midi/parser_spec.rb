require "spec_helper"

describe HeadMusic::MIDI::Parser do
  describe "MIDI.parse" do
    subject(:flow) { HeadMusic::MIDI.parse(bytes) }

    let(:written) { HeadMusic::Notation::ABC.parse("X:1\nT:Tune\nM:4/4\nL:1/8\nK:D\nD2 E2 F2 G2 | A4 B2 c2 | d8 |]\n") }
    let(:bytes) { HeadMusic::MIDI.render(written) }
    let(:voice) { flow.voices.first }

    it "reads a one-voice melody as one part of one voice" do
      expect(flow.parts.map { |part| part.voices.length }).to eq [1]
    end

    it "names the flow for the sequence" do
      expect(flow.name).to eq "Tune"
    end

    it "spells the melody" do
      expect(voice.pitches.map(&:to_s)).to eq %w[D4 E4 F♯4 G4 A4 B4 C♯5 D5]
    end

    it "places each note where it was written, with its value" do
      expect(voice.voice_events.map { |event| [event.position.to_s, event.rhythmic_duration.to_s] }).to eq written.voices.first.voice_events.map { |event| [event.position.to_s, event.rhythmic_duration.to_s] }
    end

    it "reads the meter" do
      expect(flow.meter.to_s).to eq "4/4"
    end

    it "leaves no gap in the voice" do
      expect(voice.first_gap).to be_nil
    end

    context "with rests between notes" do
      let(:written) { HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/4\nK:C\nz C z E | z4 | G4 |]\n") }

      it "fills the time between notes with rests" do
        expect(voice.voice_events.map { |event| [event.position.to_s, event.rest? ? "rest" : event.pitches.first.to_s] }).to eq [
          ["1:1:000", "rest"], ["1:2:000", "C4"], ["1:3:000", "rest"], ["1:4:000", "E4"], ["2:1:000", "rest"], ["3:1:000", "G4"]
        ]
      end
    end

    context "with a program, a lyric, and a percussion part" do
      let(:bytes) do
        HeadMusic::MIDI::SMF.file(division: 96, tracks: [
          [HeadMusic::MIDI::Text.new(0, :sequence_name, "Song")],
          [
            HeadMusic::MIDI::Text.new(0, :track_name, "Violin"),
            HeadMusic::MIDI::ProgramChange.new(0, 0, 41),
            HeadMusic::MIDI::Text.new(0, :lyric, "la"),
            HeadMusic::MIDI::NoteOn.new(0, 0, 67, 80),
            HeadMusic::MIDI::NoteOff.new(tick: 384, channel: 0, key: 67)
          ],
          [HeadMusic::MIDI::NoteOn.new(0, 9, 36, 80), HeadMusic::MIDI::NoteOff.new(tick: 96, channel: 9, key: 36)]
        ])
      end

      before do
        allow(HeadMusic::MIDI::InstrumentMap).to receive(:instrument).and_call_original
        allow(HeadMusic::MIDI::LyricAttacher).to receive(:new).and_call_original
      end

      it "asks the instrument map for the program in force, hinted by the track name" do
        flow
        expect(HeadMusic::MIDI::InstrumentMap).to have_received(:instrument).with(41, hint: "Violin")
      end

      it "gives the lyric attacher each lyric's track, snapped time, and text, and each part's note events by onset" do
        events_by_part = {
          HeadMusic::MIDI::PartKey.new(track: 1, channel: 0) => [{0r => flow.parts.first.voices.first.voice_events.first}],
          HeadMusic::MIDI::PartKey.new(track: 2, channel: 9) => [{0r => flow.parts.last.voices.first.voice_events.first}]
        }
        expect(HeadMusic::MIDI::LyricAttacher).to have_received(:new).with([[HeadMusic::MIDI::PartKey.new(track: 1, channel: nil), 0r, "la"]], events_by_part)
      end

      it "plays channel 10 as unpitched sounds" do
        expect(flow.parts.last.voices.first.note_events.first.sounds).to all(satisfy { |sound| !sound.pitched? })
      end
    end

    context "with no notes" do
      let(:bytes) { HeadMusic::MIDI::SMF.file(division: 96, tracks: [[HeadMusic::MIDI::Tempo.new(0, 500_000)]]) }

      it "raises a ParseError" do
        expect { flow }.to raise_error(HeadMusic::MIDI::ParseError, "MIDI file contains no notes")
      end
    end
  end
end
