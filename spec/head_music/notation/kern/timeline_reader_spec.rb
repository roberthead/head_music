require "spec_helper"

describe HeadMusic::Notation::Kern::TimelineReader do
  subject(:reader) { described_class.new(clock) }

  let(:clock) { HeadMusic::Notation::Kern::BarClock.new { |_bar_number| HeadMusic::Rudiment::Meter.get("3/4") } }

  def interpretation(field)
    HeadMusic::Notation::Kern::InterpretationReader.read(field)
  end

  it "tells timeline interpretations from spine interpretations" do
    expect(%w[*M3/4 *MM96 *k[f#] *G: *clefG2 *staff1].map { |field| described_class.timeline?(interpretation(field)) })
      .to eq [true, true, true, true, false, false]
  end

  it "opens the flow with what it read before the first data row" do
    reader.read([interpretation("*M3/4"), interpretation("*k[f#]"), interpretation("*G:")], 0, 2)
    flow = reader.open_flow(name: "Minuet")
    key = flow.timeline.key_signature_event_at(1)
    expect([flow.name, flow.meter_at(1).to_s, key.signature, key.tonal_context.name.to_s]).to eq ["Minuet", "3/4", 1, "G major"]
  end

  it "raises when spines state different values on one row" do
    expect { reader.read([interpretation("*M3/4"), interpretation("*M2/4")], 0, 4) }
      .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, %r{disagree on one row \(\*M3/4, \*M2/4\) \(line 4\)})
  end

  it "raises when the opening designation does not match the opening signature" do
    reader.read([interpretation("*k[f#]"), interpretation("*F:")], 0, 2)
    expect { reader.open_flow(name: "Minuet") }
      .to raise_error(HeadMusic::Notation::Kern::UnsupportedFeatureError, /does not match the designation/)
  end
end
