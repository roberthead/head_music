require "spec_helper"

describe HeadMusic::Notation::MEI::BarlineReader do
  def marks(*items)
    flow = HeadMusic::Notation::MEI.parse(mei_document(*items))
    flow.bars.to_h { |bar| [bar.number, bar.to_h] }.reject { |_, marks| marks.empty? }
  end

  def bar(right: nil, left: nil, inside: "", number: nil, content: mei_note("C4", "1"))
    attributes = {n: number, left: left, right: right}.compact.map { |name, value| %( #{name}="#{value}") }.join
    %(<measure#{attributes}>#{mei_staff(1, content)}#{inside}</measure>)
  end

  def bars(count, **by_number)
    (1..count).map { |number| bar(number: number, **by_number.fetch(number, {})) }
  end

  it "reads @right styles onto their bars" do
    expect(marks(*bars(5, 1 => {right: "dbl"}, 2 => {right: "dashed"}, 3 => {right: "dotted"}, 4 => {right: "end"})))
      .to eq(1 => {"barline" => "double"}, 2 => {"barline" => "dashed"}, 3 => {"barline" => "dotted"}, 4 => {"barline" => "final"})
  end

  it "keeps a final barline on the last bar regular, as MEI Export writes it" do
    expect(marks(*bars(3, 2 => {right: "end"}, 3 => {right: "end"}))).to eq(2 => {"barline" => "final"})
  end

  it "reads a @left style onto the bar before" do
    expect(marks(*bars(2, 2 => {left: "dbl"}))).to eq(1 => {"barline" => "double"})
  end

  it "lets the first style of a barline win" do
    expect(marks(*bars(2, 1 => {right: "dashed"}, 2 => {left: "dbl"}))).to eq(1 => {"barline" => "dashed"})
  end

  it "reads repeat starts on either side of a barline and repeat ends" do
    expect(marks(*bars(4, 1 => {left: "rptstart"}, 2 => {right: "rptend"}, 3 => {right: "rptstart"}, 4 => {right: "rptend"}))).to eq(
      1 => {"starts_repeat" => true}, 2 => {"ends_repeat_after_num_plays" => 2},
      4 => {"starts_repeat" => true, "ends_repeat_after_num_plays" => 2}
    )
  end

  it "reads rptboth as the end of one repeat and the start of the next" do
    expect(marks(*bars(3, 1 => {left: "rptstart"}, 2 => {right: "rptboth"}, 3 => {right: "rptend"}))).to eq(
      1 => {"starts_repeat" => true}, 2 => {"ends_repeat_after_num_plays" => 2},
      3 => {"starts_repeat" => true, "ends_repeat_after_num_plays" => 2}
    )
  end

  it "skips barline values the model has no style for, so that another value of the barline stands" do
    expect(marks(*bars(3, 1 => {right: "invis"}, 2 => {right: "dbldashed", left: "heavy"}, 3 => {left: "dbl"})))
      .to eq(2 => {"barline" => "double"})
  end

  it "sets the passes of the bars in each <ending>" do
    endings = [%(<ending n="1">#{bar(number: 2, right: "rptend")}</ending>), %(<ending n="2">#{bar(number: 3)}</ending>)]
    expect(marks(bar(number: 1, left: "rptstart"), *endings, bar(number: 4))).to eq(
      1 => {"starts_repeat" => true}, 2 => {"ends_repeat_after_num_plays" => 2, "plays_on_passes" => [1]}, 3 => {"plays_on_passes" => [2]}
    )
  end

  it "plays a repeat with no count as often as the highest ending of its section names" do
    endings = [
      %(<ending n="1, 2">#{bar(number: 2, right: "rptend")}</ending>),
      %(<ending n="3">#{bar(number: 3)}</ending>)
    ]
    expect(marks(bar(number: 1, left: "rptstart"), *endings).dig(2, "ends_repeat_after_num_plays")).to eq 3
  end

  it "counts a repeat by a <dir> reading ×N or xN at its end, up to the most passes an ending may name" do
    counted = %w[×3 x4 ×1000].each.with_index(1).to_h { |count, number| [number, {right: "rptend", inside: %(<dir staff="1" tstamp="5">#{count}</dir>)}] }
    expect(marks(*bars(3, **counted)).transform_values { |marks| marks["ends_repeat_after_num_plays"] }).to eq(1 => 3, 2 => 4, 3 => 2)
  end

  it "lets a count stand only at a repeat's end" do
    expect(marks(*bars(2, 1 => {inside: %(<dir staff="1" tstamp="5">×3</dir>)}, 2 => {right: "rptend"})))
      .to eq(2 => {"ends_repeat_after_num_plays" => 2})
  end

  it "closes a bar at a barline inside it and opens the next" do
    second_half = %(<measure n="3" metcon="false" left="rptstart">#{mei_staff(1, mei_note("D4", "2"))}</measure>)
    halves = [bar(number: 1), bar(number: 2, content: mei_note("C4", "2"), right: "rptend"), second_half, bar(number: 4, right: "rptend")]
    expect(marks(*halves)).to eq(2 => {"ends_repeat_after_num_plays" => 2}, 3 => {"starts_repeat" => true, "ends_repeat_after_num_plays" => 2})
  end

  it "closes the last bar of a <multiRest> at its right barline" do
    rests = bar(number: 2, right: "dbl", content: %(<multiRest num="3"/>))
    expect(marks(bar(number: 1), rests, bar(number: 3))).to eq(4 => {"barline" => "double"})
  end
end
