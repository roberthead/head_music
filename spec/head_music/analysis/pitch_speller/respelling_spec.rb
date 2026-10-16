require "spec_helper"

describe HeadMusic::Analysis::PitchSpeller::Respelling do
  describe "#flow" do
    def respell(flow, **options)
      described_class.new(flow, **options).flow
    end

    def flow_in(key_signature, pitches, meter: "4/4")
      HeadMusic::Content::Flow.new(key_signature: key_signature, meter: meter).tap do |flow|
        voice = flow.add_voice
        pitches.each_with_index { |pitch, index| voice.place("#{index + 1}:1", :whole, pitch) }
      end
    end

    def pitch_names(flow)
      flow.voices.flat_map { |voice| voice.voice_events.flat_map { |event| event.sounds.map(&:to_s) } }
    end

    def timing(flow)
      flow.voices.flat_map do |voice|
        voice.voice_events.map { |event| [event.position.to_s, event.rhythmic_value.to_s, event.sounds.map { |sound| sound.pitched? ? sound.midi_note_number : sound.to_s }] }
      end
    end

    def abc(body, key: "C")
      HeadMusic::Notation::ABC.parse("X:1\nT:Respelled\nM:4/4\nL:1/8\nK:#{key}\n#{body}\n")
    end

    def without_sounds_and_signatures(hash)
      hash.merge(
        "parts" => hash["parts"].map { |part| part.merge("voices" => part["voices"].map { |voice| voice.merge("voice_events" => voice["voice_events"].map { |event| event.except("sounds") }) }) },
        "timeline" => hash["timeline"].except("key_signature", "key_signature_changes")
      )
    end

    let(:sharp_spelled) { flow_in("E♭ major", %w[D♯4 G♯4 A♯4]) }

    it "spells each bar by the key in force, keeping the key signatures" do
      respelled = respell(sharp_spelled)
      expect([pitch_names(respelled), respelled.timeline.to_h]).to eq [%w[E♭4 A♭4 B♭4], sharp_spelled.timeline.to_h]
    end

    it "follows a change of key signature" do
      flow = flow_in("E♭ major", %w[G♯4 G♯4]).tap { |changing| changing.change_key_signature(2, "E major") }
      respelled = respell(flow)
      expect([pitch_names(respelled), respelled.timeline.to_h]).to eq [%w[A♭4 G♯4], flow.timeline.to_h]
    end

    it "spells a key signature with no interpretation by its conventional key" do
      flow = flow_in("C major", %w[G♯4 G♯4]).tap { |changing| changing.change_key_signature(2, -4) }
      expect(pitch_names(respell(flow))).to eq %w[G♯4 A♭4]
    end

    it "spells G♯ minor's 67 as F𝄪" do
      expect(pitch_names(respell(flow_in("G♯ minor", %w[G4])))).to eq %w[F𝄪4]
    end

    it "keeps the key numbers, positions, and rhythmic values" do
      flow = abc("C4 E2 G2 | A4 c2 e ^G |")
      expect(timing(respell(flow, key: :infer))).to eq timing(flow)
    end

    it "changes nothing but the sounds and the key signatures" do
      flow = abc("C4 E2 G2 | A4 c2 e ^G |")
      expect(without_sounds_and_signatures(respell(flow, key: :infer).to_h)).to eq without_sounds_and_signatures(flow.to_h)
    end

    it "leaves the flow given unchanged" do
      before = sharp_spelled.to_h
      respell(sharp_spelled)
      respell(sharp_spelled, key: :infer)
      expect(sharp_spelled.to_h).to eq before
    end

    it "answers a new flow with no project, since a project is not serialized" do
      sharp_spelled.project = HeadMusic::Content::Project.new
      respelled = respell(sharp_spelled)
      expect([respelled.equal?(sharp_spelled), respelled.project]).to eq [false, nil]
    end

    it "spells by a key given, keeping the key signatures" do
      respelled = respell(flow_in("C major", %w[A♯4]), key: "F major")
      expect([pitch_names(respelled), respelled.timeline.to_h["key_signature"]]).to eq [%w[B♭4], "C major"]
    end

    context "with key: :infer" do
      it "replaces the key signature with the inferred key" do
        flow = abc("E4 G2 B2 | E8 |", key: "C").tap { |changing| changing.change_key_signature(2, "B♭ major") }
        respelled = respell(flow, key: :infer)
        expect(respelled.timeline.to_h.values_at("key_signature", "key_signature_changes")).to eq ["E minor", []]
      end

      it "writes a change of key signature for a later region" do
        respelled = respell(abc(("C4 E2 G2 |" * 4) + ("G4 B2 d ^F |" * 4)), key: :infer, change_penalty: 0.5)
        expect(respelled.timeline.to_h["key_signature_changes"]).to eq [{"number" => 5, "signature" => 1, "tonal_context" => "G major"}]
      end

      it "writes no change for a region in the relative key of the one before" do
        flow = abc(("C4 E2 G2 |" * 4) + ("A4 c2 e ^G |" * 4))
        regions = HeadMusic::Analysis::PitchSpeller.new(flow, change_penalty: 0.5).regions.map { |region| region.key.name }
        respelled = respell(flow, key: :infer, change_penalty: 0.5)
        expect([regions, respelled.timeline.to_h.values_at("key_signature", "key_signature_changes")])
          .to eq [["C major", "A minor"], ["C major", []]]
      end

      it "spells sharp-spelled flats in a flat key" do
        respelled = respell(flow_in("C major", %w[D♯4 G4 A♯4 D♯4 G♯4 D♯4]), key: :infer)
        expect([pitch_names(respelled), respelled.timeline.to_h["key_signature"]]).to eq [%w[E♭4 G4 B♭4 E♭4 A♭4 E♭4], "E♭ major"]
      end

      it "leaves the key signatures of a flow with nothing sounding" do
        flow = HeadMusic::Content::Flow.new(key_signature: "D major").tap { |empty| empty.add_voice.place("1:1", :whole) }
        expect(respell(flow, key: :infer).timeline.to_h).to eq flow.timeline.to_h
      end
    end

    it "respells grace notes" do
      flow = flow_in("E♭ major", %w[E♭4]).tap { |graced| graced.voices.first.voice_events.first.add_grace_note("G#4", :sixteenth) }
      grace_note = respell(flow).voices.first.voice_events.first.grace_notes.first
      expect(grace_note.sounds.map(&:to_s)).to eq %w[A♭4]
    end

    it "spells a grace note by the direction to its main note" do
      grace_note = respell(abc("C2 {^C}D2 =C2 E2 G4 |")).voices.first.voice_events[1].grace_notes.first
      expect(grace_note.sounds.map(&:to_s)).to eq %w[C♯4]
    end

    it "leaves unpitched sounds alone" do
      snare = HeadMusic::Rudiment::UnpitchedSound.get("snare drum")
      flow = flow_in("E♭ major", [[snare, "D#4"]])
      expect(respell(flow).to_h.dig("parts", 0, "voices", 0, "voice_events", 0, "sounds")).to eq [{"unpitched" => "snare_drum"}, "E♭4"]
    end

    it "is what PitchSpeller.respell answers" do
      expect(HeadMusic::Analysis::PitchSpeller.respell(sharp_spelled, key: :infer).to_h).to eq respell(sharp_spelled, key: :infer).to_h
    end

    it "refuses an unknown key name when built, before any pitch is read" do
      expect { described_class.new(sharp_spelled, key: "H major") }.to raise_error(ArgumentError, /unknown key "H major"/)
    end

    it "refuses key finder options without key: :infer" do
      expect { respell(sharp_spelled, change_penalty: 0.5) }.to raise_error(ArgumentError, /change_penalty apply only to key: :infer/)
    end
  end

  describe ".signature_changes" do
    def region(bar_number, key)
      HeadMusic::Analysis::KeyRegion.new(bar_number: bar_number, onset: bar_number - 1, key: HeadMusic::Rudiment::Key.get(key))
    end

    it "keeps the first region and each that changes the signature, skipping a relative key" do
      regions = [region(1, "C major"), region(3, "A minor"), region(5, "G major"), region(7, "G major"), region(9, "F major")]
      expect(described_class.signature_changes(regions).map(&:bar_number)).to eq [1, 5, 9]
    end

    it "answers none for no regions" do
      expect(described_class.signature_changes([])).to eq []
    end
  end

  describe "#spelled_notes" do
    it "answers each spelled note with the address of its sound" do
      flow = HeadMusic::Notation::ABC.parse("X:1\nT:Respelled\nM:4/4\nL:1/4\nK:Eb\n^D ^G ^A2 |\n")
      respelling = described_class.new(flow)
      expect(respelling.addresses.zip(respelling.spelled_notes).map { |address, spelled| [address[5], spelled.pitch.to_s, spelled.rule] })
        .to eq [[0, "E♭4", :diatonic], [1, "A♭4", :diatonic], [2, "B♭4", :diatonic]]
    end
  end
end
