require "spec_helper"

describe HeadMusic::Notation::MusicXML::TempoWriter do
  def render(flow)
    HeadMusic::Notation::MusicXML.render(flow)
  end

  def document(flow)
    REXML::Document.new(render(flow))
  end

  # Each <direction> or <sound> that writes a tempo in the first part, by
  # measure, with what it holds.
  def tempo_directions(flow, part: 1)
    doc = document(flow)
    REXML::XPath.match(doc, "//part[#{part}]/measure").flat_map do |measure|
      REXML::XPath.match(measure, "direction[.//words or .//metronome or .//dashes or sound] | sound").map do |element|
        [measure.attributes["number"], *described(element)]
      end
    end
  end

  def described(element)
    return ["sound #{element.attributes["tempo"]}"] if element.name == "sound"

    types = REXML::XPath.match(element, "direction-type/*").map { |type| type_text(type) }
    offset = REXML::XPath.first(element, "offset")
    sound = REXML::XPath.first(element, "sound")
    [*types, offset && "offset #{offset.text}", sound && "sound #{sound.attributes["tempo"]}"].compact
  end

  def type_text(type)
    case type.name
    when "words" then type.text
    when "dashes" then "dashes #{type.attributes["type"]}"
    when "metronome" then "#{REXML::XPath.match(type, "beat-unit|beat-unit-dot").map(&:name).join(" ")} = #{REXML::XPath.first(type, "per-minute").text}"
    end
  end

  def flow_with(tempo = nil, meter: "4/4")
    HeadMusic::Content::Flow.new(name: "Tempos", meter: meter, tempo: tempo).tap do |flow|
      voice = flow.add_voice
      counts = HeadMusic::Rudiment::Meter.get(meter).top_number
      (1..2).each { |bar| (1..counts).each { |count| voice.place("#{bar}:#{count}", flow.meter.count_unit.to_s, "C4") } }
    end
  end

  def tempo(beat, bpm, **options)
    HeadMusic::Rudiment::Tempo.new(beat, bpm, **options)
  end

  it "writes nothing for the default tempo" do
    expect(tempo_directions(flow_with)).to be_empty
  end

  it "writes an opening tempo's text and metronome mark, then its sound" do
    flow = flow_with(tempo("quarter", 100, text: "Andante"))
    expect(tempo_directions(flow)).to eq [["1", "Andante", "beat-unit = 100", "sound 100"]]
  end

  it "writes a tempo whose number was not written as its words and sound" do
    flow = flow_with(HeadMusic::Rudiment::Tempo.for_text("Allegro"))
    expect(tempo_directions(flow)).to eq [["1", "Allegro", "sound 120"]]
  end

  it "counts the sound in quarter notes per minute" do
    flow = flow_with(tempo("dotted quarter", 60), meter: "6/8")
    expect(tempo_directions(flow)).to eq [["1", "beat-unit beat-unit-dot = 60", "sound 90"]]
  end

  it "writes a beat under a tuplet as its sound alone" do
    flow = flow_with(tempo(HeadMusic::Rudiment::RhythmicValue.get("quarter", tuplet: "3:2"), 90))
    expect(tempo_directions(flow).first.last).to start_with "sound 60"
  end

  it "writes a tempo with neither text nor a written number as a bare sound" do
    expect(tempo_directions(flow_with(tempo("quarter", 100, metronome_mark: false)))).to eq [["1", "sound 100"]]
  end

  it "writes a sound of a fraction of a quarter note per minute as a decimal" do
    expect(tempo_directions(flow_with(tempo("dotted quarter", 55.5), meter: "6/8")).first.last).to eq "sound 83.25"
  end

  it "writes a change at its downbeat" do
    flow = flow_with
    flow.change_tempo(2, tempo("half", 50))
    expect(tempo_directions(flow)).to eq [["2", "beat-unit = 50", "sound 100"]]
  end

  it "writes the tempo marks in the first part only" do
    flow = flow_with(tempo("quarter", 100))
    flow.add_voice.place("1:1", :whole, "C3")
    expect(tempo_directions(flow, part: 2)).to be_empty
  end

  describe "a ramp" do
    it "writes its text and dashes at its start, and its target with the dashes' stop at its end" do
      flow = flow_with
      flow.add_tempo_ramp(from: "1:3", to: "2:2", to_tempo: tempo("quarter", 80), text: "rall.")
      expect(tempo_directions(flow)).to eq [["1", "rall.", "dashes start"], ["2", "dashes stop", "beat-unit = 80", "sound 80"]]
    end

    it "writes an end inside a note at its offset, moving the sound with it" do
      flow = HeadMusic::Notation::ABC.parse("X:1\nM:4/4\nL:1/4\nK:C\nC4|D4|\n")
      flow.add_tempo_ramp(from: "1:3", to: "2:2", to_tempo: tempo("quarter", 80))
      offsets = REXML::XPath.match(document(flow), "//direction/offset").map { |offset| [offset.text, offset.attributes["sound"]] }
      expect([tempo_directions(flow), offsets])
        .to eq [[["1", "rit.", "dashes start", "offset 2"], ["2", "dashes stop", "beat-unit = 80", "offset 1", "sound 80"]], [%w[2 yes], %w[1 yes]]]
    end

    it "writes rit. for a slowing ramp with no text, and only the dashes' stop where it has no target" do
      flow = flow_with
      flow.add_tempo_ramp(from: "2:1", to: "2:3")
      expect(tempo_directions(flow)).to eq [["2", "rit.", "dashes start"], ["2", "dashes stop"]]
    end

    it "writes an end on the final barline after the last bar's notes" do
      flow = flow_with
      flow.add_tempo_ramp(from: "2:1", to: "3:1", text: "rit.")
      last_measure = REXML::XPath.match(document(flow), "//measure").last
      expect(last_measure.elements.to_a.map(&:name).last(3)).to eq %w[note direction barline]
      expect(tempo_directions(flow).last).to eq ["2", "dashes stop"]
    end
  end

  it "writes an \"a tempo\" with the tempo it restores to play" do
    flow = flow_with(tempo("quarter", 100))
    flow.add_tempo_ramp(from: "1:1", to: "2:1", to_tempo: tempo("quarter", 60))
    flow.add_a_tempo("2:3")
    expect(tempo_directions(flow).last).to eq ["2", "a tempo", "sound 100"]
  end
end
