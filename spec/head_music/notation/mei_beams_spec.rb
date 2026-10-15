require "spec_helper"

# MEI's beams come from the grouping the MusicXML writer uses, so each
# fixture's <beam> and <beamSpan> groups must be the notes MusicXML begins
# and ends its level-one beams on. Notes are compared as written pieces:
# voice event, bar, and link of its tied chain.
describe HeadMusic::Notation::MEI do
  fixtures = MEIHelpers.sample_flows.except(*MEIHelpers::REFUSED_SAMPLES.keys).merge(
    Dir[File.join(__dir__, "..", "..", "fixtures", "notation", "lily_pond", "*.ly")].sort.to_h do |path|
      ["lily_pond/#{File.basename(path)}", -> { HeadMusic::Notation::LilyPond.parse(File.read(path)) }]
    end,
    {
      "ABCFixtures::SPEED_THE_PLOUGH" => -> { HeadMusic::Notation::ABC.parse(ABCFixtures::SPEED_THE_PLOUGH) },
      "ABCFixtures::CHROMATIC_AIR" => -> { HeadMusic::Notation::ABC.parse(ABCFixtures::CHROMATIC_AIR) },
      "ABC with authored breaks in 2/4" => -> { HeadMusic::Notation::ABC.parse("X:1\nM:2/4\nL:1/16\nK:C\nCDE FGAB c |]\n") },
      "ABC with a split below the pulse in 6/8" => -> { HeadMusic::Notation::ABC.parse("X:1\nM:6/8\nL:1/8\nK:C\nab c def |]\n") }
    },
    MEILayerFixtures.all.to_h { |name| ["MEILayerFixtures.#{name}", -> { MEILayerFixtures.public_send(name) }] }
  )

  def piece_key(segment, link_index)
    [segment.voice_event.object_id, segment.bar_number, link_index]
  end

  def music_xml_beam_groups(flow)
    plan = HeadMusic::Notation::MusicXML::RenderPlan.new(flow)
    flow.voices.flat_map do |voice|
      plan.bar_numbers.flat_map do |bar_number|
        links = HeadMusic::Notation::WrittenLinks.for(plan.segments_by_bar(voice).fetch(bar_number, []))
        links.each_with_object([]) do |link, groups|
          type = plan.beam_annotations[[link.segment, link.index]].find { |beam| beam.number == 1 }&.type
          groups << [] if type == "begin"
          groups.last << piece_key(link.segment, link.index) if %w[begin continue end].include?(type)
        end
      end
    end
  end

  def mei_beam_groups(flow)
    plan = described_class::RenderPlan.new(flow)
    keys = flow.voices.flat_map { |voice| plan.bar_numbers.flat_map { |bar_number| plan.items(voice, bar_number) } }
      .to_h { |item| [item.id, piece_key(item.segment, item.link_index)] }
    document = parse_mei(described_class.render(flow))
    beams = mei_elements(document, "//mei:beam").map { |beam| beam_member_ids(beam) }
    spans = mei_attributes(document, "//mei:beamSpan", "plist").map { |plist| plist.split.map { |reference| reference.delete_prefix("#") } }
    (beams + spans).map { |ids| ids.map { |id| keys.fetch(id) } }
  end

  # Its notes and chords, but not the notes of its chords or grace notes.
  def beam_member_ids(beam)
    members = []
    beam.each_recursive do |element|
      next unless %w[note chord].include?(element.name) && element.parent.name != "chord" && !element.attributes["grace"]

      members << element.attributes["xml:id"]
    end
    members
  end

  fixtures.each do |name, build|
    it "beams #{name} as the MusicXML writer does" do
      flow = instance_exec(&build)
      expect(mei_beam_groups(flow).sort).to eq music_xml_beam_groups(flow).sort
    end
  end
end
