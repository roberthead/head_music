require "spec_helper"

describe HeadMusic::Notation::Kern::PartGrouping do
  def parse(text)
    HeadMusic::Notation::Kern.parse(text.gsub(/ {2,}/, "\t"))
  end

  def staff_index(voice, bar_number)
    voice.part.staff_system_at(bar_number).staves.index { |staff| staff.equal?(voice.staff_at(bar_number)) }
  end

  describe "a grand-staff piano part with two voices in the right hand" do
    subject(:flow) do
      parse(<<~KERN)
        **kern  **kern  **kern
        *part1  *part1  *part1
        *staff2  *staff1  *staff1
        *Ipiano  *  *
        *I"Piano  *  *
        *clefF4  *clefG2  *clefG2
        *M4/4  *M4/4  *M4/4
        =1  =1  =1
        1C  2g  2e
        .  2a  2f
        =2  =2  =2
        1G  1b  1d
        *-  *-  *-
      KERN
    end

    let(:part) { flow.parts.first }

    it "makes one part" do
      expect(flow.parts.length).to eq 1
    end

    it "makes a staff for each *staff number, *staff1 on top" do
      expect(part.staff_system.staves.map { |staff| staff.clef.name_key }).to eq %w[treble_clef bass_clef]
    end

    it "braces the two staves" do
      expect(part.staff_system.bracket).to eq :brace
    end

    it "orders the voices top staff first, and the leftmost spine on a staff as its upper voice" do
      expect(part.voices.map { |voice| voice.pitches.first.to_s }).to eq %w[G4 E4 C3]
    end

    it "assigns each voice to its spine's staff" do
      expect(part.voices.map { |voice| staff_index(voice, 1) }).to eq [0, 0, 1]
    end

    it "records the assignment only for a voice off the first staff" do
      expect(part.voices.map { |voice| voice.staff_assignments.keys }).to eq [[], [], [1]]
    end

    it "gives the part the name and code stated on one of its spines" do
      expect([part.player.name, part.instrument]).to eq ["Piano", nil]
    end
  end

  describe "soprano and alto sharing a staff" do
    subject(:flow) do
      parse(<<~KERN)
        **kern  **kern  **kern
        *part2  *part1  *part1
        *staff2  *staff1  *staff1
        *Ibass  *Isoprn  *
        *I"Bass  *I"Choir  *I"Choir
        *clefF4  *clefG2  *clefG2
        =1  =1  =1
        1C  1g  1e
        *-  *-  *-
      KERN
    end

    it "makes a part for each *part number, ordered top-down by its rightmost spine" do
      expect(flow.parts.map { |part| part.player.name }).to eq %w[Choir Bass]
    end

    it "puts both voices on one staff, the leftmost spine first" do
      part = flow.parts.first
      expect([part.staff_system.staves.length, part.voices.map { |voice| voice.pitches.first.to_s }]).to eq [1, %w[G4 E4]]
    end

    it "does not brace a single staff" do
      expect(flow.parts.first.staff_system.bracket).to eq :none
    end

    it "takes the part's instrument from whichever spine carries it" do
      expect(flow.parts.map { |part| part.instrument.name_key }).to eq %i[soprano_voice bass_voice]
    end

    it "gives every part a player of its own" do
      expect(flow.parts.map(&:player).uniq(&:object_id).length).to eq 2
    end
  end

  it "gives spines without *part tags a part each, even alongside tagged spines" do
    flow = parse("**kern  **kern  **kern\n*  *part1  *part1\n1C  1e  1g\n*-  *-  *-")
    expect(flow.parts.map { |part| part.voices.length }).to eq [2, 1]
  end

  describe "staff crossings" do
    let(:crossing) do
      <<~KERN
        **kern  **kern
        *part1  *part1
        *staff2  *staff1
        *clefF4  *clefG2
        *M2/4  *M2/4
        =1  =1
        2C  2e
        =2  =2
        *staff1  *
        2g  2c
        *-  *-
      KERN
    end

    it "moves a voice to another staff at the bar its *staff tag changes" do
      voice = parse(crossing).parts.first.voices.last
      expect([staff_index(voice, 1), staff_index(voice, 2)]).to eq [1, 0]
    end

    it "raises an unsupported-feature error for a change that is not at a downbeat" do
      source = crossing.sub("=2  =2\n*staff1  *\n2g  2c", "4g  4c\n*staff1  *\n4a  4d\n=2  =2\n2g  2c").sub("2C  2e", "4C  4e")
      expect { parse(source) }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /\*staff1 in the middle of a bar.*\(line 9\)/)
    end

    describe "at a barline inside a tie" do
      subject(:voice) { parse(crossing.sub("2C  2e\n=2  =2\n*staff1  *\n2g", "[2C  2e\n=2  =2\n*staff1  *\n2C]")).parts.first.voices.last }

      it "crosses at the barline's downbeat" do
        expect([staff_index(voice, 1), staff_index(voice, 2)]).to eq [1, 0]
      end

      it "still fuses the tied notes" do
        expect(voice.placements.map(&:to_s)).to eq ["half tied to half C3 at 1:1:000"]
      end
    end

    it "raises an unsupported-feature error for a staff the part does not have" do
      expect { parse(crossing.sub("*staff1  *\n", "*staff3  *\n")) }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /\*staff3 is not a staff of its spine's part/)
    end

    it "raises an unsupported-feature error for a cross-staff tag" do
      expect { parse(crossing.sub("*staff2  *staff1", "*staff1/2  *staff1")) }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /Cross-staff.*\(line 3\)/)
    end
  end

  describe "disagreements" do
    it "raises an unsupported-feature error when spines on one staff disagree on its clef" do
      expect { parse("**kern  **kern\n*part1  *part1\n*clefG2  *clefF4\n1c  1e\n*-  *-") }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /one staff disagree on their \*clef \(line 3\)/)
    end

    it "raises an unsupported-feature error when spines on one staff change to different clefs" do
      source = "**kern  **kern\n*part1  *part1\n1c  1e\n*clefG2  *clefF4\n1c  1e\n*-  *-"
      expect { parse(source) }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /Spines on one staff disagree on its clef \(line 4\)/)
    end

    it "raises an unsupported-feature error when spines of one part disagree on their *I codes" do
      expect { parse("**kern  **kern\n*part1  *part1\n*Isoprn  *Ialto\n1c  1e\n*-  *-") }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /one part disagree on their \*I codes \(line 3\)/)
    end

    it "raises an unsupported-feature error when spines of one part disagree on their names" do
      expect { parse("**kern  **kern\n*part1  *part1\n*I\"A  *I\"B\n1c  1e\n*-  *-") }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /disagree on their \*I" names/)
    end

    it "raises an unsupported-feature error when only some spines of a part have *staff tags" do
      expect { parse("**kern  **kern\n*part1  *part1\n*staff1  *\n1c  1e\n*-  *-") }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /must all have \*staff tags or none \(line 3\)/)
    end

    it "raises an unsupported-feature error for a *part change in the middle of a spine" do
      expect { parse("**kern\n*part1\n1c\n*part2\n1d\n*-") }
        .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /Changing \*part2.*\(line 4\)/)
    end

    it "accepts a restatement of the part's name on another of its spines" do
      expect { parse("**kern  **kern\n*part1  *part1\n*I\"A  *\n1c  1e\n*  *I\"A\n1c  1e\n*-  *-") }.not_to raise_error
    end
  end
end
