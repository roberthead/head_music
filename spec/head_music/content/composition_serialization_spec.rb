require "spec_helper"

# Round-trip suite for the schema v2 serialization: Composition#to_h /
# Composition.from_h (plus the to_json/from_json delegates). Each scenario
# asserts persistence fidelity — from_h(to_h) reproduces the same hash — and,
# where the notation renderers support the material, identical to_abc and
# to_musicxml output. Renderer limitations (multi-voice ABC, mid-piece key or
# meter changes in ABC, same-voice chords in MusicXML) never limit the hash
# round trip itself.
describe HeadMusic::Content::Composition do
  def expect_lossless_round_trip(composition, abc: true, musicxml: true)
    hash = composition.to_h
    restored = described_class.from_h(hash)
    expect(restored.to_h).to eq(hash)
    expect(restored.to_abc).to eq(composition.to_abc) if abc
    expect(restored.to_musicxml).to eq(composition.to_musicxml) if musicxml
    restored
  end

  def expect_json_safe(value, path = "hash")
    case value
    when Hash
      value.each do |key, nested|
        expect(key).to be_a(String), "expected a String key at #{path}, got #{key.inspect}"
        expect_json_safe(nested, "#{path}.#{key}")
      end
    when Array
      value.each_with_index { |nested, index| expect_json_safe(nested, "#{path}[#{index}]") }
    when String, Integer, Float, TrueClass, FalseClass, NilClass
      value
    else
      raise "expected a JSON primitive at #{path}, got #{value.class}: #{value.inspect}"
    end
  end

  # Exercises every branch of the schema: two voices (one with a chord), a
  # rest, a tick-offset placement, a tied duration, mid-piece key and meter
  # changes, repeat and volta flags, and comments with and without positions.
  let(:rich_composition) do
    described_class.new(
      name: "Rich Fixture",
      key_signature: "D major",
      meter: "4/4",
      composer: "Trad.",
      origin: "Testville",
      comments: "constructed for serialization specs"
    ).tap do |composition|
      melody = composition.add_voice(role: "melody")
      melody.place("1:1:000", :eighth, "D4")
      melody.place("1:1:480", :eighth, "F#4")
      melody.place("1:2:000", :quarter)
      melody.place("1:3:000", :half, "A4")
      melody.place("2:1:000", "half tied to eighth", "B4")
      harmony = composition.add_voice(role: "harmony")
      harmony.place("1:1:000", :whole, "D3")
      harmony.place("2:1:000", :whole, "D3")
      harmony.place("2:1:000", :whole, "F#3")
      composition.change_key_signature(3, "A major")
      composition.change_meter(3, "6/8")
      composition.bars(1).last.starts_repeat = true
      composition.bars(3).last.plays_on_passes = [1, 2]
      composition.bars(4).last.ends_repeat_after_num_plays = 2
      composition.add_comment("with position", "1:1:000")
      composition.add_comment("without position")
    end
  end

  describe "JSON-safety of the hash" do
    it "contains only String keys and JSON-primitive values" do
      expect_json_safe(rich_composition.to_h)
    end

    it "round-trips through JSON serialization unchanged" do
      hash = rich_composition.to_h
      restored = described_class.from_h(JSON.parse(hash.to_json))
      expect(restored.to_h).to eq hash
    end

    it "round-trips through the to_json/from_json delegates" do
      restored = described_class.from_json(rich_composition.to_json)
      expect(restored.to_h).to eq rich_composition.to_h
    end
  end

  describe "single-voice diatonic tune" do
    let(:composition) do
      HeadMusic::Notation::ABC.parse(<<~ABC)
        X:1
        T:Simple Scale
        M:4/4
        L:1/4
        K:C
        CDEF|GABc|
      ABC
    end

    it "round-trips losslessly" do
      expect_lossless_round_trip(composition)
    end
  end

  describe "accidentals and exact spellings" do
    context "with the chromatic ABC fixture" do
      let(:composition) { HeadMusic::Notation::ABC.parse(ABCFixtures::CHROMATIC_AIR) }
      let(:hash) { composition.to_h }
      let(:pitches) { hash["voices"].first["placements"].flat_map { |placement| placement["pitches"] } }

      it "serializes the minor key, composer, and origin" do
        expect(hash).to include(
          "key_signature" => "A minor", "composer" => "Trad.", "origin" => "Nowhere in Particular"
        )
      end

      it "serializes accidentals as unicode pitch strings" do
        expect(pitches).to include("G♯4", "B♭4", "F♯4", "D♯5")
      end

      it "round-trips losslessly" do
        expect_lossless_round_trip(composition)
      end
    end

    context "with enharmonically equivalent spellings" do
      let(:composition) do
        described_class.new(name: "Enharmonics").tap do |enharmonic|
          voice = enharmonic.add_voice(role: "melody")
          voice.place("1:1:000", :half, "B♭4")
          voice.place("1:3:000", :half, "A♯4")
        end
      end

      let(:pitches) { composition.to_h["voices"].first["placements"].flat_map { |placement| placement["pitches"] } }

      it "does not normalize enharmonic spellings" do
        expect(pitches).to eq %w[B♭4 A♯4]
      end

      it "round-trips losslessly" do
        expect_lossless_round_trip(composition)
      end
    end

    context "with a double-sharp pitch" do
      let(:double_sharp) { HeadMusic::Rudiment::Pitch.get("Fx5") }
      let(:composition) do
        described_class.new(name: "Double Sharp", key_signature: "F♯ minor").tap do |raised|
          raised.add_voice(role: "melody").place("1:1:000", :whole, double_sharp)
        end
      end

      it "spells the double sharp with the unicode symbol" do
        expect(double_sharp.to_s).to eq "F𝄪5"
      end

      it "serializes the double sharp and the sharp key verbatim" do
        hash = composition.to_h
        expect(hash["key_signature"]).to eq "F♯ minor"
        expect(hash["voices"].first["placements"].first["pitches"]).to eq ["F𝄪5"]
      end

      it "round-trips the exact spelling" do
        restored = expect_lossless_round_trip(composition)
        expect(restored.voices.first.pitches.first.to_s).to eq "F𝄪5"
      end
    end
  end

  describe "rests" do
    let(:composition) do
      described_class.new(name: "Restful").tap do |restful|
        voice = restful.add_voice(role: "melody")
        voice.place("1:1:000", :quarter, "C4")
        voice.place("1:2:000", :quarter)
        voice.place("1:3:000", :half, "E4")
      end
    end

    it "serializes a placement without a pitch as an empty-pitches rest" do
      expect(composition.to_h["voices"].first["placements"][1]).to eq(
        "position" => "1:2:000", "rhythmic_value" => "quarter", "pitches" => []
      )
    end

    it "round-trips the rest" do
      restored = expect_lossless_round_trip(composition)
      expect(restored.voices.first.rests.length).to eq 1
    end
  end

  describe "a chord built by placing pitches one at a time" do
    let(:composition) do
      described_class.new(name: "Chordal").tap do |chordal|
        voice = chordal.add_voice(role: "harmony")
        voice.place("1:1:000", :whole, "C4")
        voice.place("1:1:000", :whole, "E4")
        voice.place("1:1:000", :whole, "G4")
      end
    end

    it "merges into a single chord placement" do
      placements = composition.voices.first.placements
      expect(placements.length).to eq 1
      expect(placements.first.pitches.map(&:to_s)).to eq %w[C4 E4 G4]
    end

    # The notation writers do not render chord placements, so the comparison
    # is hash-only. The hash remains the source of truth regardless.
    it "preserves chord-note order through the round trip" do
      restored = expect_lossless_round_trip(composition, abc: false, musicxml: false)
      expect(restored.voices.first.placements.first.pitches.map(&:to_s)).to eq %w[C4 E4 G4]
    end

    it "reproduces the MusicXML renderer error on the restored composition" do
      restored = described_class.from_h(composition.to_h)
      expect { composition.to_musicxml }.to raise_error(HeadMusic::Notation::MusicXML::RenderError)
      expect { restored.to_musicxml }.to raise_error(HeadMusic::Notation::MusicXML::RenderError)
    end
  end

  describe "a chord placement (multiple pitches in one placement)" do
    let(:composition) do
      described_class.new(name: "Chord Placement").tap do |chordal|
        voice = chordal.add_voice(role: "harmony")
        voice.place("1:1:000", :half, %w[C4 E4 G4])
        voice.place("1:3:000", :half, "C5")
      end
    end

    it "serializes the chord as an ordered pitches array in one placement" do
      expect(composition.to_h["voices"].first["placements"].first["pitches"]).to eq %w[C4 E4 G4]
    end

    # The notation writers do not render chord placements, so the comparison
    # is hash-only.
    it "round-trips losslessly to a single chord placement" do
      restored = expect_lossless_round_trip(composition, abc: false, musicxml: false)
      voice = restored.voices.first
      expect(voice.placements.length).to eq 2
      expect(voice.placements.first.pitches.map(&:to_s)).to eq %w[C4 E4 G4]
    end
  end

  describe "multiple voices with roles" do
    let(:composition) do
      described_class.new(name: "Voices").tap do |voiced|
        [:cantus_firmus, "counterpoint", "counterpoint", nil].each do |role|
          voiced.add_voice(role: role).place("1:1:000", :whole, "C4")
        end
      end
    end

    it "serializes roles as an ordered array of strings, duplicates included" do
      roles = composition.to_h["voices"].map { |voice| voice["role"] }
      expect(roles).to eq ["cantus_firmus", "counterpoint", "counterpoint", nil]
    end

    # ABC output is single-voice only, so the render comparison is MusicXML.
    it "round-trips voices in order with their roles" do
      restored = expect_lossless_round_trip(composition, abc: false)
      expect(restored.voices.map { |voice| voice.role&.to_s }).to eq composition.voices.map { |voice| voice.role&.to_s }
      expect(restored.cantus_firmus_voice).to eq restored.voices.first
    end
  end

  describe "tick-precise positions" do
    let(:composition) do
      described_class.new(name: "Ticks").tap do |ticked|
        voice = ticked.add_voice(role: "melody")
        voice.place("1:1:000", :eighth, "C4")
        voice.place("1:1:480", :eighth, "E4")
        voice.place("1:2:000", :half, "G4")
        voice.place("1:4:000", :quarter, "C5")
      end
    end

    it "serializes tick offsets at full precision" do
      positions = composition.to_h["voices"].first["placements"].map { |placement| placement["position"] }
      expect(positions).to eq %w[1:1:000 1:1:480 1:2:000 1:4:000]
    end

    it "round-trips losslessly" do
      expect_lossless_round_trip(composition)
    end
  end

  describe "mid-piece key signature change" do
    let(:composition) do
      described_class.new(name: "Modulation", key_signature: "G major").tap do |modulating|
        voice = modulating.add_voice(role: "melody")
        1.upto(6) { |bar| voice.place("#{bar}:1:000", :whole, "D4") }
        modulating.change_key_signature(5, "D major")
      end
    end

    it "serializes a string-argument key change into the sparse bars array" do
      expect(composition.to_h["bars"]).to eq [{"number" => 5, "key_signature" => "D major"}]
    end

    # ABC cannot render mid-piece key changes, so the render comparison is MusicXML.
    it "round-trips the key change" do
      restored = expect_lossless_round_trip(composition, abc: false)
      expect(restored.key_signature_at(6).name).to eq "D major"
    end
  end

  describe "mid-piece meter change" do
    let(:composition) do
      described_class.new(name: "Meter Shift", meter: "4/4").tap do |shifting|
        voice = shifting.add_voice(role: "melody")
        voice.place("1:1:000", :whole, "C4")
        voice.place("2:1:000", :whole, "C4")
        shifting.change_meter(3, "6/8")
        voice.place("3:1:000", "dotted half", "D4")
        voice.place("4:1:000", "dotted quarter", "E4")
        voice.place("4:4:000", :eighth, "F4")
        voice.place("4:5:000", :eighth, "G4")
        voice.place("4:6:000", :eighth, "A4")
      end
    end

    let(:positions) { composition.to_h["voices"].first["placements"].map { |placement| placement["position"] } }

    it "serializes the meter change into the sparse bars array" do
      expect(composition.to_h["bars"]).to eq [{"number" => 3, "meter" => "6/8"}]
    end

    # Counts 5 and 6 only parse in a bar governed by 6/8; under the base 4/4
    # they would roll over into the next bar. Their surviving verbatim pins
    # from_h's ordering: bar changes replay before any position parses.
    it "keeps counts that only exist under the changed meter" do
      expect(positions).to include("4:5:000", "4:6:000")
    end

    it "round-trips the 6/8 positions to the same strings" do
      restored = expect_lossless_round_trip(composition, abc: false)
      restored_positions = restored.to_h["voices"].first["placements"].map { |placement| placement["position"] }
      expect(restored_positions).to eq positions
    end
  end

  describe "comments" do
    context "with positioned and unpositioned comments" do
      let(:composition) do
        described_class.new(name: "Annotated").tap do |annotated|
          annotated.add_voice(role: "melody").place("1:1:000", :whole, "C4")
          annotated.add_comment("anchored", "1:1:000")
          annotated.add_comment("floating")
        end
      end

      it "serializes both, with null for the missing position" do
        expect(composition.to_h["comments"]).to eq [
          {"text" => "anchored", "position" => "1:1:000"},
          {"text" => "floating", "position" => nil}
        ]
      end

      it "round-trips losslessly" do
        expect_lossless_round_trip(composition)
      end
    end

    context "with the constructor's comments: argument" do
      let(:from_string) { described_class.new(name: "Notes", comments: "collected in Clare") }
      let(:from_array) { described_class.new(name: "Notes", comments: ["collected in Clare"]) }
      let(:via_builder) { described_class.new(name: "Notes").tap { |notes| notes.add_comment("collected in Clare") } }

      it "converges the string form, array form, and add_comment to the same shape" do
        expect(from_string.to_h["comments"]).to eq [{"text" => "collected in Clare", "position" => nil}]
        expect(from_string.to_h).to eq(from_array.to_h)
        expect(from_array.to_h).to eq(via_builder.to_h)
      end
    end
  end

  describe "ABC fixture with repeats" do
    let(:composition) { HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH) }

    it "serializes the repeat structure into the sparse bars array" do
      expect(composition.to_h["bars"]).to eq [
        {"number" => 1, "starts_repeat" => true},
        {"number" => 8, "ends_repeat_after_num_plays" => 2}
      ]
    end

    it "round-trips losslessly including ABC and MusicXML renders" do
      restored = expect_lossless_round_trip(composition)
      expect(restored.bars(1).first.starts_repeat?).to be true
    end
  end

  describe "tied durations" do
    context "with an ABC note spanning five eighths" do
      let(:composition) do
        HeadMusic::Notation::ABC.parse(<<~ABC)
          X:1
          T:Tied
          M:4/4
          L:1/8
          K:C
          C5 z3|
        ABC
      end

      let(:rhythmic_values) do
        composition.to_h["voices"].first["placements"].map { |placement| placement["rhythmic_value"] }
      end

      it "serializes the cross-unit duration as a tied rhythmic value" do
        expect(rhythmic_values).to include("half tied to eighth")
      end

      it "round-trips losslessly" do
        expect_lossless_round_trip(composition)
      end
    end

    context "with a manually placed tied rhythmic value" do
      let(:tied) { HeadMusic::Rudiment::RhythmicValue.get("half tied to eighth") }
      let(:composition) do
        described_class.new(name: "Manual Tie").tap do |manual|
          manual.add_voice(role: "melody").place("1:1:000", tied, "G4")
        end
      end

      it "serializes the tie chain as a parseable string" do
        expect(composition.to_h["voices"].first["placements"].first["rhythmic_value"]).to eq "half tied to eighth"
      end

      it "round-trips the total duration" do
        restored = expect_lossless_round_trip(composition)
        expect(restored.voices.first.placements.first.rhythmic_value.total_value).to eq tied.total_value
      end
    end
  end

  describe "schema_version" do
    it "is present and equal to 2 in every serialized hash" do
      expect(rich_composition.to_h["schema_version"]).to eq 2
      expect(described_class.new.to_h["schema_version"]).to eq 2
    end

    it "accepts version 2" do
      expect(described_class.from_h({"schema_version" => 2, "name" => "Current"}).name).to eq "Current"
    end

    it "raises ArgumentError on the retired version 1" do
      expect { described_class.from_h({"schema_version" => 1, "name" => "Legacy"}) }
        .to raise_error(ArgumentError, /unsupported schema_version: 1 \(supported: 2\)/)
    end

    it "raises ArgumentError when schema_version is missing" do
      expect { described_class.from_h({"name" => "No Version"}) }
        .to raise_error(ArgumentError, /unsupported schema_version: nil/)
    end

    it "raises ArgumentError on an unsupported future version" do
      expect { described_class.from_h({"schema_version" => 3}) }
        .to raise_error(ArgumentError, /unsupported schema_version: 3/)
    end

    it "raises ArgumentError on a String version, even \"1\"" do
      expect { described_class.from_h({"schema_version" => "1"}) }
        .to raise_error(ArgumentError, /unsupported schema_version: "1"/)
    end
  end

  describe "malformed input" do
    let(:base_hash) { {"schema_version" => 2, "name" => "Corrupted"} }

    def hash_with_placement(placement_hash)
      base_hash.merge("voices" => [{"role" => nil, "placements" => [placement_hash]}])
    end

    it "raises ArgumentError on a non-Hash" do
      expect { described_class.from_h("not a hash") }
        .to raise_error(ArgumentError, /expected a Hash, got String/)
    end

    it "raises ArgumentError when a placement uses the retired v1 pitch key" do
      hash = hash_with_placement("position" => "1:1:000", "rhythmic_value" => "quarter", "pitch" => "C4")
      expect { described_class.from_h(hash) }
        .to raise_error(ArgumentError, /voices\[0\]\.placements\[0\]: pitches must be an Array, got nil/)
    end

    it "raises ArgumentError when pitches is not an Array" do
      hash = hash_with_placement("position" => "1:1:000", "rhythmic_value" => "quarter", "pitches" => "C4")
      expect { described_class.from_h(hash) }
        .to raise_error(ArgumentError, /voices\[0\]\.placements\[0\]: pitches must be an Array, got "C4"/)
    end

    it "raises ArgumentError with element path context on an unknown pitch in a chord" do
      hash = hash_with_placement("position" => "1:1:000", "rhythmic_value" => "quarter", "pitches" => ["C4", "H#4"])
      expect { described_class.from_h(hash) }
        .to raise_error(ArgumentError, /voices\[0\]\.placements\[0\]\.pitches\[1\]: unknown pitch "H#4"/)
    end

    it "raises ArgumentError on a nil element in pitches" do
      hash = hash_with_placement("position" => "1:1:000", "rhythmic_value" => "quarter", "pitches" => [nil])
      expect { described_class.from_h(hash) }
        .to raise_error(ArgumentError, /voices\[0\]\.placements\[0\]\.pitches\[0\]: unknown pitch nil/)
    end

    it "raises ArgumentError with path context on an unknown rhythmic value" do
      hash = hash_with_placement("position" => "1:1:000", "rhythmic_value" => "sesquialtera", "pitches" => ["C4"])
      expect { described_class.from_h(hash) }
        .to raise_error(ArgumentError, /voices\[0\]\.placements\[0\]: unknown rhythmic value "sesquialtera"/)
    end

    it "raises ArgumentError on a negative bar number" do
      hash = base_hash.merge("bars" => [{"number" => -1, "meter" => "3/4"}])
      expect { described_class.from_h(hash) }
        .to raise_error(ArgumentError, /bars\[0\]: bar number/)
    end

    it "raises ArgumentError with path context on an unparseable meter" do
      hash = base_hash.merge("bars" => [{"number" => 3, "meter" => "not a meter"}])
      expect { described_class.from_h(hash) }
        .to raise_error(ArgumentError, /bars\[0\]: unknown meter "not a meter"/)
    end

    it "raises ArgumentError on an unknown top-level key signature" do
      hash = base_hash.merge("key_signature" => "Q major")
      expect { described_class.from_h(hash) }
        .to raise_error(ArgumentError, /key_signature: unknown key signature "Q major"/)
    end

    it "raises ArgumentError with path context on an unknown bar key signature" do
      hash = base_hash.merge("bars" => [{"number" => 3, "key_signature" => "Q major"}])
      expect { described_class.from_h(hash) }
        .to raise_error(ArgumentError, /bars\[0\]: unknown key signature "Q major"/)
    end

    it "raises ArgumentError with path context on an unparseable placement position" do
      hash = hash_with_placement("position" => "not-a-position", "rhythmic_value" => "quarter", "pitches" => ["C4"])
      expect { described_class.from_h(hash) }
        .to raise_error(ArgumentError, /voices\[0\]\.placements\[0\]: unknown position "not-a-position"/)
    end

    it "raises ArgumentError with path context on a negative placement position" do
      hash = hash_with_placement("position" => "-1:1:000", "rhythmic_value" => "quarter", "pitches" => ["C4"])
      expect { described_class.from_h(hash) }
        .to raise_error(ArgumentError, /voices\[0\]\.placements\[0\]: unknown position "-1:1:000"/)
    end

    it "raises ArgumentError with path context on an unparseable comment position" do
      hash = base_hash.merge("comments" => [{"text" => "hello", "position" => "somewhere"}])
      expect { described_class.from_h(hash) }
        .to raise_error(ArgumentError, /comments\[0\]: unknown position "somewhere"/)
    end
  end

  describe "edge cases" do
    context "with an empty composition" do
      let(:composition) { described_class.new(name: "Empty") }

      it "emits empty collections rather than omitting keys" do
        expect(composition.to_h).to include("voices" => [], "bars" => [], "comments" => [])
      end

      # MusicXML refuses to render a composition with no voices on both sides
      # of the round trip; ABC renders headers only, so it compares.
      it "round-trips, reproducing the no-voices MusicXML error" do
        restored = expect_lossless_round_trip(composition, musicxml: false)
        expect { composition.to_musicxml }.to raise_error(HeadMusic::Notation::MusicXML::RenderError)
        expect { restored.to_musicxml }.to raise_error(HeadMusic::Notation::MusicXML::RenderError)
      end
    end

    context "with a voice that has a role but no placements" do
      let(:composition) do
        described_class.new(name: "Silent Voice").tap { |silent| silent.add_voice(role: "melody") }
      end

      it "serializes the voice with an empty placements array" do
        expect(composition.to_h["voices"]).to eq [{"role" => "melody", "placements" => []}]
      end

      it "round-trips the role" do
        restored = expect_lossless_round_trip(composition)
        expect(restored.voices.first.role).to eq "melody"
      end
    end

    context "with volta bars" do
      let(:composition) do
        described_class.new(name: "Volta").tap do |volta|
          voice = volta.add_voice(role: "melody")
          1.upto(4) { |bar| voice.place("#{bar}:1:000", :whole, "C4") }
          volta.bars(1).last.starts_repeat = true
          volta.bars(3).last.plays_on_passes = [1, 2]
          volta.bars(4).last.ends_repeat_after_num_plays = 2
        end
      end

      it "serializes plays_on_passes on the volta bar" do
        expect(composition.to_h["bars"]).to include({"number" => 3, "plays_on_passes" => [1, 2]})
      end

      it "round-trips the volta structure" do
        restored = expect_lossless_round_trip(composition)
        expect(restored.bars(3).last.plays_on_passes).to eq [1, 2]
      end
    end

    it "ignores unknown top-level keys" do
      hash = rich_composition.to_h
      decorated = hash.merge("mood" => "wistful", "tempo_suggestion" => 96)
      expect(described_class.from_h(decorated).to_h).to eq hash
    end

    it "treats a nil name and the default name as equivalent" do
      unnamed = described_class.from_h({"schema_version" => 2, "name" => nil})
      named = described_class.from_h({"schema_version" => 2, "name" => "Composition"})
      expect(unnamed.to_h).to eq named.to_h
      expect(unnamed.to_h["name"]).to eq "Composition"
    end
  end
end
