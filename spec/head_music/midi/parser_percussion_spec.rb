require "spec_helper"

describe HeadMusic::MIDI::Parser do
  describe "MIDI.parse percussion" do
    def parse(*tracks)
      HeadMusic::MIDI.parse(smf(*tracks))
    end

    def drum(tick, key, length = 96)
      midi_note(tick, key, length, channel: 9)
    end

    def sounds(part)
      part.voices.flat_map { |voice| voice.note_events.map { |event| event.sounds.map(&:to_s) } }
    end

    context "with a kit on channel 10" do
      subject(:flow) { parse([*midi_line([60], 384)], [*drum(0, 36), *drum(0, 42, 48), *drum(96, 38), *drum(192, 35), *drum(288, 39)]) }

      it "maps keys to sounds, through an alias where a key has no instrument of its own, else to the generic sound" do
        expect(sounds(flow.parts.last)).to eq [["bass drum", "hi hat"], ["snare drum"], ["bass drum"], ["unpitched"]]
      end

      it "groups notes struck together into one chord, whatever their releases" do
        expect(flow.parts.last.voices.first.note_events.first.rhythmic_duration.to_s).to eq "quarter"
      end

      it "gives the part a drum kit when its sounds are of several instruments" do
        expect(flow.parts.last.instrument.name_key).to eq :drum_kit
      end
    end

    context "with sounds all of one instrument" do
      subject(:part) { parse([*drum(0, 38), *drum(96, 40)]).parts.first }

      it "gives the part that instrument" do
        expect(part.instrument.name_key).to eq :snare_drum
      end
    end

    context "with a track name that names an unpitched instrument" do
      subject(:part) { parse([track_name("tambourine"), *drum(0, 54), *drum(96, 36)]).parts.first }

      it "gives the part that instrument, and no player" do
        expect([part.instrument.name_key, part.player]).to eq [:tambourine, nil]
      end
    end

    context "with a program change on channel 10" do
      subject(:part) { parse([program(0, 41, channel: 9), *drum(0, 38), program(384, 1, channel: 9), *drum(384, 38)]).parts.first }

      it "ignores it" do
        expect([part.instrument.name_key, part.instrument_changes]).to eq [:snare_drum, {}]
      end
    end

    context "with percussion on channel 10 of a track that plays pitched notes" do
      subject(:flow) { parse([*midi_line([60, 62], 192), *drum(0, 38)]) }

      it "makes it a part of its own" do
        expect(flow.parts.map { |part| sounds(part) }).to eq [[["C4"], ["D4"]], [["snare drum"]]]
      end
    end
  end
end
