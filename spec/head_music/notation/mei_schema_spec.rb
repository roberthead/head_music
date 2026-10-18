require "spec_helper"
require "open3"

# Validates rendered MEI against the MEI 5.1 CMN schema, run only when
# MEI_SCHEMA names a local copy of mei-CMN.rng. The schema is not committed
# here.
describe HeadMusic::Notation::MEI, oracle: :mei_schema do
  schema = ENV["MEI_SCHEMA"]

  def schema_errors(xml, schema)
    output, status = Open3.capture2e("xmllint", "--noout", "--nonet", "--relaxng", schema, "-", stdin_data: xml)
    status.success? ? [] : output.lines.reject { |line| line.include?("validates") }.map(&:strip)
  end

  MEIFixtures.every_fixture.each do |name, build|
    next if MEIHelpers::REFUSED_SAMPLES.key?(name)

    it "renders #{name} as a valid MEI 5.1 document" do
      expect(schema_errors(instance_exec(&build).to_mei, schema)).to eq []
    end
  end

  MEIFixtures.names.each do |name|
    it "commits the #{name} golden document as valid MEI 5.1" do
      expect(schema_errors(File.read(MEIFixtures.path(name)), schema)).to eq []
    end
  end

  MEILayerFixtures.all.each do |name|
    it "renders the beams, tuplets, spans, and grace notes of MEILayerFixtures.#{name} as valid MEI" do
      expect(schema_errors(described_class.render(MEILayerFixtures.public_send(name)), schema)).to eq []
    end
  end

  it "renders a document of several flows as valid MEI" do
    xml = described_class::Writer.new([LilyPondFixtures.duo, LilyPondFixtures.rests], title: "Two").to_s
    expect(schema_errors(xml, schema)).to eq []
  end

  it "renders credits and a transposed render as valid MEI" do
    flow = LilyPondFixtures.piano_and_melody
    flow.work = HeadMusic::Content::Work.new(title: "Work").with_credit("Ann", :composer).with_credit("Bo", :lyricist)
    expect(schema_errors(described_class.render(flow, arranger: %w[Cy Di], transposed: true), schema)).to eq []
  end

  it "renders labels, instruments, and roles as valid MEI" do
    flow = LilyPondFixtures.piano_and_melody.tap(&:add_part)
    flow.parts.each_with_index { |part, index| part.player = HeadMusic::Content::Player.new(name: "Player #{index}") }
    expect(schema_errors(described_class.render(flow), schema)).to eq []
  end

  it "renders written and gestural accidentals as valid MEI" do
    flow = HeadMusic::Notation::ABC.parse("X:1\nT:Accidentals\nM:4/4\nL:1/4\nK:D\n{^^f}F=F[^C=C]^^F-|F_B__B=c|]\n")
    expect(schema_errors(described_class.render(flow), schema)).to eq []
  end

  it "renders a transposed part's accidentals as valid MEI" do
    project = LayoutFixtures.clarinet_project(pitches: %w[E4 F#4 Bb4 C4])
    written = project.add_layout(concert_pitch: false).realize(project.flows.first)
    expect(schema_errors(described_class.render(written, transposed: true), schema)).to eq []
  end

  it "renders two verses as valid MEI" do
    expect(schema_errors(described_class.render(MuseScoreFixtures.two_verses), schema)).to eq []
  end

  it "renders a syllable sung on a chord as valid MEI" do
    flow = HeadMusic::Content::Flow.new(meter: "4/4")
    voice = flow.add_voice
    voice.place("1:1", :half, %w[C4 E4]).sing("Hal", hyphen_after: true)
    voice.place("1:3", :half, %w[D4 F4]).sing("lo")
    expect(schema_errors(described_class.render(flow), schema)).to eq []
  end

  it "renders instrument changes in concert pitch as valid MEI" do
    expect(schema_errors(MuseScoreFixtures.clarinet_changes.flows.first.to_mei, schema)).to eq []
  end

  def transposed_mei(project)
    described_class.render(project.add_layout(concert_pitch: false).realize(project.flows.first), transposed: true)
  end

  it "renders transposed instrument changes as valid MEI" do
    expect(schema_errors(transposed_mei(MuseScoreFixtures.clarinet_changes), schema)).to eq []
  end

  it "renders a key change in a transposed trio as valid MEI" do
    trio = LayoutFixtures.trio.tap { |project| project.flows.first.change_key_signature(2, "G major") }
    expect(schema_errors(transposed_mei(trio), schema)).to eq []
  end

  it "renders a layout of several flows, with arrangers, as valid MEI" do
    project = LayoutFixtures.suite.tap { |suite| %w[Ann Bo].each { |name| suite.add_credit(name, :arranger) } }
    expect(schema_errors(project.add_layout.to_mei, schema)).to eq []
  end

  it "renders a transposed layout as valid MEI" do
    expect(schema_errors(LayoutFixtures.trio.add_layout(concert_pitch: false).to_mei, schema)).to eq []
  end

  it "renders a tempo change as valid MEI" do
    flow = LilyPondFixtures.key_and_meter_change.tap { |changes| changes.change_tempo(2, "dotted quarter = 60") }
    expect(schema_errors(described_class.render(flow), schema)).to eq []
  end

  it "renders the part marks of the grand-staff piano as valid MEI" do
    expect(schema_errors(described_class.render(MuseScoreFixtures.piano_part_marks), schema)).to eq []
  end

  it "renders a chord's articulation, ornament, and note dynamic as valid MEI" do
    flow = HeadMusic::Notation::ABC.parse("X:1\nT:Marks\nM:2/4\nL:1/4\nK:C\n!tenuto![CE] D|]\n")
    flow.voices.first.voice_events.first.embellish(:trill).note_dynamic = :sf
    expect(schema_errors(described_class.render(flow), schema)).to eq []
  end

  %w[marked_dal_segno_al_coda marked_da_capo_al_fine].each do |name|
    it "renders the navigation of #{name} as valid MEI" do
      expect(schema_errors(described_class.render(MuseScoreFixtures.public_send(name)), schema)).to eq []
    end
  end

  it "renders an ending of several passes and a repeat played thrice as valid MEI" do
    flow = HeadMusic::Notation::ABC.parse("X:1\nT:Volta\nM:2/4\nL:1/4\nK:C\n|: C D |[1,2 EF :|[3 GA |]\n")
    flow.bar(2).ends_repeat_after_num_plays = 3
    expect(schema_errors(described_class.render(flow), schema)).to eq []
  end

  it "renders what every extension hook adds as valid MEI" do
    register_every_mei_hook
    flow = HeadMusic::Notation::ABC.parse("X:1\nT:Hooks\nM:2/4\nL:1/4\nK:C\n{B}CD|[EG]F|]\n")
    expect(schema_errors(described_class.render(flow), schema)).to eq []
  end
end
