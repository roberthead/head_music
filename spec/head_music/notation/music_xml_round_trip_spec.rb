require "spec_helper"

# Every fixture flow written to MusicXML, read back, and written again gives
# the same document, and the flow read back keeps the music field by field;
# see spec/support/music_xml_round_trip.rb for what that comparison leaves
# out.
describe HeadMusic::Notation::MusicXML do
  fixtures_directory = File.expand_path("../../fixtures/notation", __dir__)

  # The fixtures each module builds with no arguments.
  fixture_names = lambda do |fixtures|
    fixtures.singleton_methods.sort.select do |name|
      parameters = fixtures.method(name).parameters
      parameters.all? { |type, _| %i[opt key].include?(type) } && !%i[all crossing_barline].include?(name)
    end
  end

  flows = {
    **ABCFixtures.constants.sort.to_h { |name| ["ABCFixtures::#{name}", -> { HeadMusic::Notation::ABC.parse(ABCFixtures.const_get(name)) }] },
    **fixture_names.call(LilyPondFixtures).to_h { |name| ["LilyPondFixtures.#{name}", -> { LilyPondFixtures.public_send(name) }] },
    **Dir[File.join(fixtures_directory, "kern", "*.krn")].sort.to_h { |path| [File.basename(path), -> { HeadMusic::Notation::Kern.parse(File.read(path)) }] },
    **Dir[File.join(fixtures_directory, "lily_pond", "*.ly")].sort.to_h { |path| [File.basename(path), -> { HeadMusic::Notation::LilyPond.parse(File.read(path)) }] },
    **fixture_names.call(MarkingFixtures).to_h { |name| ["MarkingFixtures.#{name}", -> { MarkingFixtures.public_send(name) }] },
    **fixture_names.call(NavigationFixtures).to_h { |name| ["NavigationFixtures.#{name}", -> { NavigationFixtures.public_send(name) }] },
    **HairpinFixtures.all.to_h { |name| ["HairpinFixtures.#{name}", -> { HairpinFixtures.public_send(name) }] },
    **TupletFixtures.all.to_h { |name| ["TupletFixtures.#{name}", -> { TupletFixtures.public_send(name) }] },
    **%i[piano_part_marks marked_dal_segno_al_coda marked_da_capo_al_fine clef_changes two_verses]
      .to_h { |name| ["MuseScoreFixtures.#{name}", -> { MuseScoreFixtures.public_send(name) }] },
    "MuseScoreFixtures.clarinet_changes" => -> { MuseScoreFixtures.clarinet_changes.flows.first }
  }

  projects = {
    **fixture_names.call(LayoutFixtures).to_h { |name| ["LayoutFixtures.#{name}", -> { LayoutFixtures.public_send(name) }] },
    "MuseScoreFixtures.clarinet_changes" => -> { MuseScoreFixtures.clarinet_changes }
  }

  # The reader pads every voice to the flow's end, so a voice that is
  # silent for whole bars, written as <rest measure="yes"/>, comes back as
  # rests the writer then writes as such.
  padded = %w[
    LilyPondFixtures.pickup_and_short_final_bar LilyPondFixtures.duo LilyPondFixtures.tacet
    HairpinFixtures.hairpin_in_voice_that_ends_early
  ]

  # The writer gives a one-voice part's voice dynamics and hairpins no
  # <voice>, so they come back as the part's, which it writes in another
  # place.
  one_voice_marks = %w[
    LilyPondFixtures.melody_with_part_dynamics tuplets_and_grace_notes.ly MarkingFixtures.marked_melody
    HairpinFixtures.hairpin_starting_on_split_note HairpinFixtures.touching_hairpins_on_tied_note
    HairpinFixtures.hairpin_on_split_rest HairpinFixtures.hairpins_after_short_final_bar
    HairpinFixtures.level_inside_hairpin MuseScoreFixtures.marked_dal_segno_al_coda
    MuseScoreFixtures.marked_da_capo_al_fine
  ]

  # Instrument changes read back only as the concert pitch their
  # <transpose>s give, so a layout of the flow read back writes no
  # <transpose> after the first.
  changes_instrument = %w[MuseScoreFixtures.clarinet_changes]

  def render(flow, **options)
    described_class.render(flow, **options)
  end

  def parse(xml)
    described_class.parse(xml)
  end

  def expect_same_document(flow, **options)
    rendered = render(flow, **options)
    expect(render(parse(rendered), **options)).to eq rendered
  end

  # The document the reader's flow writes is the one it reads back from.
  def expect_stable_document(flow)
    rendered = render(parse(render(flow)))
    expect(render(parse(rendered))).to eq rendered
  end

  def written(flow)
    project = flow.project || HeadMusic::Content::Project.new(name: flow.name.to_s).tap { |adopting| adopting.add_flow(flow) }
    project.add_layout(kind: :score, concert_pitch: false).realize(flow)
  end

  it "finds every exclusion among the fixtures" do
    expect((padded + one_voice_marks) - flows.keys).to eq []
    expect(changes_instrument - projects.keys).to eq []
  end

  flows.each do |name, build|
    describe name do
      let(:flow) { instance_exec(&build) }

      if padded.include?(name) || one_voice_marks.include?(name)
        it("writes back the document it reads") { expect_stable_document(flow) }
      else
        it("writes back the document it was read from") { expect_same_document(flow) }
      end

      it("keeps the music") { expect_musicxml_round_trip(flow) }
    end
  end

  projects.each do |name, build|
    describe "#{name}, transposed" do
      let(:project) { instance_exec(&build) }

      unless changes_instrument.include?(name)
        it "writes back each flow's transposed document from the flow it reads" do
          project.flows.each do |flow|
            rendered = render(written(flow), transposed: true)
            expect(render(written(parse(rendered)), transposed: true)).to eq rendered
          end
        end
      end

      it "reads each flow back at concert pitch" do
        project.flows.each do |flow|
          reparsed = parse(render(written(flow), transposed: true))
          expect(musicxml_music(reparsed)).to eq musicxml_music(flow)
        end
      end
    end
  end

  describe "TupletGenerator" do
    TupletGenerator::SEEDS.each do |seed|
      it "round-trips seed #{seed}" do
        flow = TupletGenerator.flow(seed)
        expect_same_document(flow)
        expect_musicxml_round_trip(flow)
      end
    end
  end

  describe "HairpinGenerator" do
    HairpinGenerator::SEEDS.each do |seed|
      it "round-trips seed #{seed}" do
        flow = HairpinGenerator.flow(seed)
        expect_same_document(flow)
        expect_musicxml_round_trip(flow)
      end
    end
  end
end
