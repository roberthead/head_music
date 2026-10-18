require "spec_helper"

describe HeadMusic::Notation::LilyPond::BarCommands do
  subject(:bar_commands) { described_class.new(layout) }

  let(:layout) { instance_double(HeadMusic::Notation::LilyPond::PartLayout, staff_named: nil) }
  let(:flow) { HeadMusic::Content::Flow.new(key_signature: "C major", meter: "4/4") }
  let(:voice) { flow.add_voice }
  let(:event_class) { HeadMusic::Notation::LilyPond::VoiceStream::Event }

  def apply(kind, position, **fields)
    bar_commands.apply(event_class.new(kind: kind, line: 3, **fields), voice, flow.position(position))
  end

  describe "a bar check" do
    it "passes at a bar's start" do
      expect { apply(:bar_check, "2:1") }.not_to raise_error
    end

    it "fails elsewhere, saying how far into the bar it stands" do
      expect { apply(:bar_check, "2:2") }.to raise_error(HeadMusic::Notation::LilyPond::ParseError, "Bar check failed at: 1/4 in bar 2 (line 3)")
    end
  end

  describe "a key or meter change" do
    it "changes the key from its bar" do
      apply(:key, "2:1", key_signature: HeadMusic::Rudiment::KeySignature.get("G major"))
      expect(flow.key_signature_at(2)).to eq HeadMusic::Rudiment::KeySignature.get("G major")
    end

    it "changes the meter from its bar" do
      apply(:time, "3:1", meter: HeadMusic::Rudiment::Meter.get("3/4"))
      expect(flow.meter_at(3)).to eq HeadMusic::Rudiment::Meter.get("3/4")
    end

    it "lets a voice repeat a change already in force" do
      apply(:time, "3:1", meter: HeadMusic::Rudiment::Meter.get("3/4"))
      expect { apply(:time, "3:1", meter: HeadMusic::Rudiment::Meter.get("3/4")) }.not_to raise_error
    end

    it "refuses a different change at the same bar" do
      apply(:time, "3:1", meter: HeadMusic::Rudiment::Meter.get("3/4"))
      expect { apply(:time, "3:1", meter: HeadMusic::Rudiment::Meter.get("2/4")) }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, "Conflicting \\time at bar 3 (line 3)")
    end

    it "refuses a disagreement with the first bar's key" do
      expect { apply(:key, "1:1", key_signature: HeadMusic::Rudiment::KeySignature.get("D major")) }
        .to raise_error(HeadMusic::Notation::LilyPond::ParseError, "Conflicting \\key at bar 1 (line 3)")
    end

    it "is unsupported in the middle of a bar" do
      expect { apply(:key, "2:3", key_signature: HeadMusic::Rudiment::KeySignature.get("G major")) }
        .to raise_error(HeadMusic::Notation::LilyPond::UnsupportedFeatureError, "\\key in the middle of a bar is not supported (line 3)")
    end
  end

  it "refuses a crossing to a staff outside the voice's group" do
    expect { apply(:staff_change, "2:1", staff_name: "lower") }
      .to raise_error(HeadMusic::Notation::LilyPond::ParseError, %(No staff named "lower" in this voice's staff group (line 3)))
  end
end
