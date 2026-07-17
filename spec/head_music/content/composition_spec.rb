require "spec_helper"

describe HeadMusic::Content::Composition do
  subject(:composition) { described_class.new(name: "Fruit Salad") }

  its(:name) { is_expected.to eq "Fruit Salad" }

  it "defaults to the key of C major" do
    expect(composition.key_signature).to eq "C major"
  end

  it "defaults to 4/4" do
    expect(composition.meter).to eq "4/4"
  end

  its(:latest_bar_number) { is_expected.to eq 1 }
  its(:to_s) { is_expected.to eq "Fruit Salad — 0 voices" }

  its(:composer) { is_expected.to be_nil }
  its(:origin) { is_expected.to be_nil }
  its(:comments) { is_expected.to eq [] }

  context "when constructed with composer and origin" do
    subject(:composition) { described_class.new(name: "The Banshee", composer: "Traditional", origin: "Ireland") }

    its(:composer) { is_expected.to eq "Traditional" }
    its(:origin) { is_expected.to eq "Ireland" }
  end

  context "when constructed with a single comment string" do
    subject(:composition) { described_class.new(name: "The Banshee", comments: "collected in Clare") }

    it "coerces the string to one comment" do
      expect(composition.comments.map(&:to_s)).to eq ["collected in Clare"]
    end

    it "anchors the comment to the composition" do
      expect(composition.comments.first.composition).to eq composition
    end

    it "leaves the comment unpositioned" do
      expect(composition.comments.first.position).to be_nil
    end
  end

  context "when constructed with an array of comment strings" do
    subject(:composition) { described_class.new(name: "The Banshee", comments: ["collected in Clare", "also known as McMahon's"]) }

    it "coerces each string to a comment" do
      expect(composition.comments.map(&:to_s)).to eq ["collected in Clare", "also known as McMahon's"]
    end

    it "builds unpositioned comments" do
      expect(composition.comments.map(&:position)).to all(be_nil)
    end
  end

  describe "#add_comment" do
    context "without a position" do
      it "returns an unpositioned comment" do
        comment = composition.add_comment("play twice")
        expect(comment.position).to be_nil
      end

      it "appends the comment to the collection" do
        comment = composition.add_comment("play twice")
        expect(composition.comments).to include(comment)
      end
    end

    context "with a position" do
      it "anchors the comment at that position" do
        comment = composition.add_comment("the turn", "2:1")
        expect(comment.position.to_s).to eq "2:1:000"
      end
    end
  end

  context "with some placements" do
    let(:voice) { composition.add_voice(role: "melody") }

    before do
      voice.place("0:4", "quarter", "C4")
      voice.place("1:1", :eighth, "C4")
      voice.place("1:1:480", :eighth, "E4")
      voice.place("1:4", :eighth, "A3")
      voice.place("1:4:480", :eighth, "G3")
      voice.place("2:1", :eighth, "A3")
      voice.place("2:1:480", :eighth, "C4")
    end

    its(:latest_bar_number) { is_expected.to eq 2 }
    its(:to_s) { is_expected.to eq "Fruit Salad — 1 voice" }
  end

  context "when the meter changes" do
    before do
      composition.change_meter(9, "6/8")
    end

    it "starts in the original meter" do
      expect(composition.meter_at(1)).to eq "4/4"
    end

    it "remains in the original meter before the change" do
      expect(composition.meter_at(8)).to eq "4/4"
    end

    it "switches to the new meter at the change" do
      expect(composition.meter_at(9)).to eq "6/8"
    end

    it "continues on with the new meter after the change" do
      expect(composition.meter_at(15)).to eq "6/8"
    end
  end

  context "when the key signature changes at bar zero" do
    it "does not raise" do
      expect { composition.change_key_signature(0, "G major") }.not_to raise_error
    end

    it "records the key signature change" do
      composition.change_key_signature(0, "G major")
      expect(composition.key_signature_at(0)).to eq "G major"
    end

    it "applies the key signature to later bars" do
      composition.change_key_signature(0, "G major")
      expect(composition.key_signature_at(5)).to eq "G major"
    end
  end

  context "when the meter changes at bar zero" do
    it "does not raise" do
      expect { composition.change_meter(0, "6/8") }.not_to raise_error
    end

    it "records the meter change" do
      composition.change_meter(0, "6/8")
      expect(composition.meter_at(0)).to eq "6/8"
    end

    it "applies the meter to later bars" do
      composition.change_meter(0, "6/8")
      expect(composition.meter_at(5)).to eq "6/8"
    end
  end

  describe "#to_abc" do
    it "renders an ABC tune string" do
      expect(composition.to_abc).to start_with "X:1\nT:Fruit Salad\n"
    end

    it "passes options through to the renderer" do
      expect(composition.to_abc(reference_number: 12)).to start_with "X:12\n"
    end

    it "propagates render errors" do
      composition.add_voice
      composition.add_voice
      expect { composition.to_abc }.to raise_error(HeadMusic::Notation::ABC::RenderError)
    end
  end

  describe "#to_musicxml" do
    it "renders a MusicXML document string" do
      composition.add_voice
      expect(composition.to_musicxml).to include "<work-title>Fruit Salad</work-title>"
    end

    it "propagates render errors" do
      expect { composition.to_musicxml }.to raise_error(HeadMusic::Notation::MusicXML::RenderError)
    end

    it "rejects options until the renderer defines some" do
      composition.add_voice
      expect { composition.to_musicxml(transpose: 1) }.to raise_error(ArgumentError)
    end
  end

  context "when the key signature changes" do
    before do
      composition.change_key_signature(9, "G major")
    end

    it "starts in the original key signature" do
      expect(composition.key_signature_at(1)).to eq "C major"
    end

    it "remains in the original key signature before the change" do
      expect(composition.key_signature_at(8)).to eq "C major"
    end

    it "switches to the new key signature at the change" do
      expect(composition.key_signature_at(9)).to eq "G major"
    end

    it "continues on with the new key signature after the change" do
      expect(composition.key_signature_at(15)).to eq "G major"
    end
  end

  describe "#to_h" do
    subject(:hash) { composition.to_h }

    let(:composition) do
      described_class.new(name: "Salad Days", key_signature: "D major", meter: "3/4", composer: "Trad.", origin: "Ireland")
    end
    let(:expected_voices) do
      [
        {
          "role" => "melody",
          "placements" => [
            {"position" => "1:1:000", "rhythmic_value" => "quarter", "pitches" => ["D4"]},
            {"position" => "1:2:000", "rhythmic_value" => "quarter", "pitches" => []}
          ]
        }
      ]
    end
    let(:expected_attributes) do
      {
        "name" => "Salad Days",
        "key_signature" => "D major",
        "meter" => "3/4",
        "composer" => "Trad.",
        "origin" => "Ireland"
      }
    end

    before do
      voice = composition.add_voice(role: "melody")
      voice.place("1:1", :quarter, "D4")
      voice.place("1:2", :quarter)
      composition.change_meter(2, "6/8")
      composition.add_comment("with feeling", "1:1")
    end

    it "carries schema version 2" do
      expect(hash["schema_version"]).to eq 2
    end

    it "includes all top-level keys" do
      expect(hash.keys).to contain_exactly(
        "schema_version", "name", "key_signature", "meter", "composer", "origin", "voices", "bars", "comments"
      )
    end

    it "serializes the attributes as parseable strings" do
      expect(hash).to include expected_attributes
    end

    it "serializes the voices with their placements" do
      expect(hash["voices"]).to eq expected_voices
    end

    it "serializes changed bars sparsely with their numbers" do
      expect(hash["bars"]).to eq [{"number" => 2, "meter" => "6/8"}]
    end

    it "serializes the comments" do
      expect(hash["comments"]).to eq [{"text" => "with feeling", "position" => "1:1:000"}]
    end

    it "contains only JSON-safe values" do
      expect(JSON.parse(hash.to_json)).to eq hash
    end

    context "without composer, origin, changes, or comments" do
      subject(:hash) { described_class.new(name: "Plain").to_h }

      let(:expected_defaults) do
        {"composer" => nil, "origin" => nil, "voices" => [], "bars" => [], "comments" => []}
      end

      it "emits nils and empty collections rather than omitting keys" do
        expect(hash).to include expected_defaults
      end
    end
  end

  describe ".from_h" do
    let(:original) do
      composition = described_class.new(name: "Round Trip", key_signature: "G major", meter: "4/4")
      voice = composition.add_voice(role: :melody)
      voice.place("1:1", :quarter, "G4")
      voice.place("1:2", :quarter, "B4")
      voice.place("1:2", :quarter, "D5")
      voice.place("1:3", :eighth)
      voice.place("1:3:480", "eighth tied to quarter", "F♯4")
      composition.change_meter(2, "6/8")
      composition.change_key_signature(2, "D major")
      composition.bars(1).last.starts_repeat = true
      composition.bars(2).last.ends_repeat_after_num_plays = 2
      composition.add_comment("first strain", "1:1")
      composition.add_comment("unpositioned")
      composition
    end

    def single_placement_hash(placement_hash)
      {
        "schema_version" => 2,
        "voices" => [{"role" => nil, "placements" => [placement_hash]}]
      }
    end

    it "rebuilds an equivalent composition" do
      expect(described_class.from_h(original.to_h).to_h).to eq original.to_h
    end

    it "accepts a symbol-keyed hash" do
      hash = {schema_version: 2, name: "Symbolic", voices: [], bars: [], comments: []}
      expect(described_class.from_h(hash).name).to eq "Symbolic"
    end

    it "ignores unknown top-level keys" do
      hash = original.to_h.merge("mood" => "wistful")
      expect(described_class.from_h(hash).to_h).to eq original.to_h
    end

    it "raises on non-Hash input" do
      expect { described_class.from_h("nope") }.to raise_error(ArgumentError, /expected a Hash/)
    end

    it "raises on a missing schema_version" do
      expect { described_class.from_h({}) }.to raise_error(ArgumentError, /unsupported schema_version: nil/)
    end

    it "raises on a string schema_version" do
      expect { described_class.from_h("schema_version" => "1") }
        .to raise_error(ArgumentError, /unsupported schema_version: "1"/)
    end

    it "raises on an unsupported schema_version" do
      expect { described_class.from_h("schema_version" => 3) }
        .to raise_error(ArgumentError, /unsupported schema_version: 3/)
    end

    it "raises with path context on an unknown pitch" do
      hash = single_placement_hash("position" => "1:1:000", "rhythmic_value" => "quarter", "pitches" => ["H#4"])
      expect { described_class.from_h(hash) }
        .to raise_error(ArgumentError, 'voices[0].placements[0].pitches[0]: unknown pitch "H#4"')
    end

    it "raises with path context on an unknown rhythmic value" do
      hash = single_placement_hash("position" => "1:1:000", "rhythmic_value" => "flurble", "pitches" => ["C4"])
      expect { described_class.from_h(hash) }
        .to raise_error(ArgumentError, /voices\[0\]\.placements\[0\]: unknown rhythmic value "flurble"/)
    end

    it "raises with path context on a negative bar number" do
      hash = {"schema_version" => 2, "bars" => [{"number" => -1, "meter" => "6/8"}]}
      expect { described_class.from_h(hash) }
        .to raise_error(ArgumentError, /bars\[0\]: bar number must be an Integer of at least 0/)
    end

    it "raises with path context on a non-integer bar number" do
      hash = {"schema_version" => 2, "bars" => [{"number" => "2", "meter" => "6/8"}]}
      expect { described_class.from_h(hash) }.to raise_error(ArgumentError, /bars\[0\]: bar number/)
    end

    it "raises with path context on an unparseable meter" do
      hash = {"schema_version" => 2, "bars" => [{"number" => 2, "meter" => "garbage"}]}
      expect { described_class.from_h(hash) }
        .to raise_error(ArgumentError, /bars\[0\]: unknown meter "garbage"/)
    end

    it "raises with path context on an unparseable key signature" do
      hash = {"schema_version" => 2, "bars" => [{"number" => 2, "key_signature" => "garbage nonsense"}]}
      expect { described_class.from_h(hash) }
        .to raise_error(ArgumentError, /bars\[0\]: unknown key signature "garbage nonsense"/)
    end
  end

  describe "#to_json and .from_json" do
    it "round-trips through a JSON string" do
      composition.add_voice(role: "melody").place("1:1", :quarter, "C4")
      restored = described_class.from_json(composition.to_json)
      expect(restored.to_h).to eq composition.to_h
    end
  end
end
