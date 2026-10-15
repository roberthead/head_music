require "spec_helper"

describe HeadMusic::Notation::MusicXML::MarkingReader do
  def parse(*measures)
    parse_musicxml_flow(musicxml_measures(*measures))
  end

  def markings(note_event)
    [note_event.articulations.map(&:name_key), note_event.ornaments.map(&:name_key), note_event.note_dynamic&.name_key]
  end

  def note_markings(flow)
    flow.voices.map { |voice| voice.note_events.map { |note_event| [note_event.position.to_s, *markings(note_event)] } }
  end

  it "reads articulations, ornaments, and an accent dynamic" do
    flow = parse(note_xml("C5", 4, "whole", notations: "<articulations><staccato/><strong-accent/></articulations>" \
      "<ornaments><trill-mark/></ornaments><dynamics><sfz/></dynamics>"))
    expect(markings(flow.voices.first.note_events.first)).to eq [%w[marcato staccato], %w[trill], "sfz"]
  end

  it "reads every group of every <notations>" do
    flow = parse(note_xml("C5", 4, "whole", after: "<notations><articulations><accent/></articulations></notations>",
      notations: "<articulations><tenuto/></articulations><ornaments><mordent/></ornaments><ornaments><turn/></ornaments>"))
    expect(markings(flow.voices.first.note_events.first)).to eq [%w[accent tenuto], %w[mordent turn], nil]
  end

  it "combines the markings of a chord's tones" do
    flow = parse(
      note_xml("C5", 4, "whole", notations: "<articulations><accent/></articulations>") +
        note_xml("E5", 4, "whole", chord: true, notations: "<articulations><tenuto/></articulations><ornaments><turn/></ornaments>")
    )
    expect(markings(flow.voices.first.note_events.first)).to eq [%w[accent tenuto], %w[turn], nil]
  end

  it "keeps the first accent dynamic of a chord" do
    flow = parse(
      note_xml("C5", 4, "whole", notations: "<dynamics><sf/></dynamics>") +
        note_xml("E5", 4, "whole", chord: true, notations: "<dynamics><fp/></dynamics>")
    )
    expect(flow.voices.first.note_events.first.note_dynamic.name_key).to eq "sf"
  end

  it "reads markings from the attack only, not a tie's later link" do
    flow = parse(
      note_xml("C5", 4, "whole", inside: %(<tie type="start"/>), notations: "<articulations><accent/></articulations>"),
      note_xml("C5", 4, "whole", inside: %(<tie type="stop"/>), notations: "<articulations><staccato/></articulations><dynamics><sfz/></dynamics>")
    )
    expect(note_markings(flow)).to eq [[["1:1:000", %w[accent], [], nil]]]
  end

  it "leaves a grace note's articulations to the grace note" do
    grace = "<note><grace/>#{pitch_xml("D5")}<type>16th</type><notations><articulations><staccato/></articulations>" \
      "<ornaments><trill-mark/></ornaments></notations></note>"
    note_event = parse(grace + note_xml("C5", 4, "whole")).voices.first.note_events.first
    expect([markings(note_event), note_event.grace_notes.first.articulations.map(&:name_key)]).to eq [[[], [], nil], %w[staccato]]
  end

  it "places a level in <notations> on the voice at its note" do
    flow = parse(note_xml("C5", 2, "half") + note_xml("D5", 2, "half", notations: "<dynamics><mf/></dynamics>"))
    voice = flow.voices.first
    expect([voice.dynamic_events.map { |event| [event.position.to_s, event.name_key] }, voice.note_events.last.note_dynamic])
      .to eq [[["1:3:000", "mf"]], nil]
  end

  it "keeps the first level at a note" do
    flow = parse(note_xml("C5", 4, "whole", notations: "<dynamics><p/></dynamics>") +
      note_xml("E5", 4, "whole", chord: true, notations: "<dynamics><ff/></dynamics>"))
    expect(flow.voices.first.dynamic_events.map(&:name_key)).to eq ["p"]
  end

  it "places a level on a rest" do
    flow = parse(rest_xml(2, "half", notations: "<dynamics><pp/></dynamics>") + note_xml("D5", 2, "half"))
    expect(flow.voices.first.dynamic_events.map { |event| [event.position.to_s, event.name_key] }).to eq [["1:1:000", "pp"]]
  end

  it "skips fermatas, breath marks, caesuras, technical marks, wavy lines, tremolos, and unknown dynamics" do
    flow = parse(note_xml("C5", 4, "whole", notations: "<fermata/><technical><up-bow/></technical>" \
      "<articulations><breath-mark/><caesura/><staccato/></articulations>" \
      "<ornaments><wavy-line type=\"start\"/><tremolo>3</tremolo></ornaments><dynamics><sffz/><other-dynamics>n</other-dynamics></dynamics>"))
    expect([markings(flow.voices.first.note_events.first), flow.voices.first.dynamic_events]).to eq [[%w[staccato], [], nil], []]
  end

  it "keeps the music whole" do
    flow = parse(rest_xml(1, "quarter", notations: "<fermata/><articulations><accent/></articulations>") +
      note_xml("C5", 3, "half", dots: 1, notations: "<fermata/>"))
    expect_music_whole(flow)
  end

  %i[marked_melody grand_staff_piano_with_dynamics spanned_melody phrases_on_split_rest spanned_piano].each do |name|
    it "round-trips the markings of MarkingFixtures.#{name}" do
      flow = MarkingFixtures.public_send(name)
      round_tripped = HeadMusic::Notation::MusicXML.parse(HeadMusic::Notation::MusicXML.render(flow))
      expect(note_markings(round_tripped)).to eq note_markings(flow)
    end
  end
end
