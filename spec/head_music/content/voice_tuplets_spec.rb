require "spec_helper"

describe HeadMusic::Content::Voice do
  subject(:voice) { flow.add_voice }

  let(:flow) { HeadMusic::Content::Flow.new }
  let(:triplet_eighth) { HeadMusic::Rudiment::RhythmicValue.get(:eighth, tuplet: "3:2") }
  let(:septuplet_sixteenth) { HeadMusic::Rudiment::RhythmicValue.get(:sixteenth, tuplet: "7:4") }

  def value(name, tuplet: nil)
    HeadMusic::Rudiment::RhythmicValue.get(name, tuplet: tuplet)
  end

  def place_in_turn(*values, sounds: "C4")
    values.each { |rhythmic_value| voice.place(voice.next_position, rhythmic_value, sounds) }
  end

  describe "#group_tuplet" do
    it "groups the story's triplet, placed at its rounded positions" do
      voice.place("1:1", triplet_eighth, "C4")
      voice.place("1:1:320", triplet_eighth, "D4")
      voice.place("1:1:640", triplet_eighth, "E4")
      group = voice.group_tuplet(from: "1:1", to: "1:2")
      expect([group.to_s, group.unit.to_s, group.voice_events.length]).to eq ["3:2 tuplet from 1:1:000 to 1:2:000", "eighth", 3]
    end

    it "groups a quarter and an eighth under 3:2, counting in eighths" do
      place_in_turn(value(:quarter, tuplet: "3:2"), triplet_eighth)
      group = voice.group_tuplet(from: "1:1", to: "1:2")
      expect([group.unit.to_s, voice.voice_events.map(&:next_position).map(&:to_s)]).to eq ["eighth", %w[1:1:640 1:2:000]]
    end

    it "gives a quarter and an eighth under 3:2 their exact subticks" do
      place_in_turn(value(:quarter, tuplet: "3:2"), triplet_eighth)
      expect(voice.voice_events.map { |voice_event| voice_event.rhythmic_value.subticks }).to eq [153_600, 76_800]
    end

    it "counts six 6:4 sixteenths in sixteenths" do
      place_in_turn(*Array.new(6, value(:sixteenth, tuplet: "6:4")))
      expect(voice.group_tuplet(from: "1:1", to: "1:2").unit.to_s).to eq "sixteenth"
    end

    it "counts six triplet eighths in one bracket in quarters" do
      place_in_turn(*Array.new(6, triplet_eighth))
      expect(voice.group_tuplet(from: "1:1", to: "1:3").unit.to_s).to eq "quarter"
    end

    it "takes a unit it is given" do
      place_in_turn(*Array.new(3, triplet_eighth))
      expect(voice.group_tuplet(from: "1:1", to: "1:2", unit: :sixteenth).unit.to_s).to eq "sixteenth"
    end

    it "holds a rest and a chord" do
      place_in_turn(triplet_eighth)
      voice.place(voice.next_position, triplet_eighth)
      voice.place(voice.next_position, triplet_eighth, %w[E4 G4])
      group = voice.group_tuplet(from: "1:1", to: "1:2")
      expect(group.voice_events.map { |voice_event| [voice_event.rest?, voice_event.chord?] }).to eq [[false, false], [true, false], [false, true]]
    end

    it "ends on the first link of a chain that mixes ratios" do
      place_in_turn(triplet_eighth, triplet_eighth, value("triplet eighth tied to quarter"))
      group = voice.group_tuplet(from: "1:1", to: "1:2")
      expect([group.links.length, group.voice_events.length, voice.next_position.to_s]).to eq [3, 3, "1:3:000"]
    end

    it "begins on a later link of a chain" do
      place_in_turn(value("quarter tied to triplet eighth"), triplet_eighth, triplet_eighth)
      expect(voice.group_tuplet(from: "1:2", to: "1:3").links.map { |link| link.voice_event.position.to_s })
        .to eq %w[1:1:000 1:2:320 1:2:640]
    end

    it "groups a septuplet, keeping its rounded positions" do
      place_in_turn(*Array.new(7, septuplet_sixteenth))
      positions = voice.voice_events.map { |voice_event| voice_event.position.to_s }
      voice.group_tuplet(from: "1:1", to: "1:2")
      expect([voice.voice_events.map { |voice_event| voice_event.position.to_s }, voice.first_gap]).to eq [positions, nil]
    end

    it "measures each onset of a later septuplet group from its start" do
      place_in_turn(*Array.new(14, septuplet_sixteenth))
      voice.group_tuplet(from: "1:1", to: "1:2")
      voice.group_tuplet(from: "1:2", to: "1:3")
      expect(voice.voice_events[7..].map(&:onset_remainder)).to eq [0, 2r / 7, -3r / 7, -1r / 7, 1r / 7, 3r / 7, -2r / 7]
    end

    it "lets groups touch" do
      place_in_turn(*Array.new(6, triplet_eighth))
      voice.group_tuplet(from: "1:2", to: "1:3")
      voice.group_tuplet(from: "1:1", to: "1:2")
      expect(voice.tuplets.map(&:to_s)).to eq ["3:2 tuplet from 1:1:000 to 1:2:000", "3:2 tuplet from 1:2:000 to 1:3:000"]
    end

    it "keeps the voice gapless after a note replaces a rest inside a group" do
      [%w[C4], [], %w[E4]].each { |sounds| voice.place(voice.next_position, triplet_eighth, sounds) }
      voice.group_tuplet(from: "1:1", to: "1:2")
      voice.place("1:1:320", triplet_eighth, "D4")
      expect([voice.first_gap, voice.voice_events[1].rest?]).to eq [nil, false]
    end

    describe "validation" do
      before { place_in_turn(*Array.new(3, triplet_eighth), value(:quarter)) }

      it "refuses a group that does not end after it starts" do
        expect { voice.group_tuplet(from: "1:2", to: "1:1") }
          .to raise_error(ArgumentError, "the tuplet from 1:2:000 to 1:1:000 must end after it starts")
      end

      it "refuses a group that does not start on a link, naming the ratio sounding there" do
        expect { voice.group_tuplet(from: "1:1:100", to: "1:2") }
          .to raise_error(ArgumentError, "the 3:2 tuplet from 1:1:100 to 1:2:000 must start where a note, rest, or tied link starts")
      end

      it "refuses a group that does not fill its span" do
        expect { voice.group_tuplet(from: "1:1", to: "1:1:900") }
          .to raise_error(ArgumentError, /the 3:2 tuplet from 1:1:000 to 1:1:900 must end where .* filling its span exactly/)
      end

      it "refuses a group holding a value without its ratio" do
        expect { voice.group_tuplet(from: "1:1", to: "1:3") }
          .to raise_error(ArgumentError, /the 3:2 tuplet from 1:1:000 to 1:3:000 must hold values of one tuplet ratio, but the quarter at 1:2:000 has none/)
      end

      it "refuses a unit that is tied or carries a ratio" do
        expect { voice.group_tuplet(from: "1:1", to: "1:2", unit: "triplet eighth") }
          .to raise_error(ArgumentError, /the 3:2 tuplet from 1:1:000 to 1:2:000 needs a plain or dotted value for its unit/)
      end

      it "refuses a group overlapping another as a nested tuplet" do
        voice.group_tuplet(from: "1:1", to: "1:2")
        expect { voice.group_tuplet(from: "1:1:320", to: "1:2") }
          .to raise_error(ArgumentError, "nested tuplets are not supported: the 3:2 tuplet from 1:1:320 to 1:2:000 " \
            "overlaps the 3:2 tuplet from 1:1:000 to 1:2:000")
      end

      it "refuses the same group twice" do
        voice.group_tuplet(from: "1:1", to: "1:2")
        expect { voice.group_tuplet(from: "1:1", to: "1:2") }.to raise_error(ArgumentError, /nested tuplets are not supported/)
      end
    end

    it "refuses a group holding a value of another ratio" do
      place_in_turn(triplet_eighth, value(:sixteenth, tuplet: "5:4"))
      expect { voice.group_tuplet(from: "1:1", to: "1:1:512") }
        .to raise_error(ArgumentError, /but the 5:4 sixteenth at 1:1:320 is not 3:2/)
    end

    it "refuses a group whose events are not consecutive" do
      voice.place("1:1", triplet_eighth, "C4")
      voice.place("1:1:640", triplet_eighth, "E4")
      expect { voice.group_tuplet(from: "1:1", to: "1:2") }
        .to raise_error(ArgumentError, /the 3:2 tuplet from 1:1:000 to 1:2:000 must hold consecutive notes and rests, but none starts at 1:1:320/)
    end

    it "refuses a group of a rounding ratio that ends inside a voice event" do
      place_in_turn(value(([septuplet_sixteenth.to_s] * 8).join(" tied to ")))
      expect { voice.group_tuplet(from: "1:1", to: "1:2") }
        .to raise_error(ArgumentError, /the 7:4 tuplet from 1:1:000 to 1:2:000 must start and end where notes or rests do/)
    end

    it "groups part of a run of a rounding ratio, keeping the run's exact onsets" do
      place_in_turn(*Array.new(9, septuplet_sixteenth))
      remainders = voice.voice_events.map(&:onset_remainder)
      group = voice.group_tuplet(from: voice.voice_events[2].position, to: voice.voice_events[8].next_position)
      expect([group.to_s, voice.voice_events.map(&:onset_remainder), voice.first_gap])
        .to eq ["7:4 tuplet from 1:1:274:069 to 1:2:274:069", remainders, nil]
    end

    it "groups back-to-back brackets that each hold part of a septuplet beat" do
      place_in_turn(*Array.new(14, septuplet_sixteenth))
      [0..2, 3..9, 10..13].each { |range| voice.group_tuplet(from: voice.voice_events[range.first].position, to: voice.voice_events[range.last].next_position) }
      expect(voice.tuplets.map { |group| [group.from, group.to].join("-") })
        .to eq %w[1:1:000-1:1:411:103 1:1:411:103-1:2:411:103 1:2:411:103-1:3:000]
    end

    it "refuses a group of a rounding ratio starting inside one of its notes" do
      place_in_turn(*Array.new(7, septuplet_sixteenth))
      expect { voice.group_tuplet(from: "1:1:100", to: "1:2") }
        .to raise_error(ArgumentError, "the 7:4 tuplet from 1:1:100 to 1:2:000 must start where a note, rest, or tied link starts, " \
          "but it falls inside the 7:4 sixteenth at 1:1:000, in a run of values rounded to the nearest subtick")
    end
  end

  describe "#place inside a group" do
    before do
      place_in_turn(*Array.new(3, triplet_eighth))
      voice.group_tuplet(from: "1:1", to: "1:2")
    end

    it "refuses a new event inside a group" do
      expect { voice.place("1:1:100", :sixteenth, "C4") }
        .to raise_error(ArgumentError, "cannot place a sixteenth at 1:1:100 inside the 3:2 tuplet from 1:1:000 to 1:2:000")
    end

    it "merges a chord tone onto a note inside a group" do
      voice.place("1:1:320", triplet_eighth, "F4")
      expect(voice.voice_event_at(flow.position("1:1:320")).pitches.map(&:to_s)).to eq %w[C4 F4]
    end

    it "places at the group's exclusive end" do
      voice.place("1:2", :quarter, "G4")
      expect(voice.first_gap).to be_nil
    end
  end

  describe "#tuplet_at" do
    before do
      place_in_turn(*Array.new(6, triplet_eighth))
      voice.group_tuplet(from: "1:1", to: "1:2")
      voice.group_tuplet(from: "1:2", to: "1:3")
    end

    it "answers the group covering a position" do
      expect(%w[1:1 1:1:960 1:2:500].map { |position| voice.tuplet_at(position).from.to_s }).to eq %w[1:1:000 1:2:000 1:2:000]
    end

    it "answers nil outside every group" do
      expect(voice.tuplet_at("1:3")).to be_nil
    end
  end

  describe "#to_h" do
    it "writes its tuplets" do
      place_in_turn(*Array.new(3, triplet_eighth))
      voice.group_tuplet(from: "1:1", to: "1:2")
      expect(voice.to_h["tuplets"]).to eq [{"from" => "1:1:000", "to" => "1:2:000", "unit" => "eighth"}]
    end

    it "writes no tuplets key without groups" do
      place_in_turn(triplet_eighth)
      expect(voice.to_h).not_to have_key("tuplets")
    end
  end
end
