require "spec_helper"

describe HeadMusic::Notation::ABC::RenderPreflight do
  def tune
    HeadMusic::Notation::ABC.parse("X:1\nT:Test\nM:4/4\nL:1/8\nK:C\nC8|D8|E8|F8|\n")
  end

  it "passes a tune it can write" do
    expect { described_class.check!(tune) }.not_to raise_error
  end

  it "passes a tune of several voices" do
    flow = HeadMusic::Notation::ABC.parse("X:1\nL:1/4\nV:S\nV:B\nK:C\nV:S\nc d e f|\nV:B\nC D E F|\n")
    expect { described_class.check!(flow) }.not_to raise_error
  end

  it "refuses a part's and its first voice's different levels at one position" do
    flow = HeadMusic::Notation::ABC.parse("X:1\nL:1/4\nV:S\nV:B\nK:C\nV:S\nc d !f!e f|\nV:B\nC D E F|\n")
    flow.voices.first.part.place_dynamic("1:3", :p)
    expect { described_class.check!(flow) }.to raise_error(HeadMusic::Notation::ABC::RenderError, /the p and the f at 1:3:000/)
  end

  it "passes two voices holding different levels at one position" do
    flow = HeadMusic::Notation::ABC.parse("X:1\nL:1/4\nV:S\nV:B\nK:C\nV:S\nc d !f!e f|\nV:B\nC D !p!E F|\n")
    expect { described_class.check!(flow) }.not_to raise_error
  end

  it "passes meter and key changes within the music" do
    flow = tune.tap do |changing|
      changing.change_meter(3, "3/4")
      changing.change_key_signature(2, "G major")
    end
    expect { described_class.check!(flow) }.not_to raise_error
  end

  it "refuses the earliest meter change where no voice sounds" do
    flow = tune.tap do |changing|
      changing.change_meter(7, "3/4")
      changing.change_meter(6, "2/4")
    end
    expect { described_class.check!(flow) }.to raise_error(HeadMusic::Notation::ABC::RenderError, /meter change at bar 6/)
  end

  it "refuses a key signature change where no voice sounds" do
    flow = tune.tap { |changing| changing.change_key_signature(5, "G major") }
    expect { described_class.check!(flow) }.to raise_error(HeadMusic::Notation::ABC::RenderError, /key signature change at bar 5/)
  end

  it "refuses a gap between voice events" do
    flow = HeadMusic::Content::Flow.new
    flow.add_voice.place("1:1", :quarter, "C4").voice.place("2:1", :quarter, "D4")
    expect { described_class.check!(flow) }.to raise_error(HeadMusic::Notation::ABC::RenderError, /insert explicit rests/)
  end
end
