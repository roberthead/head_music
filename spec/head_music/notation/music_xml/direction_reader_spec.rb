require "spec_helper"

describe HeadMusic::Notation::MusicXML::DirectionReader do
  include HairpinExpectations

  def parse(xml)
    HeadMusic::Notation::MusicXML.parse(xml)
  end

  def render(flow)
    HeadMusic::Notation::MusicXML.render(flow)
  end

  def direction_xml(types, offset: nil, voice: nil, staff: nil)
    [
      "<direction>",
      Array(types).map { |type| "<direction-type>#{type}</direction-type>" }.join,
      offset && "<offset>#{offset}</offset>",
      voice && "<voice>#{voice}</voice>",
      staff && "<staff>#{staff}</staff>",
      "</direction>"
    ].compact.join
  end

  def dynamic_xml(level, **options)
    direction_xml("<dynamics><#{level}/></dynamics>", **options)
  end

  def wedge_xml(type, number: nil, **options)
    number_attribute = number && %( number="#{number}")
    direction_xml(%(<wedge type="#{type}"#{number_attribute}/>), **options)
  end

  def quarters(*pitches, **options)
    pitches.map { |pitch| note_xml(pitch, 2, "quarter", **options) }.join
  end

  def levels(owner)
    owner.dynamic_events.map(&:to_s)
  end

  def hairpins(owner)
    owner.spans.select(&:hairpin?).map { |span| "#{span.name_key} #{span.from}-#{span.to}" }
  end

  # Every level an owner holds, as hairpin_summary labels owners.
  def level_summary(flow)
    flow.parts.each_with_index.flat_map do |part, index|
      owners = [["part", part], *part.voices.each_with_index.map { |voice, number| ["voice #{number}", voice] }]
      owners.flat_map { |label, owner| levels(owner).map { |level| [index, label, level] } }
    end.sort
  end

  # Hairpins and levels as hairpin_summary labels their owners. A one-voice
  # part's voice marks come back on the part, since the writer leaves <voice>
  # off them.
  def directions_summary(flow, one_voice_onto_part: false)
    level_entries = level_summary(flow).map { |index, label, level| [index, label, "level", level] }
    (hairpin_summary(flow) + level_entries).map do |index, label, *rest|
      moved = one_voice_onto_part && flow.parts[index].voices.one?
      [index, moved ? "part" : label, *rest]
    end.sort
  end

  def read(*measures, divisions: 2)
    parse(musicxml_measures(*measures, attributes: opening_attributes(divisions: divisions)))
  end

  def part_levels(*measures, **options)
    levels(read(*measures, **options).parts.first)
  end

  def note_dynamics(voice)
    voice.voice_events.map { |event| event.note_dynamic&.name_key }
  end

  def septuplet_xml(directions = {})
    modification = "<time-modification><actual-notes>7</actual-notes><normal-notes>4</normal-notes></time-modification>"
    %w[C4 D4 E4 F4 G4 A4 B4].each_with_index.map do |pitch, index|
      directions.fetch(index, "") + note_xml(pitch, 1, "16th", after: modification)
    end.join
  end

  let(:whole_note) { note_xml("C4", 8, "whole") }

  describe "dynamic levels" do
    it "places a level at its cursor on the part" do
      flow = read(quarters("C4", "D4") + dynamic_xml("p") + quarters("E4", "F4"))
      expect([levels(flow.parts.first), levels(flow.voices.first)]).to eq [["p at 1:3:000"], []]
    end

    it "adds its <offset> in the divisions in force" do
      second = "<attributes><divisions>4</divisions></attributes>" + dynamic_xml("f", offset: 2) + note_xml("C4", 16, "whole")
      expect(part_levels(dynamic_xml("p", offset: 3) + quarters("C4", "D4", "E4", "F4"), second))
        .to eq ["p at 1:2:480", "f at 2:1:480"]
    end

    it "clamps a negative <offset> to the start of its bar" do
      measure = dynamic_xml("p", offset: -1) + quarters("C4", "D4") + dynamic_xml("f", offset: -1) + quarters("E4", "F4")
      expect(part_levels(measure)).to eq ["p at 1:1:000", "f at 1:2:480"]
    end

    it "clamps an <offset> past its bar to the next downbeat" do
      expect(part_levels(quarters("C4", "D4", "E4", "F4") + dynamic_xml("p", offset: 4), whole_note)).to eq ["p at 2:1:000"]
    end

    it "drops a level whose <offset> has an exponent too large for Rational" do
      measure = dynamic_xml("p", offset: "1e999999999") + quarters("C4", "D4") + dynamic_xml("f") + quarters("E4", "F4")
      expect(part_levels(measure)).to eq ["f at 1:3:000"]
    end

    it "places a level at the end of a short final bar on its final barline" do
      expect(part_levels(whole_note, quarters("C4", "D4") + dynamic_xml("p", offset: 6))).to eq ["p at 3:1:000"]
    end

    it "goes to the voice its <voice> names" do
      flow = read(dynamic_xml("p", voice: "upper") + note_xml("E5", 8, "whole", voice: "upper") + backup_xml(8) +
        dynamic_xml("f", offset: 2, voice: "lower") + note_xml("C4", 8, "whole", voice: "lower"))
      expect([levels(flow.parts.first), *flow.voices.map { |voice| levels(voice) }]).to eq [[], ["p at 1:1:000"], ["f at 1:2:000"]]
    end

    it "goes to the part when its <voice> names no voice of the part" do
      flow = read(dynamic_xml("p", voice: "9") + note_xml("C4", 8, "whole", voice: "1"))
      expect([levels(flow.parts.first), levels(flow.voices.first)]).to eq [["p at 1:1:000"], []]
    end

    it "keeps the first level at a position" do
      expect(part_levels(dynamic_xml("p") + dynamic_xml("f") + whole_note)).to eq ["p at 1:1:000"]
    end

    it "reads every dynamic and wedge of every <direction-type> in a direction" do
      flow = read(direction_xml(["<dynamics><p/></dynamics>", %(<wedge type="crescendo"/>)]) + quarters("C4", "D4") +
        direction_xml(["<words>cresc.</words>", %(<wedge type="stop"/>)]) + quarters("E4", "F4"))
      expect([levels(flow.parts.first), hairpins(flow.parts.first)]).to eq [["p at 1:1:000"], ["crescendo 1:1:000-1:3:000"]]
    end

    it "skips dynamics it does not know" do
      expect(part_levels(direction_xml("<dynamics><other-dynamics>poco f</other-dynamics><mf/></dynamics>") + whole_note))
        .to eq ["mf at 1:1:000"]
    end

    it "ignores a bare <sound> and a direction with no dynamic" do
      flow = read(%(<sound tempo="96"/>) + direction_xml("<words>dolce</words>") + whole_note)
      expect([levels(flow.parts.first), hairpins(flow.parts.first), flow.voices.first.notes.length]).to eq [[], [], 1]
    end

    it "reads a direction in the second half of a bar split at a repeat at its place in the bar" do
      split = [dynamic_xml("p", offset: 2) + quarters("E4", "F4"), {implicit: true}]
      expect(part_levels(whole_note, quarters("C4", "D4"), split, whole_note)).to eq ["p at 2:4:000"]
    end

    it "places a level inside a septuplet at its exact onset" do
      flow = read(septuplet_xml(3 => dynamic_xml("mp"), 5 => dynamic_xml("f", offset: -1)) + note_xml("C5", 21, "half", dots: 1), divisions: 7)
      expect(levels(flow.parts.first)).to eq(flow.voices.first.voice_events.values_at(3, 4).zip(%w[mp f]).map { |event, level| "#{level} at #{event.position}" })
    end
  end

  describe "accents" do
    it "accents the note its owner attacks there" do
      expect(note_dynamics(read(quarters("C4") + dynamic_xml("sfz") + quarters("D4", "E4", "F4")).voices.first)).to eq [nil, "sfz", nil, nil]
    end

    it "accents only the voice its <voice> names" do
      flow = read(note_xml("E5", 8, "whole", voice: "1") + backup_xml(8) + dynamic_xml("sf", voice: "2") + note_xml("C4", 8, "whole", voice: "2"))
      expect(flow.voices.map { |voice| note_dynamics(voice) }).to eq [[nil], ["sf"]]
    end

    it "accents nothing under a held note or on a rest" do
      flow = read(dynamic_xml("sf", offset: 2) + note_xml("C4", 4, "half") + dynamic_xml("fp") + rest_xml(4, "half"))
      expect([flow.voices.first.voice_events.map(&:note_dynamic), levels(flow.parts.first)]).to eq [[nil, nil], []]
    end

    it "accents a note inside a septuplet" do
      flow = read(septuplet_xml(3 => dynamic_xml("sf")) + note_xml("C5", 21, "half", dots: 1), divisions: 7)
      expect(note_dynamics(flow.voices.first).index("sf")).to eq 3
    end
  end

  describe "wedges" do
    let(:part) { flow.parts.first }
    let(:flow) { read(*measures) }

    context "when paired by number across each other" do
      let(:measures) do
        [
          wedge_xml("crescendo", number: 2) + quarters("C4") + wedge_xml("diminuendo", number: 1, offset: 2) + quarters("D4") +
            wedge_xml("stop", number: 2) + quarters("E4") + wedge_xml("stop", number: 1) + quarters("F4"),
          note_xml("C4", 8, "whole")
        ]
      end

      it "pairs each start with the next stop of its number" do
        expect(hairpins(part)).to contain_exactly("crescendo 1:1:000-1:3:000", "diminuendo 1:3:000-1:4:000")
      end
    end

    context "with no number" do
      let(:measures) { [wedge_xml("diminuendo") + quarters("C4", "D4", "E4", "F4"), wedge_xml("stop", offset: 4) + note_xml("C4", 8, "whole")] }

      it "takes number 1" do
        expect(hairpins(part)).to eq ["diminuendo 1:1:000-2:3:000"]
      end
    end

    context "with a stop that has nothing open" do
      let(:measures) do
        [wedge_xml("stop", number: 1) + quarters("C4", "D4") + wedge_xml("crescendo", number: 1) + quarters("E4", "F4") + wedge_xml("stop", number: 1)]
      end

      it "drops the stop" do
        expect(hairpins(part)).to eq ["crescendo 1:3:000-2:1:000"]
      end
    end

    context "with a start on a number still open" do
      let(:measures) do
        [wedge_xml("crescendo") + quarters("C4", "D4") + wedge_xml("diminuendo") + quarters("E4", "F4"), wedge_xml("stop") + note_xml("C4", 8, "whole")]
      end

      it "replaces the earlier start" do
        expect(hairpins(part)).to eq ["diminuendo 1:3:000-2:1:000"]
      end
    end

    context "with a wedge never stopped" do
      let(:measures) { [wedge_xml("crescendo") + quarters("C4", "D4") + wedge_xml("diminuendo", number: 2) + quarters("E4") + wedge_xml("stop", number: 2) + quarters("F4")] }

      it "drops it" do
        expect(hairpins(part)).to eq ["diminuendo 1:3:000-1:4:000"]
      end
    end

    context "with a stop written before its own start, as MuseScore writes one" do
      let(:measures) do
        [
          wedge_xml("crescendo") + note_xml("C4", 8, "whole"),
          note_xml("D4", 8, "whole") + wedge_xml("stop", number: 2) + wedge_xml("crescendo", number: 2, offset: -4) + wedge_xml("stop", offset: -4),
          note_xml("E4", 8, "whole")
        ]
      end

      it "pairs it with the start that sounds before it" do
        expect(hairpins(part)).to contain_exactly("crescendo 1:1:000-2:3:000", "crescendo 2:3:000-3:1:000")
      end
    end

    context "with a stop on a downbeat written after the last note of the bar before" do
      let(:measures) do
        [
          wedge_xml("crescendo") + note_xml("C4", 8, "whole") + wedge_xml("stop"),
          wedge_xml("diminuendo") + note_xml("D4", 8, "whole") + wedge_xml("stop"),
          note_xml("E4", 8, "whole")
        ]
      end

      it "ends one hairpin where the next begins" do
        expect(hairpins(part)).to eq ["crescendo 1:1:000-2:1:000", "diminuendo 2:1:000-3:1:000"]
      end
    end

    context "with a stop that sounds before the next start of its number" do
      let(:measures) do
        [wedge_xml("stop", number: 2) + quarters("C4", "D4") + wedge_xml("crescendo", number: 2) + quarters("E4", "F4"), whole_note]
      end

      it "drops the stop and leaves the start open" do
        expect(hairpins(part)).to eq []
      end
    end

    context "with piano_part_marks as MuseScore 4 converted it" do
      def hairpins_by_time(flow)
        flow.parts.flat_map { |owner_part| [owner_part, *owner_part.voices] }.flat_map { |owner| hairpins(owner) }.sort
      end

      it "reads every hairpin at the moments of the render it converted" do
        read = %w[head_music musescore4].map { |kind| hairpins_by_time(parse(File.binread(MuseScoreFixtures.path("piano_part_marks", kind)))) }
        expect(read.last).to eq read.first
      end
    end

    context "with a stop where its wedge starts" do
      let(:measures) { [wedge_xml("crescendo") + wedge_xml("stop") + quarters("C4", "D4", "E4", "F4")] }

      it "drops the hairpin its owner refuses" do
        expect(hairpins(part)).to eq []
      end
    end

    context "with a continue" do
      let(:measures) { [wedge_xml("crescendo") + quarters("C4", "D4") + wedge_xml("continue") + quarters("E4", "F4") + wedge_xml("stop")] }

      it "skips it" do
        expect(hairpins(part)).to eq ["crescendo 1:1:000-2:1:000"]
      end
    end

    context "with a <voice>" do
      let(:measures) do
        [
          wedge_xml("crescendo", voice: "1") + note_xml("E5", 8, "whole", voice: "1") + wedge_xml("stop", voice: "1") +
            backup_xml(8) + note_xml("C4", 8, "whole", voice: "2"),
          note_xml("E5", 8, "whole", voice: "1") + backup_xml(8) + note_xml("C4", 8, "whole", voice: "2")
        ]
      end

      it "goes to the voice of its start" do
        expect([hairpins(part), hairpins(flow.voices.first)]).to eq [[], ["crescendo 1:1:000-2:1:000"]]
      end
    end

    context "when it stops at the end of a short final bar" do
      let(:measures) { [note_xml("C4", 8, "whole"), wedge_xml("diminuendo") + quarters("C4", "D4", "E4") + wedge_xml("stop", offset: 2)] }

      it "ends on the final barline" do
        expect([hairpins(part), flow.final_barline_position.to_s]).to eq [["diminuendo 2:1:000-3:1:000"], "3:1:000"]
      end
    end

    context "when it stops after the last note of a short final bar" do
      let(:measures) { [note_xml("C4", 8, "whole"), wedge_xml("diminuendo") + quarters("C4", "D4", "E4") + wedge_xml("stop")] }

      it "ends where the music ends" do
        expect(hairpins(part)).to eq ["diminuendo 2:1:000-2:4:000"]
      end
    end
  end

  describe "reading back the writer's directions" do
    HairpinFixtures.all.each do |fixture|
      context "with #{fixture}" do
        let(:original) { HairpinFixtures.public_send(fixture) }
        let(:flow) { parse(render(original)) }

        it "reads every hairpin and level, a one-voice part's voice marks onto the part" do
          expect(directions_summary(flow)).to eq directions_summary(original, one_voice_onto_part: true)
        end

        it "is idempotent" do
          expect(render(parse(render(flow)))).to eq render(flow)
        end

        it "keeps the music whole" do
          expect_music_whole(flow)
        end
      end
    end

    %i[septuplet septuplet_crossing_barline].each do |fixture|
      context "with hairpins and levels on the notes of #{fixture}" do
        let(:original) do
          TupletFixtures.public_send(fixture).tap do |tupleted|
            voice = tupleted.voices.first
            positions = voice.voice_events.select { |event| event.rhythmic_value.tuplet? }.map(&:position)
            voice.add_span(:crescendo, from: positions[1], to: positions[4])
            voice.place_dynamic(positions[2], :mp)
            voice.place_dynamic(positions[5], :f)
          end
        end

        it "reads them back at the same positions" do
          expect(directions_summary(parse(render(original)))).to eq directions_summary(original, one_voice_onto_part: true)
        end
      end
    end

    HairpinGenerator::SEEDS.each do |seed|
      it "reads back seed #{seed} unchanged" do
        original = HairpinGenerator.flow(seed, voices: 2, pickup: true)
        flow = parse(render(original))
        expect([directions_summary(flow), render(flow)]).to eq [directions_summary(original), render(original)]
      end
    end
  end
end
