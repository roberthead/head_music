require "spec_helper"

describe HeadMusic::MIDI::Parser do
  describe "MIDI.parse timeline" do
    def parse(*tracks, **options)
      HeadMusic::MIDI.parse(smf(*tracks), **options)
    end

    def tempos(flow)
      [[1, flow.tempo], *flow.tempo_changes.to_a].map { |bar, tempo| [bar, tempo.beat_value.to_s, tempo.beats_per_minute] }
    end

    def keys(flow)
      [1, *flow.key_signature_changes.keys].map { |bar| [bar, flow.key_signature_at(bar).to_s, flow.timeline.tonal_context_at(bar)&.name] }
    end

    let(:bar) { 384 }

    context "with no time signature, tempo, or key signature" do
      subject(:flow) { parse(midi_line([60, 64, 67, 72], 96)) }

      it "reads 4/4 at 120 quarters a minute" do
        expect([flow.meter.to_s, tempos(flow)]).to eq ["4/4", [[1, "quarter", 120.0]]]
      end
    end

    context "with meter changes" do
      subject(:flow) { parse([time_signature(0, 3, 4), time_signature(576, 2, 4), time_signature(768, 2, 4), *midi_line([60] * 10, 96)]) }

      it "opens in the first meter and changes at each barline, ignoring a restatement" do
        expect([flow.meter.to_s, flow.meter_changes.transform_values(&:to_s)]).to eq ["3/4", {3 => "2/4"}]
      end

      it "places the notes in the bars of each meter" do
        expect(bar_events(flow.voices.first).map(&:first).values_at(5, 6, 8, 9)).to eq %w[2:3:000 3:1:000 4:1:000 4:2:000]
      end
    end

    context "with a pickup" do
      subject(:flow) { parse([time_signature(0, 1, 4), time_signature(96, 4, 4), *midi_line([55, 60, 62, 64, 65], 96)]) }

      it "reads the first bar as a pickup in the meter that follows" do
        expect([flow.meter.to_s, bar_events(flow.voices.first).first(3)]).to eq [
          "4/4", [["0:1:000", "dotted half", "rest"], ["0:4:000", "quarter", "G3"], ["1:1:000", "quarter", "C4"]]
        ]
      end
    end

    context "with a note struck on the final barline" do
      final_notes = {
        "of no length" => [HeadMusic::MIDI::NoteOn.new(384, 0, 62, 80), HeadMusic::MIDI::NoteOff.new(tick: 384, channel: 0, key: 62)],
        "never released" => [HeadMusic::MIDI::NoteOn.new(384, 0, 62, 80)],
        "of no length, a tick early" => [HeadMusic::MIDI::NoteOn.new(383, 0, 62, 80), HeadMusic::MIDI::NoteOff.new(tick: 383, channel: 0, key: 62)],
        "never released, a tick early" => [HeadMusic::MIDI::NoteOn.new(383, 0, 62, 80)]
      }

      final_notes.each do |description, events|
        context description do
          subject(:flow) { parse([*midi_note(0, 60, 383), *events]) }

          it "lays out a bar for it, filled with rests" do
            expect([flow.latest_bar_number, bar_events(flow.voices.first)]).to eq [2, [
              ["1:1:000", "whole", "C4"], ["2:1:000", "sixteenth", "D4"], ["2:1:240", "dotted eighth", "rest"], ["2:2:000", "quarter", "rest"], ["2:3:000", "half", "rest"]
            ]]
          end
        end
      end
    end

    context "with a meter change within a bar" do
      it "raises an UnsupportedFeatureError" do
        expect { parse([time_signature(0, 4, 4), time_signature(480, 3, 4), *midi_line([60] * 8, 96)]) }
          .to raise_error(HeadMusic::MIDI::UnsupportedFeatureError, /within bar/)
      end
    end

    context "with tempo changes" do
      subject(:flow) do
        parse([tempo(0, 500_000), tempo(96, 400_000), tempo(bar * 2, 600_000), tempo(bar * 2 + 96, 300_000), tempo(bar * 2 + 192, 600_000), *midi_line([60] * 4, bar)])
      end

      it "takes the tempo in force at each downbeat, skipping those within a bar" do
        expect(tempos(flow)).to eq [[1, "quarter", 120.0], [2, "quarter", 150.0], [3, "quarter", 100.0]]
      end
    end

    context "with a tempo no whole number of beats a minute writes back" do
      subject(:flow) { parse([tempo(0, 827_586), *midi_line([60], bar)]) }

      it "restates it with the fewest decimals that write back the same microseconds" do
        expect(tempos(flow)).to eq [[1, "quarter", 72.5]]
      end
    end

    context "with a compound meter" do
      subject(:flow) { parse([time_signature(0, 4, 4), tempo(0, 500_000), time_signature(bar, 6, 8), tempo(bar, 666_667), *midi_line([60] * 2, bar)]) }

      it "restates each tempo in its meter's beat" do
        expect(tempos(flow)).to eq [[1, "quarter", 120.0], [2, "dotted quarter", 60.0]]
      end
    end

    context "with a compound meter of whole notes" do
      subject(:flow) { parse([time_signature(0, 6, 1), *midi_note(0, 60, bar * 6), *midi_note(bar * 6, 62, bar * 3)]) }

      it "beats in dotted double wholes" do
        expect([tempos(flow), bar_events(flow.voices.first)]).to eq [
          [[1, "dotted double whole", 10.0]], [["1:1:000", "dotted longa", "C4"], ["2:1:000", "dotted double whole", "D4"], ["2:4:000", "dotted double whole", "rest"]]
        ]
      end
    end

    context "with a tempo so slow in a meter of whole notes that a whole number of beats a minute is 0" do
      subject(:flow) { parse([time_signature(0, 6, 1), tempo(0, 10_000_001), *midi_note(0, 60, bar * 6)]) }

      it "restates it with the fewest decimals that are not 0" do
        expect(tempos(flow)).to eq [[1, "dotted double whole", 0.5]]
      end
    end

    context "with a pickup's time signature a tick short of a quarter" do
      subject(:flow) { parse([time_signature(0, 4, 4), *midi_note(0, 60, 95), time_signature(95, 4, 4), *midi_note(95, 62, bar + 1)]) }

      let(:quarter_pickup) { parse([time_signature(0, 4, 4), *midi_note(0, 60, 96), time_signature(96, 4, 4), *midi_note(96, 62, bar)]) }

      it "reads a quarter pickup" do
        expect([flow.bars.first.number, bar_events(flow.voices.first)]).to eq [0, bar_events(quarter_pickup.voices.first)]
      end
    end

    context "with a pickup's time signature between grid points" do
      subject(:bytes) { smf([time_signature(0, 4, 4), *midi_note(0, 60, 470), time_signature(470, 4, 4), *midi_line([62] * 4, 480, tick: 470)], division: 480) }

      it "raises UnsupportedFeatureError naming its tick" do
        expect { HeadMusic::MIDI.parse(bytes) }.to raise_error(HeadMusic::MIDI::UnsupportedFeatureError, /time signature at tick 470 falls between grid points/)
      end
    end

    context "with a meter change at the same speed" do
      subject(:flow) { parse([time_signature(0, 3, 4), time_signature(288, 6, 8), *midi_line([60] * 4, 144)]) }

      it "makes no tempo change" do
        expect(tempos(flow)).to eq [[1, "quarter", 120.0]]
      end
    end

    context "with key signatures" do
      subject(:flow) do
        parse([key_signature(0, 2), key_signature(bar, 2), key_signature(bar * 2, -3, minor: true), *midi_line([62, 66, 69, 60], bar)])
      end

      it "opens in the first and changes where one differs" do
        expect(keys(flow)).to eq [[1, "2 sharps", "D major"], [3, "3 flats", "C minor"]]
      end

      it "spells each bar in its key" do
        expect(flow.voices.first.note_events.map { |event| event.pitches.first.to_s }).to eq %w[D4 F♯4 A4 C4]
      end
    end

    context "with a key signature within a bar before any note there" do
      subject(:flow) { parse([key_signature(bar + 96, -1), *midi_note(0, 60, bar), *midi_note(bar + 192, 70, 192)]) }

      it "applies at that downbeat" do
        expect(keys(flow).map(&:first)).to eq [1, 2]
        expect(flow.voices.first.note_events.last.pitches.first.to_s).to eq "B♭4"
      end
    end

    context "with a key signature within a bar after a note there" do
      subject(:flow) { parse([key_signature(bar + 96, -1), *midi_note(0, 60, bar), *midi_note(bar, 62, 96), *midi_note(bar * 2, 70, bar)]) }

      it "applies at the next downbeat" do
        expect(keys(flow).map(&:first)).to eq [1, 3]
      end
    end

    context "with a key signature after the first bar only" do
      subject(:flow) { parse([key_signature(bar, 1), *midi_line([60, 66], bar)]) }

      it "opens in C major, as the SMF specification says" do
        expect(keys(flow)).to eq [[1, "no sharps or flats", "C major"], [2, "1 sharp", "G major"]]
      end
    end

    describe "key:" do
      let(:bytes) { smf([key_signature(0, -1), *midi_line([60, 62, 64, 66, 67, 69, 71, 72], 96)]) }

      it "trusts the file's signatures by default" do
        expect(keys(HeadMusic::MIDI.parse(bytes))).to eq [[1, "1 flat", "F major"]]
      end

      it "infers the key and writes its signatures with :infer" do
        expect(keys(HeadMusic::MIDI.parse(bytes, key: :infer))).to eq [[1, "no sharps or flats", "A minor"]]
      end

      it "spells with a key it is given, keeping the file's signatures" do
        flow = HeadMusic::MIDI.parse(bytes, key: "G♭ major")
        expect([keys(flow), flow.voices.first.note_events[3].pitches.first.to_s]).to eq [[[1, "1 flat", "F major"]], "G♭4"]
      end

      it "writes the key it is given where the file has no signature" do
        flow = HeadMusic::MIDI.parse(without(bytes, HeadMusic::MIDI::KeySignature), key: "D major")
        expect(keys(flow)).to eq [[1, "2 sharps", "D major"]]
      end
    end

    # The Aarden tonic-heavy melody of Key and Spelling Inference: Aarden's
    # major profile weights the fifth above the tonic most, so a melody that
    # dwells on its tonic reads as the key a fifth below.
    context "with the Aarden tonic-heavy melody and no key signature" do
      subject(:flow) do
        written = HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/8\nK:C\nC2 D2 E2 F2 | G2 A2 B2 c2 | c8 | c8 |]\n")
        HeadMusic::MIDI.parse(without(HeadMusic::MIDI.render(written), HeadMusic::MIDI::KeySignature))
      end

      it "infers F major" do
        expect(keys(flow)).to eq [[1, "1 flat", "F major"]]
      end

      it "still spells the leading tone as B" do
        expect(flow.voices.first.note_events.map { |event| event.pitches.first.to_s }).to eq %w[C4 D4 E4 F4 G4 A4 B4 C5 C5 C5]
      end
    end

    describe "grid:" do
      let(:bytes) { smf(midi_line([60, 62, 64, 65], 96, tick: 0).each_with_index.map { |event, index| event.with(tick: event.tick + ((index == 2) ? 5 : 0)) }) }

      it "snaps onsets to the grid it is given" do
        expect(bar_events(HeadMusic::MIDI.parse(bytes, grid: Rational(1, 8)).voices.first).map(&:first)).to eq %w[1:1:000 1:2:000 1:3:000 1:4:000]
      end

      it "chooses by default the coarsest grid that places every onset within a tick" do
        expect(bar_events(HeadMusic::MIDI.parse(bytes).voices.first).map(&:first)).to eq %w[1:1:000 1:2:060 1:3:000 1:4:000]
      end
    end
  end
end
