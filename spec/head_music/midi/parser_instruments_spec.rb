require "spec_helper"

describe HeadMusic::MIDI::Parser do
  describe "MIDI.parse instruments" do
    def parse(*tracks)
      HeadMusic::MIDI.parse(smf(*tracks))
    end

    let(:bar) { 384 }

    context "with a program" do
      subject(:part) { parse([program(0, 41), *midi_line([67, 69], bar)]).parts.first }

      it "gives the part the program's instrument" do
        expect(part.instrument.name_key).to eq :violin
      end
    end

    context "with no program" do
      subject(:part) { parse(midi_line([67, 69], bar)).parts.first }

      it "gives the part no instrument" do
        expect(part.instrument).to be_nil
      end
    end

    context "with a program no catalog instrument has" do
      subject(:part) { parse([program(0, 126), *midi_line([67], bar)]).parts.first }

      it "gives the part no instrument" do
        expect(part.instrument).to be_nil
      end
    end

    context "with an ambiguous program and a track name" do
      subject(:flow) do
        parse([track_name("alto saxophone"), program(0, 66), *midi_line([67], bar)], [track_name("tenor saxophone"), program(0, 67, channel: 1), *midi_line([60], bar, channel: 1)])
      end

      it "resolves the program through the name" do
        expect(flow.parts.map { |part| part.instrument.name_key }).to eq %i[alto_saxophone tenor_saxophone]
      end
    end

    context "with an instrument name and a track name" do
      subject(:part) do
        parse([track_name("Mr. Smith"), HeadMusic::MIDI::Text.new(0, :instrument_name, "trombone"), program(0, 58), *midi_line([48], bar)]).parts.first
      end

      it "resolves the program through whichever names an instrument with it" do
        expect([part.instrument.name_key, part.player.name]).to eq [:trombone, "Mr. Smith"]
      end
    end

    context "with a track name that is the instrument's name" do
      subject(:part) { parse([track_name("Violin"), program(0, 41), *midi_line([67], bar)]).parts.first }

      it "names no player, ignoring case" do
        expect([part.instrument.name_key, part.player]).to eq [:violin, nil]
      end
    end

    context "with a program change before a later note" do
      subject(:part) do
        parse([program(0, 72), *midi_note(0, 67, 96), program(bar + 96, 41), *midi_note(bar + 192, 69, 96), *midi_note(bar * 2, 71, 96)]).parts.first
      end

      it "changes the instrument at the bar of the next note on" do
        expect([part.instrument.name_key, part.instrument_changes.transform_values(&:name_key)]).to eq [:clarinet, {2 => :violin}]
      end
    end

    context "with a program change in a bar before a bar with no notes" do
      subject(:part) do
        parse([program(0, 72), *midi_note(0, 67, 96), program(96, 41), *midi_note(bar * 2, 69, 96)]).parts.first
      end

      it "changes the instrument at the bar of the channel's next note on" do
        expect(part.instrument_changes.transform_values(&:name_key)).to eq(3 => :violin)
      end
    end

    context "with a program set again to the program in force" do
      subject(:part) { parse([program(0, 41), *midi_note(0, 67, 96), program(bar, 41), *midi_note(bar, 69, 96)]).parts.first }

      it "makes no instrument change" do
        expect(part.instrument_changes).to eq({})
      end
    end

    context "with a program set in another track on the part's channel" do
      subject(:part) { parse([program(0, 41)], midi_line([67], bar)).parts.first }

      it "takes the program in force on the channel" do
        expect(part.instrument.name_key).to eq :violin
      end
    end
  end
end
