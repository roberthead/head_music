require "spec_helper"

describe HeadMusic::MIDI::Parser do
  describe "MIDI.parse lyrics" do
    def sung(voice)
      voice.note_events.map do |event|
        event.syllables.values.map { |syllable| [syllable.verse, syllable.text, syllable.hyphen_after] }
      end
    end

    context "with hyphens and two verses" do
      subject(:flow) do
        HeadMusic::MIDI.parse(smf([
          *midi_line([60, 62, 64, 65], 96),
          lyric(0, "Hel-"), lyric(96, "lo"), lyric(192, "one"), lyric(192, "two"), lyric(288, "-"), lyric(300, "stray")
        ]))
      end

      it "sings each syllable on the note it falls on, a trailing hyphen setting hyphen_after" do
        expect(sung(flow.voices.first).first(2)).to eq [[[1, "Hel", true]], [[1, "lo", false]]]
      end

      it "sings several lyrics at one onset as successive verses" do
        expect(sung(flow.voices.first)[2]).to eq [[1, "one", false], [2, "two", false]]
      end

      it "skips a standalone hyphen and a lyric on no onset" do
        expect(sung(flow.voices.first)[3]).to eq []
      end
    end

    context "with lyrics in a track that has no notes" do
      subject(:flow) { HeadMusic::MIDI.parse(smf([lyric(96, "la")], midi_line([60, 62], 96), midi_line([48, 50], 96, channel: 1))) }

      it "sings them on the first part with an onset there" do
        expect(flow.parts.map { |part| sung(part.voices.first) }).to eq [[[], [[1, "la", false]]], [[], []]]
      end
    end

    context "with a flow MIDI Export wrote" do
      subject(:flow) do
        written = HeadMusic::Content::Flow.new(meter: "3/4", key_signature: "F major")
        voice = written.add_voice
        [["1:1", "F4", "Glo", true], ["1:2", "G4", "ri", true], ["1:3", "A4", "a", false], ["2:1", "C5", "to", false]].each do |position, pitch, text, hyphen|
          voice.place(position, :quarter, pitch).sing(text, hyphen_after: hyphen)
        end
        HeadMusic::MIDI.parse(HeadMusic::MIDI.render(written))
      end

      it "reads its lyrics back" do
        expect(sung(flow.voices.first).flatten(1).map { |_verse, text, hyphen| [text, hyphen] }).to eq [["Glo", true], ["ri", true], ["a", false], ["to", false]]
      end
    end
  end
end
