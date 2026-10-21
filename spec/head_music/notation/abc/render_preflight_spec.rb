require "spec_helper"

describe HeadMusic::Notation::ABC::RenderPreflight do
  def tune
    HeadMusic::Notation::ABC.parse("X:1\nT:Test\nM:4/4\nL:1/8\nK:C\nC8|D8|E8|F8|\n")
  end

  it "passes a tune it can write" do
    expect { described_class.check!(tune) }.not_to raise_error
  end

  it "refuses a second voice" do
    flow = HeadMusic::Content::Flow.new.tap { |two_voices| 2.times { two_voices.add_voice } }
    expect { described_class.check!(flow) }.to raise_error(HeadMusic::Notation::ABC::RenderError, /multi-voice/)
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
