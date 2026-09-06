require "spec_helper"

describe HeadMusic::Content::Flow::SchemaValues do
  subject(:values) { described_class.new }

  describe "#position" do
    it "returns nil for a nil value" do
      expect(values.position(nil, "path")).to be_nil
    end

    it "passes a well-formed position string through" do
      expect(values.position("2:3:480", "path")).to eq "2:3:480"
    end

    # Position#code emits a fourth field when a position carries subticks, so
    # what the gem writes must be what it reads.
    it "accepts the four-field form Position#code emits for subticks" do
      expect(values.position("1:1:000:120", "path")).to eq "1:1:000:120"
    end

    it "raises with path context on a malformed position" do
      expect { values.position("bogus", "comments[0]") }
        .to raise_error(ArgumentError, /comments\[0\]: unknown position "bogus"/)
    end

    it "raises on a fifth field" do
      expect { values.position("1:1:000:000:1", "path") }
        .to raise_error(ArgumentError, /path: unknown position "1:1:000:000:1"/)
    end
  end

  describe "#tempo" do
    it "returns nil for a nil value" do
      expect(values.tempo(nil, "path")).to be_nil
    end

    it "builds a tempo from its beat value and beats per minute" do
      tempo = values.tempo({"beat_value" => "half", "beats_per_minute" => 72.5}, "path")
      expect([tempo.beat_value.to_s, tempo.beats_per_minute]).to eq ["half", 72.5]
    end

    it "raises on a non-Hash" do
      expect { values.tempo("quarter = 120", "timeline.tempo") }
        .to raise_error(ArgumentError, /timeline\.tempo: tempo must be a Hash/)
    end

    it "raises on a non-positive beats per minute" do
      expect { values.tempo({"beat_value" => "quarter", "beats_per_minute" => 0}, "timeline.tempo") }
        .to raise_error(ArgumentError, /timeline\.tempo: beats_per_minute must be a positive number, got 0/)
    end

    it "raises with path context on an unknown beat value" do
      expect { values.tempo({"beat_value" => "bogus", "beats_per_minute" => 120}, "timeline.tempo") }
        .to raise_error(ArgumentError, /timeline\.tempo\.beat_value: unknown rhythmic value "bogus"/)
    end
  end

  describe "#staff" do
    it "replays the clef changes onto the staff" do
      staff = values.staff({"clef" => "treble_clef", "clef_changes" => [{"number" => 5, "clef" => "bass_clef"}]}, "path")
      expect([staff.clef_at(4), staff.clef_at(5)]).to eq [HeadMusic::Rudiment::Clef.get(:treble_clef), HeadMusic::Rudiment::Clef.get(:bass_clef)]
    end

    it "raises on a non-Hash" do
      expect { values.staff("treble_clef", "parts[0].staff_system.staves[0]") }
        .to raise_error(ArgumentError, /staves\[0\]: staff must be a Hash/)
    end

    it "raises with path context on a clef change to nothing" do
      expect { values.staff({"clef" => nil, "clef_changes" => [{"number" => 5, "clef" => nil}]}, "staves[0]") }
        .to raise_error(ArgumentError, /staves\[0\]\.clef_changes\[0\]: a clef change names a clef, got nil/)
    end

    it "raises with path context on an unknown changed clef" do
      expect { values.staff({"clef" => nil, "clef_changes" => [{"number" => 5, "clef" => "kazoo_clef"}]}, "staves[0]") }
        .to raise_error(ArgumentError, /staves\[0\]\.clef_changes\[0\]: unknown clef "kazoo_clef"/)
    end
  end

  describe "#key_signature" do
    it "returns nil for a nil value" do
      expect(values.key_signature(nil, "path")).to be_nil
    end

    it "resolves a real key signature" do
      expect(values.key_signature("G major", "path").tonic_spelling.to_s).to eq "G"
    end

    it "raises with path context on a hollow key signature" do
      expect { values.key_signature("Q major", "key_signature") }
        .to raise_error(ArgumentError, /key_signature: unknown key signature "Q major"/)
    end
  end

  describe "#meter" do
    it "returns nil for a nil value" do
      expect(values.meter(nil, "path")).to be_nil
    end

    it "raises with path context on an unparseable meter" do
      expect { values.meter("not a meter", "bars[0]") }
        .to raise_error(ArgumentError, /bars\[0\]: unknown meter "not a meter"/)
    end
  end

  describe "#rhythmic_value" do
    it "resolves a real rhythmic value" do
      expect(values.rhythmic_value("quarter", "path")).to be_a(HeadMusic::Rudiment::RhythmicValue)
    end

    it "raises with path context on an unknown rhythmic value" do
      expect { values.rhythmic_value("sesquialtera", "voices[0].placements[0]") }
        .to raise_error(ArgumentError, /voices\[0\]\.placements\[0\]: unknown rhythmic value "sesquialtera"/)
    end
  end

  describe "#placement_sounds" do
    it "maps a pitched sound array to pitches" do
      sounds = values.placement_sounds({"sounds" => ["C4"]}, "path")
      expect(sounds.map(&:to_s)).to eq ["C4"]
    end

    it "returns an empty array for a rest" do
      expect(values.placement_sounds({"sounds" => []}, "path")).to eq []
    end

    it "raises when sounds is not an Array" do
      expect { values.placement_sounds({"sounds" => nil}, "voices[0].placements[0]") }
        .to raise_error(ArgumentError, /voices\[0\]\.placements\[0\]: sounds must be an Array, got nil/)
    end

    it "raises with element path context on an unknown pitch" do
      expect { values.placement_sounds({"sounds" => ["C4", "H#4"]}, "voices[0].placements[0]") }
        .to raise_error(ArgumentError, /voices\[0\]\.placements\[0\]\.sounds\[1\]: unknown pitch "H#4"/)
    end

    it "resolves a generic unpitched sound" do
      sounds = values.placement_sounds({"sounds" => [{"unpitched" => nil}]}, "path")
      expect(sounds.first).to be_a(HeadMusic::Rudiment::UnpitchedSound)
    end

    it "raises on an unpitched hash with extra keys" do
      expect { values.placement_sounds({"sounds" => [{"unpitched" => nil, "y" => 1}]}, "voices[0].placements[0]") }
        .to raise_error(ArgumentError, /voices\[0\]\.placements\[0\]\.sounds\[0\]: unknown sound .*"y"/)
    end
  end

  describe "#placement_syllables" do
    it "returns an empty array when the key is absent" do
      expect(values.placement_syllables({}, "path")).to eq []
    end

    it "builds syllables from valid data" do
      entries = [{"text" => "glo", "hyphen_after" => true}, {"text" => "peace", "verse" => 2}]
      built = values.placement_syllables({"syllables" => entries}, "path")
      expect(built.map(&:to_h)).to eq entries
    end

    it "raises when syllables is not an Array" do
      expect { values.placement_syllables({"syllables" => "la"}, "voices[0].placements[0]") }
        .to raise_error(ArgumentError, /voices\[0\]\.placements\[0\]: syllables must be an Array, got "la"/)
    end

    it "raises with element path context when an entry is not a Hash" do
      expect { values.placement_syllables({"syllables" => ["la"]}, "voices[0].placements[0]") }
        .to raise_error(ArgumentError, /voices\[0\]\.placements\[0\]\.syllables\[0\]: syllable must be a Hash/)
    end

    it "raises on empty text" do
      expect { values.placement_syllables({"syllables" => [{"text" => ""}]}, "voices[0].placements[0]") }
        .to raise_error(ArgumentError, /syllables\[0\]: syllable text must be a non-empty String/)
    end

    it "raises on a non-positive verse" do
      expect { values.placement_syllables({"syllables" => [{"text" => "la", "verse" => 0}]}, "voices[0].placements[0]") }
        .to raise_error(ArgumentError, /syllables\[0\]: verse must be a positive Integer, got 0/)
    end

    it "raises on a duplicate verse" do
      expect {
        values.placement_syllables({"syllables" => [{"text" => "la"}, {"text" => "dee"}]}, "voices[0].placements[0]")
      }.to raise_error(ArgumentError, /syllables\[1\]: duplicate verse 1/)
    end
  end

  describe "#bar_number" do
    it "returns a valid non-negative bar number" do
      expect(values.bar_number({"number" => 3}, 0)).to eq 3
    end

    it "raises with path context on a negative bar number" do
      expect { values.bar_number({"number" => -1}, 0) }
        .to raise_error(ArgumentError, /bars\[0\]: bar number must be an Integer of at least 0, got -1/)
    end
  end

  describe "#tonal_context" do
    it "reads a name into the context it names" do
      expect(values.tonal_context("C dorian", "x")).to be_a HeadMusic::Rudiment::Mode
    end

    it "accepts no context at all" do
      expect(values.tonal_context(nil, "x")).to be_nil
    end

    it "rejects a name that is not a key" do
      expect { values.tonal_context("Q major", "x") }
        .to raise_error ArgumentError, /x: unknown tonal context "Q major"/
    end

    # KeySignature.get raises rather than returning nil for some shapes, which
    # is why the lookup is guarded rather than merely nil-checked.
    it "rejects a value that is not nameable at all" do
      expect { values.tonal_context({"key" => "C"}, "x") }
        .to raise_error ArgumentError, /x: unknown tonal context/
    end
  end

  describe "#fifths" do
    it "accepts a count of fifths" do
      expect(values.fifths(-3, "x")).to eq(-3)
    end

    it "accepts a theoretical signature past seven" do
      expect(values.fifths(8, "x")).to eq 8
    end

    it "rejects a key signature name, which is an interpretation rather than a signature" do
      expect { values.fifths("3 flats", "x") }
        .to raise_error ArgumentError, /x: signature must be an Integer of fifths/
    end
  end

  describe "#instrument" do
    it "reads a name into an instrument" do
      expect(values.instrument("piano", "x").name).to eq "piano"
    end

    it "accepts no instrument at all" do
      expect(values.instrument(nil, "x")).to be_nil
    end

    it "rejects an unknown instrument" do
      expect { values.instrument("kazoophone", "x") }
        .to raise_error ArgumentError, /x: unknown instrument "kazoophone"/
    end
  end

  describe "#staff_system" do
    subject(:system) { values.staff_system({"bracket" => "brace", "staves" => [{"clef" => "treble_clef"}, {"clef" => "bass_clef"}]}, "x") }

    it "reads the staves" do
      expect(system.staves.map { |staff| staff.clef.to_s }).to eq ["treble clef", "bass clef"]
    end

    it "reads the bracket" do
      expect(system.bracket).to eq :brace
    end

    it "accepts no staff system at all" do
      expect(values.staff_system(nil, "x")).to be_nil
    end

    # A null clef is a staff whose clef was never authored, which the writers
    # infer from a voice's range instead. It is a real state, not a missing one.
    it "accepts a staff with no authored clef" do
      expect(values.staff_system({"staves" => [{"clef" => nil}]}, "x").staves.first.clef).to be_nil
    end

    it "defaults the bracket to none" do
      expect(values.staff_system({"staves" => [{"clef" => nil}]}, "x").bracket).to eq :none
    end

    it "rejects a staff system that is not a Hash" do
      expect { values.staff_system(["treble"], "x") }
        .to raise_error ArgumentError, /x: staff_system must be a Hash/
    end

    it "rejects an unknown bracket" do
      expect { values.staff_system({"bracket" => "squiggle", "staves" => []}, "x") }
        .to raise_error ArgumentError, /x: unknown bracket "squiggle"/
    end

    # Clef.get raises rather than returning nil for an unrecognized key.
    it "rejects an unknown clef, naming the staff it was on" do
      expect { values.staff_system({"staves" => [{"clef" => "bogus clef"}]}, "x") }
        .to raise_error ArgumentError, /x\.staves\[0\]: unknown clef "bogus clef"/
    end
  end
end
