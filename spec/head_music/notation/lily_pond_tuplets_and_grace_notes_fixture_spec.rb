require "spec_helper"

# A hand-written score that compiles under LilyPond 2.26 without warnings,
# using each tuplet and grace form the reader accepts.
describe HeadMusic::Notation::LilyPond do
  subject(:flow) { described_class.parse(File.read(File.expand_path("../../fixtures/notation/lily_pond/tuplets_and_grace_notes.ly", __dir__))) }

  let(:upper) { flow.voices.first }
  let(:lower) { flow.voices.last }

  def tuplets(voice)
    voice.tuplets.map { |group| [group.from.to_s, group.to.to_s, group.ratio.to_s, group.unit.to_s] }
  end

  def graces(voice)
    voice.note_events.reject { |event| event.grace_notes.empty? }.map do |event|
      [event.position.to_s, event.grace_notes.map { |grace| "#{grace}#{"~" if grace.tied?}" }]
    end
  end

  it "fills every bar of both voices" do
    expect([upper.first_gap, lower.first_gap, flow.voices.map { |voice| voice.next_position.to_s }])
      .to eq [nil, nil, ["6:1:000", "6:1:000"]]
  end

  it "brackets the upper voice's span form, with a short bracket for its remainder" do
    expect(tuplets(upper).first(5)).to eq [
      ["1:1:000", "1:2:000", "triplet", "eighth"], ["1:2:000", "1:3:000", "triplet", "eighth"],
      ["1:3:000", "1:4:000", "triplet", "eighth"], ["1:4:000", "1:4:320", "triplet", "eighth"],
      ["1:4:320", "2:1:000", "triplet", "quarter"]
    ]
  end

  it "brackets the upper voice's mixed values and single notes" do
    expect(tuplets(upper)[5, 4].map(&:first)).to eq %w[3:1:000 3:2:000 3:2:640 3:3:320]
  end

  it "brackets the upper voice's other ratios" do
    expect(tuplets(upper).drop(9)).to eq [
      ["3:4:000", "4:1:000", "5:4", "sixteenth"], ["4:4:000", "5:1:000", "7:4", "sixteenth"], ["5:1:000", "5:2:000", "6:4", "sixteenth"]
    ]
  end

  it "brackets the lower voice's \\tupletSpan and \\times" do
    expect(tuplets(lower)).to eq [
      ["1:1:000", "1:2:000", "triplet", "eighth"], ["1:2:000", "1:3:000", "triplet", "eighth"],
      ["1:3:000", "2:1:000", "triplet", "quarter"], ["3:1:000", "4:1:000", "triplet", "half"]
    ]
  end

  it "rounds the septuplet from its start" do
    septuplet = upper.voice_events.select { |event| event.position.bar_number == 4 }.drop(2)
    expect(septuplet.map { |event| event.position.to_s }.values_at(1, 6)).to eq %w[4:4:137:034 4:4:822:206]
  end

  it "reads the grace notes, dropping those before a rest and after a note" do
    expect(graces(upper)).to eq [
      ["2:1:000", ["grace sixteenth D5"]], ["2:2:000", ["slashed grace sixteenth E5", "slashed grace sixteenth D5"]],
      ["2:3:000", ["grace eighth D5"]], ["2:4:000", ["slashed grace eighth E5"]],
      ["3:1:000", ["grace sixteenth D5"]], ["5:2:000", ["slashed grace sixteenth B4"]]
    ]
  end

  it "reads a tied grace note and a grace chord's slur" do
    expect([graces(lower), lower.spans.map { |span| [span.to_s, span.from_grace?] }]).to eq [
      [["4:1:000", ["grace sixteenth C3~"]], ["5:1:000", ["grace sixteenth G2", "grace sixteenth B2"]]],
      [["slur from the grace notes before 5:1:000 to 5:1:000", true]]
    ]
  end

  it "slurs the appoggiatura and acciaccaturas to their main notes" do
    expect(upper.spans.select(&:from_grace?).map { |span| span.from.to_s }).to eq %w[2:3:000 2:4:000 5:2:000]
  end

  it "places the \\after inside a tuplet at its scaled offset" do
    expect(upper.dynamic_events.map(&:to_s)).to eq ["p at 3:1:640"]
  end
end
