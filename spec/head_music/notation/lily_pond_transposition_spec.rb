require "spec_helper"

# \transposition names where a written c' sounds. The reader moves what is
# written after it to concert pitch, and the writer states it for a part
# written at its instrument's pitch, restating it where the instrument changes.
describe HeadMusic::Notation::LilyPond do
  def pitches(source)
    described_class.parse(source).voices.map { |voice| voice.pitches.map(&:to_s) }
  end

  def key_name(source)
    described_class.parse(source).key_signature.name
  end

  def written(flow)
    project = flow.project || HeadMusic::Content::Project.new(name: flow.name.to_s).tap { |adopting| adopting.add_flow(flow) }
    project.add_layout(kind: :score, concert_pitch: false).realize(flow)
  end

  def flow_for(*instruments, key_signature: "D major")
    HeadMusic::Content::Flow.new(name: "Transposed", meter: "4/4", key_signature: key_signature).tap do |flow|
      part = flow.add_part(instrument: instruments.first)
      instruments.drop(1).each.with_index(2) { |instrument, bar| part.change_instrument(bar, instrument) }
      voice = part.add_voice
      instruments.each.with_index(1) do |_instrument, bar|
        voice.place("#{bar}:1", :half, "D4")
        voice.place("#{bar}:3", :half, "F♯4")
      end
    end
  end

  def round_trip(flow)
    described_class.parse(described_class.render(written(flow), transposed: true))
  end

  def music(flow)
    [flow.key_signature.name, flow.voices.map { |voice| voice.pitches.map(&:to_s) }]
  end

  describe "reading \\transposition" do
    it "reads the notes after it at concert pitch" do
      expect(pitches("{ \\transposition bes d''2 e''2 }")).to eq [%w[C5 D5]]
    end

    it "reads a key written after it at concert pitch" do
      expect(key_name("{ \\transposition a \\key f \\major f''1 }")).to eq "D major"
    end

    it "reads a key written just before it at concert pitch" do
      expect(key_name("{ \\key f \\major \\transposition a f''1 }")).to eq "D major"
    end

    it "leaves a key written before the music alone" do
      expect(key_name("{ \\key f \\major f''1 \\transposition a f''1 }")).to eq "F major"
    end

    it "reads its pitch as absolute inside \\relative, without moving the reference" do
      expect(pitches("\\relative c'' { \\transposition bes c1 \\transposition c' d1 \\transposition a, e1 }"))
        .to eq [%w[B♭4 D5 C♯4]]
    end

    it "moves chords and grace notes" do
      flow = described_class.parse("{ \\transposition bes \\grace d''8 <c'' e''>1 }")
      voice_event = flow.voices.first.voice_events.first
      expect([voice_event.pitches.map(&:to_s), voice_event.grace_notes.flat_map { |grace| grace.sounds.map(&:to_s) }])
        .to eq [%w[B♭4 D5], %w[C5]]
    end

    it "keeps a tie between notes it moves" do
      expect(pitches("{ \\transposition bes c''2~ c''2 }")).to eq [%w[B♭4]]
    end

    it "reads a staff's transposition in the voice inside it" do
      expect(pitches("\\new Staff { \\transposition a \\new Voice { c''1 } }")).to eq [%w[A4]]
    end

    it "reads a concert staff and a transposed staff in the same key" do
      source = "<< \\new Staff { \\key d \\major d''1 } \\new Staff { \\transposition a \\key f \\major f''1 } >>"
      expect([key_name(source), pitches(source)]).to eq ["D major", [%w[D5], %w[D5]]]
    end

    it "reads one in a \\new Dynamics for its syntax alone" do
      expect(pitches("<< \\new Staff { c'1 } \\new Dynamics { \\transposition bes s1\\f } >>")).to eq [%w[C4]]
    end

    it "raises without a pitch" do
      expect { described_class.parse("{ \\transposition c'1 }") }
        .to raise_error(described_class::ParseError, /\\transposition expects a pitch/)
    end
  end

  describe "writing \\transposition" do
    def voice_lines(flow, transposed: true)
      described_class.render(written(flow), transposed: transposed)[/\\new Voice.*?^\s*\}/m]
    end

    it "restates it where the instrument changes it" do
      expect(voice_lines(flow_for(:clarinet, :clarinet_in_a))).to include("\\transposition a \\key f \\major")
    end

    it "returns to c' for an instrument in C" do
      expect(voice_lines(flow_for(:clarinet, :flute))).to include("\\transposition c' \\key d \\major")
    end

    it "restates it for a change of octave alone" do
      expect(voice_lines(flow_for(:clarinet, :bass_clarinet))).to include("\\transposition bes,")
    end

    it "does not restate one the new instrument shares" do
      expect(voice_lines(flow_for(:clarinet, :trumpet)).scan("\\transposition").length).to eq 1
    end

    it "writes none at concert pitch" do
      expect(voice_lines(flow_for(:clarinet, :clarinet_in_a), transposed: false)).not_to include("\\transposition")
    end
  end

  describe "a round trip at written pitch" do
    HeadMusic::Instruments::Instrument.all.select(&:transposing?).each do |instrument|
      it "reads the #{instrument.name} back at concert pitch" do
        flow = flow_for(instrument.name_key)
        expect(music(round_trip(flow))).to eq music(flow)
      end
    end

    it "reads a part that changes instrument back at concert pitch" do
      flow = flow_for(:clarinet, :clarinet_in_a, :flute, :bass_clarinet)
      expect(music(round_trip(flow))).to eq music(flow)
    end
  end

  # LilyPond's MIDI plays what \transposition says the notes sound.
  describe "against lilypond's MIDI" do
    def midi_note_numbers(flow)
      skip "lilypond is not installed" unless installed_lilypond

      source = described_class.render(written(flow), transposed: true).sub("\\layout { }", "\\layout { }\n  \\midi { }")
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, "transposed.ly"), source)
        system(installed_lilypond, "-dno-print-pages", "--output", dir, File.join(dir, "transposed.ly"), out: File::NULL, err: File::NULL)
        HeadMusic::MIDI.parse(File.binread(File.join(dir, "transposed.midi"))).voices.flat_map { |voice| voice.pitches.map(&:midi_note_number) }
      end
    end

    it "sounds every transposing instrument at concert pitch" do
      instruments = HeadMusic::Instruments::Instrument.all.select(&:transposing?).map(&:name_key)
      flow = flow_for(*instruments)
      expect(midi_note_numbers(flow)).to eq flow.voices.first.pitches.map(&:midi_note_number)
    end
  end
end
