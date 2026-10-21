require "spec_helper"

describe HeadMusic::Notation::MEI::Preflight do
  let(:error) { HeadMusic::Notation::MEI::RenderError }
  let(:flow) { HeadMusic::Content::Flow.new(name: "Check", meter: "2/4") }
  let(:voice) { flow.add_voice }
  let(:snare) { HeadMusic::Rudiment::UnpitchedSound.get(:snare_drum) }

  it "passes a flow it can write" do
    voice.place("1:1", :half, "C4")
    expect { described_class.check!(flow) }.not_to raise_error
  end

  it "raises for a flow with no voices" do
    expect { described_class.check!(flow) }.to raise_error(error, /no voice events/)
  end

  it "raises for a flow whose voices hold nothing" do
    voice
    expect { described_class.check!(flow) }.to raise_error(error, /no voice events/)
  end

  it "raises for text XML cannot hold" do
    voice.place("1:1", :half, "C4").sing("la\u0007")
    expect { described_class.check!(flow) }.to raise_error(error, /XML forbids/)
  end

  it "raises for tempo text XML cannot hold" do
    voice.place("1:1", :half, "C4")
    flow.change_tempo(1, HeadMusic::Rudiment::Tempo.for_text("Lento\u0007"))
    expect { described_class.check!(flow) }.to raise_error(error, /XML forbids/)
  end

  it "raises for ramp text XML cannot hold" do
    voice.place("1:1", :half, "C4").voice.place("2:1", :half, "D4")
    flow.add_tempo_ramp(from: "1:2", to: "2:1", text: "rit.\u0007")
    expect { described_class.check!(flow) }.to raise_error(error, /XML forbids/)
  end

  it "raises for text it is given that XML cannot hold" do
    voice.place("1:1", :half, "C4")
    expect { described_class.check!(flow, ["￿"]) }.to raise_error(error, /XML forbids/)
  end

  it "raises for a gap in a voice" do
    voice.place("1:1", :quarter, "C4")
    voice.place("2:1", :half, "D4")
    expect { described_class.check!(flow) }.to raise_error(error, /expected a voice event at/)
  end

  it "raises for a dynamic after the music" do
    voice.place("1:1", :half, "C4")
    voice.place_dynamic("3:1", "p")
    expect { described_class.check!(flow) }.to raise_error(error, /after the music ends/)
  end

  it "raises for an unpitched sound" do
    voice.place("1:1", :half, snare)
    expect { described_class.check!(flow) }.to raise_error(error, /unpitched sound "snare drum" at 1:1/)
  end

  it "raises for an unpitched grace note" do
    voice.place("1:1", :half, "C4").add_grace_note(snare, :sixteenth)
    expect { described_class.check!(flow) }.to raise_error(error, /unpitched grace note .* before 1:1:000/)
  end

  it "raises for a part whose staff system changes" do
    voice.place("1:1", :half, "C4")
    voice.place("2:1", :half, "D4")
    voice.part.change_staff_system(2, HeadMusic::Content::StaffSystem.grand_staff)
    expect { described_class.check!(flow) }.to raise_error(error, /staff system change/)
  end
end
