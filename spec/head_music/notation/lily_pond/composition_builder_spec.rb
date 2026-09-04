require "spec_helper"

describe HeadMusic::Notation::LilyPond::CompositionBuilder do
  def build(source)
    tokens = HeadMusic::Notation::LilyPond::Lexer.new(source).tokens
    document = HeadMusic::Notation::LilyPond::DocumentReader.new(tokens).document
    described_class.new(document).composition
  end

  def placements(source)
    build(source).voices.flat_map { |voice| voice.placements.map(&:to_s) }
  end

  describe "identity" do
    it "seeds the name, composer, key, and meter" do
      composition = build(%(\\header { title = "Air" composer = "A." } { \\key g \\major \\time 3/4 c'2. }))
      expect([composition.name, composition.composer, composition.key_signature.to_s, composition.meter.to_s])
        .to eq ["Air", "A.", "1 sharp", "3/4"]
    end

    it "defaults to C major and 4/4, as LilyPond does" do
      composition = build("{ c'1 }")
      expect([composition.key_signature.to_s, composition.meter.to_s]).to eq ["no sharps or flats", "4/4"]
    end

    it "defaults the name" do
      expect(build("{ c'1 }").name).to eq "Composition"
    end

    it "raises when there is no music" do
      expect { build("{ }") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /contains no music/)
    end
  end

  describe "placements" do
    it "places notes and rests consecutively" do
      expect(placements("{ c'4 r4 e'2 }")).to eq ["quarter C4 at 1:1:000", "quarter rest at 1:2:000", "half E4 at 1:3:000"]
    end

    it "keeps rests distinct from notes" do
      voice = build("{ c'4 r4 }").voices.first
      expect([voice.notes.length, voice.rests.length]).to eq [1, 1]
    end

    it "places a chord as one placement" do
      placement = build("{ <c' e' g'>1 }").voices.first.placements.first
      expect([placement.chord?, placement.pitches.map(&:to_s)]).to eq [true, %w[C4 E4 G4]]
    end

    it "carries a tied value into one placement" do
      expect(placements("{ c'2~ c'8 d'8 e'4 }").first).to eq "half tied to eighth C4 at 1:1:000"
    end

    it "rolls into the next bar" do
      expect(placements("{ c'1 d'1 }").last).to eq "whole D4 at 2:1:000"
    end

    it "gives each stream its own voice with its role" do
      composition = build(%(<< \\new Staff \\with { instrumentName = "A" } { c'1 } \\new Staff { d'1 } >>))
      expect(composition.voices.map { |voice| [voice.role, voice.pitches.map(&:to_s)] }).to eq [["A", %w[C4]], [nil, %w[D4]]]
    end

    it "builds an empty voice for an empty staff" do
      expect(build("\\new Staff { }").voices.first.placements).to be_empty
    end
  end

  describe "bar checks" do
    it "passes at the start of a bar" do
      expect(placements("{ c'2 d'2 | e'1 | }").last).to eq "whole E4 at 2:1:000"
    end

    it "passes at the very start" do
      expect(placements("{ | c'1 }")).to eq ["whole C4 at 1:1:000"]
    end

    it "passes across a meter change" do
      expect(placements("{ c'1 | \\time 3/4 d'2. | e'4 }").last).to eq "quarter E4 at 3:1:000"
    end

    it "raises for an underfilled bar with the elapsed fraction" do
      expect { build("{ c'2 d'4 | e'1 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Bar check failed at: 3\/4 in bar 1 \(line 1\)/)
    end

    it "raises for an overfilled bar in the bar it spilled into" do
      expect { build("{ c'1 d'4 | e'1 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Bar check failed at: 1\/4 in bar 2/)
    end

    it "reports a partial count in ticks" do
      expect { build("{ c'8 | }") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /failed at: 1\/8 in bar 1/)
    end
  end

  describe "whole-bar rests" do
    it "places a whole rest in 4/4" do
      expect(placements("{ R1*4/4 c'1 }").first).to eq "whole rest at 1:1:000"
    end

    it "places a dotted half rest in 3/4" do
      expect(placements("{ \\time 3/4 R1*3/4 }").first).to eq "dotted half rest at 1:1:000"
    end

    it "places a tied rest in 5/4" do
      expect(placements("{ \\time 5/4 R1*5/4 }").first).to eq "whole tied to quarter rest at 1:1:000"
    end

    it "accepts a bare R1 in 4/4" do
      expect(placements("{ R1 }").first).to eq "whole rest at 1:1:000"
    end

    it "raises for a multi-bar rest" do
      expect { build("{ R1*2 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Multi-bar rests are not yet supported \(2 whole notes in 4\/4\)/)
    end

    it "raises for a rest that does not fill the bar" do
      expect { build("{ R1*3/4 }") }.to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /Multi-bar rests/)
    end

    it "raises for a whole-bar rest starting mid-bar" do
      expect { build("{ c'4 R1*4/4 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /must start a bar/)
    end
  end

  describe "key and meter changes" do
    it "applies a mid-piece key change to the bar" do
      composition = build("{ c'1 | \\key d \\major d'1 | }")
      expect([composition.key_signature_at(1).to_s, composition.key_signature_at(2).to_s]).to eq ["no sharps or flats", "2 sharps"]
    end

    it "applies a mid-piece meter change to the bar" do
      composition = build("{ c'1 | \\time 3/4 d'2. | }")
      expect([composition.meter_at(1).to_s, composition.meter_at(2).to_s]).to eq ["4/4", "3/4"]
    end

    it "treats the same change in a second voice as a no-op" do
      source = "<< \\new Staff { c'1 | \\key d \\major \\time 3/4 d'2. | } \\new Staff { c1 | \\key d \\major \\time 3/4 d2. | } >>"
      composition = build(source)
      expect([composition.key_signature_at(2).to_s, composition.meter_at(2).to_s]).to eq ["2 sharps", "3/4"]
    end

    it "treats a restated key as a no-op that leaves the key in force" do
      composition = build("{ \\key d \\major c'1 | \\key d \\major d'1 | }")
      expect(composition.key_signature_at(2).to_s).to eq "2 sharps"
    end

    it "raises for a conflicting key at bar one" do
      expect { build("<< \\new Staff { \\key g \\major c'1 } \\new Staff { \\key d \\major c1 } >>") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Conflicting \\key at bar 1/)
    end

    it "raises for a conflicting meter at bar one" do
      expect { build("<< \\new Staff { \\time 4/4 c'1 } \\new Staff { \\time 3/4 c2. } >>") }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Conflicting \\time at bar 1/)
    end

    it "raises for conflicting changes at a later bar" do
      source = "<< \\new Staff { c'1 | \\key d \\major d'1 } \\new Staff { c1 | \\key g \\major d1 } >>"
      expect { build(source) }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Conflicting \\key at bar 2/)
    end

    it "raises for conflicting meters at a later bar" do
      source = "<< \\new Staff { c'1 | \\time 3/4 d'2. } \\new Staff { c1 | \\time 2/4 d2 } >>"
      expect { build(source) }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, /Conflicting \\time at bar 2/)
    end

    it "applies a change from one staff to the voices that do not restate it" do
      source = "<< \\new Staff { c'1 c'1 c'1 } \\new Staff { \\time 4/4 c1 | \\time 3/4 c4 c c | c4 c c } >>"
      expect(build(source).voices.first.placements.map(&:position).map(&:to_s)).to eq %w[1:1:000 2:1:000 3:2:000]
    end

    it "reads the same score the same way whichever staff carries the change" do
      plain = "\\new Staff { c'1 c'1 c'1 }"
      changing = "\\new Staff { \\time 4/4 c1 | \\time 3/4 c4 c c | c4 c c }"
      positions = ->(source) { build(source).voices.map { |voice| voice.placements.map { |p| p.position.to_s } } }
      expect(positions.call("<< #{plain} #{changing} >>")).to eq positions.call("<< #{changing} #{plain} >>").reverse
    end

    it "raises for a key change mid-bar" do
      expect { build("{ c'2 \\key d \\major d'2 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /\\key in the middle of a bar/)
    end

    it "raises for a meter change mid-bar" do
      expect { build("{ c'2 \\time 2/4 d'2 }") }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, /\\time in the middle of a bar/)
    end
  end
end
