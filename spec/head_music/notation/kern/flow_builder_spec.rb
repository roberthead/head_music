require "spec_helper"

describe HeadMusic::Notation::Kern::FlowBuilder do
  # Columns are separated by two or more spaces, so that chords can keep
  # their single spaces.
  def parse(text)
    HeadMusic::Notation::Kern.parse(text.gsub(/ {2,}/, "\t"))
  end

  def placements(voice)
    voice.placements.map(&:to_s)
  end

  describe "parts and voices" do
    subject(:flow) do
      parse(<<~KERN)
        **kern  **dynam  **kern
        *clefF4  *  *clefG2
        =1  =1  =1
        2C  p  2e
        2r  .  4d 4f
        .  .  4r
        =2  =2  =2
        1C  .  1c
        ==  ==  ==
        *-  *-  *-
      KERN
    end

    it "makes a voice of each kern spine, skipping other spines" do
      expect(flow.voices.length).to eq 2
    end

    it "gives each spine a part of its own, top-down from the rightmost" do
      expect(flow.parts.map { |part| part.voices.first.placements.first.pitch.to_s }).to eq %w[E4 C3]
    end

    it "places notes, chords, and rests" do
      expect(placements(flow.voices.first))
        .to eq ["half E4 at 1:1:000", "quarter D4 F4 at 1:3:000", "quarter rest at 1:4:000", "whole C4 at 2:1:000"]
    end

    it "sets each part's clef" do
      expect(flow.parts.map { |part| part.staff_system.first_staff.clef.name_key }).to eq %w[treble_clef bass_clef]
    end
  end

  describe "instruments and players" do
    subject(:flow) do
      parse(<<~KERN)
        **kern  **kern  **kern
        *ICvox  *ICvox  *ICvox
        *Ibass  *Ivox  *Isoprn
        *I"Bass  *I"Voice  *I"Soprano
        =1  =1  =1
        1C  1c  1cc
        *-  *-  *-
      KERN
    end

    it "maps catalog codes to instruments, leaving unknown codes without one" do
      expect(flow.parts.map { |part| part.instrument&.name_key }).to eq [:soprano_voice, nil, :bass_voice]
    end

    it "gives each part a projectless player named for the spine" do
      expect(flow.parts.map { |part| [part.player.name, part.player.project] })
        .to eq [["Soprano", nil], ["Voice", nil], ["Bass", nil]]
    end

    it "leaves a part without a name without a player" do
      expect(parse("**kern\n1c\n*-").parts.first.player).to be_nil
    end
  end

  describe "the timeline" do
    let(:opening) do
      parse(<<~KERN)
        !!!OTL: Air
        **kern  **kern
        *k[f#]  *k[f#]
        *e:  *e:
        *M3/4  *M3/4
        *MM72  *MM72
        =1  =1
        2.E  2.e
        *-  *-
      KERN
    end

    it "names the flow for its title" do
      expect(opening.name).to eq "Air"
    end

    it "reads the opening key signature and its tonal context" do
      expect([opening.key_signature.name, opening.timeline.tonal_context_at(1).name]).to eq ["E minor", "E minor"]
    end

    it "reads a signature with no designation as its conventional key" do
      expect(parse("**kern\n*k[b-e-]\n1c\n*-").key_signature.name).to eq "B♭ major"
    end

    it "reads the opening meter and tempo" do
      expect([opening.meter.to_s, opening.tempo.beats_per_minute]).to eq ["3/4", 72.0]
    end

    it "raises an unsupported-feature error when the opening signature and designation disagree" do
      expect { parse("**kern\n*k[]\n*G:\n1c\n*-") }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /does not match the designation.*\(line 3\)/)
    end

    it "raises an unsupported-feature error when spines disagree on a row" do
      expect { parse("**kern  **kern\n*M3/4  *M4/4\n1c  1e\n*-  *-") }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /disagree on one row.*\(line 2\)/)
    end

    describe "changes in the middle of the piece" do
      subject(:flow) do
        parse(<<~KERN)
          **kern  **kern
          *M4/4  *M4/4
          *k[]  *k[]
          =1  =1
          1c  1e
          =2  =2
          *M3/4  *M3/4
          *k[f#]  *k[f#]
          *MM96  *
          2.d  2.f#
          =3  =3
          *e:  *e:
          2.e  2.g
          =4  =4
          *M3/4  *M3/4
          2.e  2.g
          *-  *-
        KERN
      end

      it "changes the meter at its bar" do
        expect(flow.meter_changes.transform_values(&:to_s)).to eq(2 => "3/4")
      end

      it "changes the key signature at its bar, with no designation" do
        change = flow.timeline.key_signature_change_at(2)
        expect([change.signature, change.tonal_context]).to eq [1, nil]
      end

      it "changes the tonal context at its bar, keeping the signature" do
        change = flow.timeline.key_signature_change_at(3)
        expect([change.signature, change.tonal_context.name]).to eq [1, "E minor"]
      end

      it "changes the tempo at its bar" do
        expect(flow.tempo_at(2).beats_per_minute).to eq 96.0
      end

      it "ignores a restatement of the value in force" do
        expect(flow.meter_change_at(4)).to be_nil
      end

      it "places the music under the changed meter" do
        expect(placements(flow.voices.last).last).to eq "dotted half E4 at 4:1:000"
      end
    end

    it "applies a change read at the end of a bar from the next bar's downbeat" do
      flow = parse("**kern\n*M2/4\n=1\n2c\n*M3/4\n=2\n2.d\n*-")
      expect(flow.meter_changes.transform_values(&:to_s)).to eq(2 => "3/4")
    end

    it "raises an unsupported-feature error for a change in the middle of a bar" do
      expect { parse("**kern\n=1\n2c\n*M3/4\n2d\n*-") }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /\*M3\/4 in the middle of a bar.*\(line 4\)/)
    end

    it "raises an unsupported-feature error for a transposed spine" do
      expect { parse("**kern\n*ITrd1c2\n1c\n*-") }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /Transposed spines.*\(line 2\)/)
    end
  end

  describe "clefs" do
    subject(:flow) { parse("**kern\n*clefG2\n=1\n1c\n=2\n*clefF4\n1C\n*-") }

    it "changes the clef of the spine's staff at its bar" do
      expect(flow.parts.first.staff_system.first_staff.clef_changes.transform_values(&:name_key)).to eq(2 => "bass_clef")
    end

    it "drops a clef it does not know" do
      expect(parse("**kern\n*clefX\n1c\n*-").parts.first.staff_system.first_staff.clef).to be_nil
    end
  end

  describe "bars" do
    it "continues the count past an unnumbered barline" do
      flow = parse("**kern\n*M2/4\n=1\n2c\n=\n2d\n=\n2e\n*-")
      expect(placements(flow.voices.first).last).to eq "half E4 at 3:1:000"
    end

    it "starts from the first barline's number" do
      flow = parse("**kern\n*M2/4\n=5\n2c\n=6\n2d\n*-")
      expect(placements(flow.voices.first)).to eq ["half C4 at 5:1:000", "half D4 at 6:1:000"]
    end

    it "reads a full bar before the first barline as the bar before it" do
      flow = parse("**kern\n*M2/4\n2c\n=1\n2d\n*-")
      expect(placements(flow.voices.first)).to eq ["half C4 at 0:1:000", "half D4 at 1:1:000"]
    end

    describe "a pickup" do
      subject(:flow) do
        parse(<<~KERN)
          **kern  **kern
          *M3/4  *M3/4
          4G  8e
          .  8f
          =1  =1
          2.C  2.g
          *-  *-
        KERN
      end

      it "becomes bar 0, padded with a leading rest from its downbeat" do
        expect(placements(flow.voices.last)).to eq ["half rest at 0:1:000", "quarter G3 at 0:3:000", "dotted half C3 at 1:1:000"]
      end

      it "pads each voice by the same amount" do
        expect(placements(flow.voices.first).first(3)).to eq ["half rest at 0:1:000", "eighth E4 at 0:3:000", "eighth F4 at 0:3:480"]
      end

      it "leaves every voice continuous" do
        expect(flow.voices.map(&:first_gap)).to eq [nil, nil]
      end
    end

    it "numbers a pickup from the first barline" do
      flow = parse("**kern\n*M2/4\n4c\n=5\n2d\n*-")
      expect(placements(flow.voices.first)).to eq ["quarter rest at 4:1:000", "quarter C4 at 4:2:000", "half D4 at 5:1:000"]
    end

    it "has no pickup when the first barline precedes the music" do
      flow = parse("**kern\n*M3/4\n=1-\n2.c\n=2\n2.d\n*-")
      expect(placements(flow.voices.first)).to eq ["dotted half C4 at 1:1:000", "dotted half D4 at 2:1:000"]
    end

    it "raises when a pickup is longer than its bar" do
      expect { parse("**kern\n*M2/4\n1c\n=1\n2d\n*-") }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /pickup bar is longer than bar 0's meter \(line 4\)/)
    end

    it "raises an unsupported-feature error for a pickup before bar 0" do
      expect { parse("**kern\n*M2/4\n4c\n=0\n2d\n*-") }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /pickup before bar 0/)
    end

    it "applies a change read in the pickup from bar 1" do
      flow = parse("**kern\n*M2/4\n4c\n*M3/4\n=1\n2.d\n*-")
      expect(flow.meter_changes.transform_values(&:to_s)).to eq(1 => "3/4")
    end

    describe "repeats" do
      subject(:flow) do
        parse(<<~KERN)
          **kern
          *M3/4
          4c
          =1!|:
          2.d
          =2
          2e
          =:|!
          4f
          =3:|!|:
          2.g
          ==:|!
          *-
        KERN
      end

      def repeat_flags
        flow.bars(3).to_h { |bar| [bar.number, [bar.starts_repeat?, bar.ends_repeat_after_num_plays]] }
      end

      it "starts a repeat on the bar after !|:" do
        expect(repeat_flags[1]).to eq [true, nil]
      end

      it "records a repeat sign in the middle of a bar on its whole bar" do
        expect(repeat_flags[2]).to eq [false, 2]
      end

      it "keeps the bar whole across a repeat sign in its middle" do
        expect(placements(flow.voices.first)[4]).to eq "quarter F4 at 2:3:000"
      end

      it "ends a repeat on the bar before :|! and starts one on the bar after" do
        expect(repeat_flags[3]).to eq [true, 2]
      end

      it "leaves the pickup bar without repeats" do
        expect(repeat_flags[0]).to eq [false, nil]
      end
    end

    it "ignores a repeat end at the first barline when nothing precedes it" do
      flow = parse("**kern\n=1:|!\n1c\n*-")
      expect(flow.bars(1).map(&:ends_repeat?)).to eq [false]
    end

    it "accepts a short final bar" do
      flow = parse("**kern\n*M3/4\n=1\n2.c\n=2\n2d\n==\n*-")
      expect(placements(flow.voices.first).last).to eq "half D4 at 2:1:000"
    end

    it "raises when a bar is too long" do
      expect { parse("**kern\n*M2/4\n=1\n2c\n4d\n=2\n2e\n*-") }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /Bar 1 is too long.*\(line 6\)/)
    end

    it "raises when the last bar is too long" do
      expect { parse("**kern\n*M2/4\n=1\n2c\n4d\n*-") }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /Bar 1 is too long.*\(line 6\)/)
    end

    it "reads a file with no barlines from bar 1" do
      expect(placements(parse("**kern\n1c\n1d\n*-").voices.first)).to eq ["whole C4 at 1:1:000", "whole D4 at 2:1:000"]
    end

    it "raises when spines disagree on a bar's length" do
      expect { parse("**kern  **kern\n*M2/4  *M2/4\n=1  =1\n2c  4e\n.  2f\n=2  =2\n*-  *-") }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /disagree on the length of bar 1 \(line 6\)/)
    end

    it "raises an unsupported-feature error for a short bar in the middle of the piece" do
      expect { parse("**kern\n*M2/4\n=1\n4c\n=2\n2d\n*-") }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /Bar 1 is shorter than its meter.*\(line 5\)/)
    end

    it "raises an unsupported-feature error for a bar number variant" do
      expect { parse("**kern\n=1a\n1c\n*-") }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /variants.*=1a.*\(line 2\)/)
    end

    it "raises an unsupported-feature error for a bar number that skips" do
      expect { parse("**kern\n*M2/4\n=1\n2c\n=3\n2d\n*-") }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /Bar 3 does not follow bar 1/)
    end
  end

  describe "ties" do
    it "fuses a tie into one placement" do
      expect(placements(parse("**kern\n[4c\n4c]\n2d\n*-").voices.first))
        .to eq ["quarter tied to quarter C4 at 1:1:000", "half D4 at 1:3:000"]
    end

    it "fuses a tie across a barline between different durations into one placement" do
      flow = parse("**kern\n*M2/4\n=1\n4c\n[4g\n=2\n8g]\n8a\n4b\n*-")
      expect(placements(flow.voices.first)[1..2]).to eq ["quarter tied to eighth G4 at 1:2:000", "eighth A4 at 2:1:480"]
    end

    it "fuses a longer chain" do
      flow = parse("**kern\n*M2/4\n=1\n[2c\n=2\n2c_\n=3\n2c]\n*-")
      expect(placements(flow.voices.first)).to eq ["half tied to half tied to half C4 at 1:1:000"]
    end

    it "ties chords" do
      expect(placements(parse("**kern\n[2c [2e\n2c] 2e]\n*-").voices.first)).to eq ["half tied to half C4 E4 at 1:1:000"]
    end

    it "keeps the spine's time across the tie" do
      flow = parse("**kern  **kern\n[4c  2e\n4c]  .\n2d  2f\n*-  *-")
      expect(placements(flow.voices.last).last).to eq "half D4 at 1:3:000"
    end

    it "raises when a tie is never closed" do
      expect { parse("**kern\n[4c\n4d\n*-") }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /tie is never closed \(line 2\)/)
    end

    it "raises when a tie is still open at the end" do
      expect { parse("**kern\n4c\n[4c\n*-") }.to raise_error(HeadMusic::Notation::Kern::ParseError, /never closed \(line 3\)/)
    end

    it "raises for a stray ]" do
      expect { parse("**kern\n4c]\n*-") }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /\] continues a tie that was never opened \(line 2\)/)
    end

    it "raises for a stray _" do
      expect { parse("**kern\n4c_\n*-") }.to raise_error(HeadMusic::Notation::Kern::ParseError, /_ continues a tie/)
    end

    it "raises for a tie between different pitches" do
      expect { parse("**kern\n[4c\n4d]\n*-") }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /same pitch \(line 3\)/)
    end

    it "raises for a tie between a note and a differently spelled pitch" do
      expect { parse("**kern\n[4c#\n4d-]\n*-") }.to raise_error(HeadMusic::Notation::Kern::ParseError, /same pitch/)
    end

    it "raises for a tied rest" do
      expect { parse("**kern\n[4r\n4r]\n*-") }.to raise_error(HeadMusic::Notation::Kern::ParseError, /rest cannot be tied/)
    end

    it "raises an unsupported-feature error for a chord tied only in part" do
      expect { parse("**kern\n[4c 4e\n4c] 4e\n*-") }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /tied only in part/)
    end
  end

  describe "time slices" do
    it "raises when a note begins before the note before it ends" do
      expect { parse("**kern  **kern\n2c  4e\n4d  4f\n*-  *-") }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /spine 1 begins before the note before it ends \(line 3\)/)
    end

    it "raises when a null token falls where no note is sounding" do
      expect { parse("**kern  **kern\n4c  4e\n.  4f\n*-  *-") }
        .to raise_error(HeadMusic::Notation::Kern::ParseError, /null token in spine 1 falls where no note is sounding \(line 3\)/)
    end

    it "passes over a row with no attacks" do
      expect(parse("**kern  **dynam\n2c  p\n.  <\n2d  .\n*-  *-").voices.first.placements.length).to eq 2
    end

    it "drops grace notes" do
      expect(placements(parse("**kern\n8qc\n1d\n*-").voices.first)).to eq ["whole D4 at 1:1:000"]
    end
  end

  describe "errors" do
    it "raises when there is no music" do
      expect { parse("**kern\n*M4/4\n*-") }.to raise_error(HeadMusic::Notation::Kern::ParseError, /contains no music/)
    end

    it "does not memoize a failure" do
      document = HeadMusic::Notation::Kern::Document.new(HeadMusic::Notation::Kern::Lexer.new("**kern\n*-").records)
      builder = described_class.new(document)
      expect { builder.flow }.to raise_error(HeadMusic::Notation::Kern::ParseError)
      expect { builder.flow }.to raise_error(HeadMusic::Notation::Kern::ParseError)
    end

    it "raises an unsupported-feature error for a split in the music" do
      expect { parse("**kern\n1c\n*^\n1c  1e\n*v  *v\n*-") }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /not yet supported/)
    end

    it "raises an unsupported-feature error for an instrument change in the middle of a spine" do
      expect { parse("**kern\n*I\"Flute\n1c\n*I\"Oboe\n1d\n*-") }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /Changing \*I"Oboe.*\(line 4\)/)
    end
  end
end
