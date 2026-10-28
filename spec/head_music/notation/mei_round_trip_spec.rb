require "spec_helper"

# Every golden and fixture flow written to MEI, read back, and written again
# gives the same document, and the flow read back keeps the music field by
# field; see spec/support/mei_round_trip.rb for what that comparison leaves
# out. The exclusions that change what a flow reads back as are pinned under
# "named exclusions".
describe HeadMusic::Notation::MEI do
  fixture_names = lambda do |fixtures|
    fixtures.singleton_methods.sort.select do |name|
      parameters = fixtures.method(name).parameters
      parameters.all? { |type, _| %i[opt key].include?(type) } && !%i[all crossing_barline].include?(name)
    end
  end

  flows = {
    **MEIFixtures.every_fixture,
    **ABCFixtures.constants.sort.to_h { |name| ["ABCFixtures::#{name}", -> { HeadMusic::Notation::ABC.parse(ABCFixtures.const_get(name)) }] },
    **%i[piano_part_marks marked_dal_segno_al_coda marked_da_capo_al_fine clef_changes two_verses]
      .to_h { |name| ["MuseScoreFixtures.#{name}", -> { MuseScoreFixtures.public_send(name) }] },
    **%i[melismas two_verse_melismas].to_h { |name| ["MelismaFixtures.#{name}", -> { MelismaFixtures.public_send(name) }] },
    "MuseScoreFixtures.clarinet_changes" => -> { MuseScoreFixtures.clarinet_changes.flows.first }
  }.except(*MEIHelpers::REFUSED_SAMPLES.keys)

  projects = {
    **fixture_names.call(LayoutFixtures).to_h { |name| ["LayoutFixtures.#{name}", -> { LayoutFixtures.public_send(name) }] },
    "MuseScoreFixtures.clarinet_changes" => -> { MuseScoreFixtures.clarinet_changes }
  }

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

  def layout_of(flow)
    project = HeadMusic::Content::Project.new(name: flow.name.to_s).tap { |adopting| adopting.add_flow(flow) }
    project.add_layout(concert_pitch: false)
  end

  describe "the goldens" do
    MEIFixtures.names.each do |name|
      describe name do
        let(:golden) { File.read(MEIFixtures.path(name)) }

        it "keeps the music of the flow that was rendered" do
          expect(mei_music(parse(golden))).to eq mei_music(MEIFixtures.source(name))
        end

        it "writes back the golden it was read from" do
          reparsed = parse(golden)
          rewritten = (name == "clarinet_changes_transposed") ? layout_of(reparsed).to_mei : reparsed.to_mei
          expect(rewritten).to eq golden
        end
      end
    end
  end

  flows.each do |name, build|
    describe name do
      let(:flow) { instance_exec(&build) }

      it("writes back the document it was read from") { expect_same_document(flow) }

      it("keeps the music") { expect_mei_round_trip(flow) }
    end
  end

  projects.each do |name, build|
    describe "#{name}, transposed" do
      let(:project) { instance_exec(&build) }

      it "reads each flow of its transposed layout back at concert pitch" do
        reparsed = described_class.parse_book(project.add_layout(concert_pitch: false).to_mei)
        expect(reparsed.map { |flow| mei_music(flow) }).to eq(project.flows.map { |flow| mei_music(flow) })
      end
    end
  end

  describe "named exclusions" do
    def melody(meter: "4/4", tempo: nil)
      HeadMusic::Content::Flow.new(name: "Melody", meter: meter, tempo: tempo).tap { |flow| flow.add_voice }
    end

    it "reads a fermata's stretch back as the default, since MEI writes none" do
      flow = melody.tap { |built| built.voices.first.place("1:1", :whole, "C4") }
      flow.add_fermata("1:1", :whole, stretch: 3)
      expect(parse(render(flow)).fermatas.map(&:stretch)).to eq [HeadMusic::Time::Fermata::DEFAULT_STRETCH]
    end

    it "reads an authored whole-bar rest at a voice's start or end back as absence" do
      flow = melody.tap { |built| built.voices.first.place("1:1", :whole).then { built.voices.first.place("2:1", :whole, "C4") } }
      expect(parse(render(flow)).voices.first.voice_events.map(&:to_s)).to eq ["whole C4 at 2:1:000"]
    end

    it "reads a note tied across a barline back as its written links" do
      flow = melody.tap { |built| built.voices.first.place("1:1", :half).then { built.voices.first.place("1:3", :whole, "C4") } }
      expect(parse(render(flow)).voices.first.voice_events.map(&:to_s)).to eq ["half rest at 1:1:000", "half tied to half C4 at 1:3:000"]
    end

    it "reads a melisma that stops before an unsung note back as held up to the next syllable, since @con names no end" do
      flow = MelismaFixtures.short_melisma
      expect(melisma_ends(parse(render(flow)))).to eq [[0, 1, "1:1:000", "1:3:000"]]
    end

    it "reads an unauthored clef back as the one the writer falls back to" do
      flow = melody.tap { |built| built.voices.first.place("1:1", :whole, "C3") }
      expect([flow.parts.first.staff_system.staves.first.clef, parse(render(flow)).parts.first.staff_system.staves.first.clef.name_key]).to eq [nil, "bass_clef"]
    end
  end

  describe "a chord holding one letter and octave under two alterations" do
    def chord_then(key, chord, after)
      HeadMusic::Content::Flow.new(meter: "4/4", key_signature: key).tap do |flow|
        flow.add_voice.place("1:1", :half, chord).voice.place("1:3", :half, after)
      end
    end

    [["C major", %w[F4 F#4], "F4", %w[n s]], ["F major", %w[Bb4 B4], "Bb4", %w[f n]]].each do |key, chord, after, shown|
      it "shows #{shown.join(" and ")} in #{key} and reads #{chord.join(" and ")} back" do
        flow = chord_then(key, chord, after)
        expect(render(flow).scan(/oct="4" accid="(\w+)"/).flatten.first(2)).to eq shown
        expect_mei_round_trip(flow)
      end
    end
  end

  describe "TupletGenerator" do
    TupletGenerator::SEEDS.each do |seed|
      it "round-trips seed #{seed}" do
        flow = TupletGenerator.flow(seed)
        expect_same_document(flow)
        expect_mei_round_trip(flow)
      end
    end
  end

  describe "HairpinGenerator" do
    HairpinGenerator::SEEDS.each do |seed|
      it "round-trips seed #{seed}" do
        flow = HairpinGenerator.flow(seed)
        expect_same_document(flow)
        expect_mei_round_trip(flow)
      end
    end
  end
end
