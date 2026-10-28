require "spec_helper"

describe HeadMusic::Notation::ABC::RestWriter do
  subject(:writer) { described_class.new(HeadMusic::Notation::ABC::DurationWriter.new(HeadMusic::Notation::ABC::Writer::UNIT_NOTE_LENGTH)) }

  def bar_marks(music_end:, overlay: [], trailing: [], closing: [])
    HeadMusic::Notation::ABC::PositionMarks::BarMarks.new(
      attacks: [], overlay: overlay, trailing: trailing, closing: closing, music_end: music_end, length: 1r
    )
  end

  it "fills a bar the voice ends early in with rests" do
    expect(writer.trailing(bar_marks(music_end: 1/2r), 1r)).to eq " z4"
  end

  it "writes nothing after a bar its music fills" do
    expect([writer.trailing(bar_marks(music_end: 1r)), writer.overlay(bar_marks(music_end: 1r))]).to eq ["", ""]
  end
end
