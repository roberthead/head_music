require "spec_helper"

# Guards the notation_styles.yml data file against the failure modes the
# sparse-overlay model is prone to: a missing/orphan instrument in the default
# style, an overlay key that never matches (a typo silently notating nothing),
# or a clef key that does not resolve.
describe "HeadMusic::Notation::NotationStyle" do
  styles = HeadMusic::Notation::NotationStyle::STYLES
  instrument_keys = HeadMusic::Instruments::Instrument::INSTRUMENTS.keys.map(&:to_s)
  default_keys = styles.fetch("default").fetch("instrument_notations").keys

  referenced_clefs = styles.values.flat_map do |style|
    style["instrument_notations"].values.flat_map do |entry|
      (entry["staves"].to_a + entry["alternatives"].to_a).map { |staff| staff["clef"] }
    end
  end.compact.uniq

  it "gives the default style an entry for every instrument" do
    expect(default_keys).to match_array(instrument_keys)
  end

  (styles.keys - ["default"]).each do |style_key|
    context "with the #{style_key} overlay" do
      overlay_keys = styles[style_key]["instrument_notations"].keys

      it "lists only instruments that also exist in the default style" do
        expect(overlay_keys - default_keys).to be_empty
      end

      it "is a sparse overlay (fewer entries than default)" do
        expect(overlay_keys.length).to be < default_keys.length
      end
    end
  end

  it "references only clefs that resolve" do
    referenced_clefs.each do |clef_key|
      expect(HeadMusic::Rudiment::Clef.get(clef_key)).to be_a(HeadMusic::Rudiment::Clef)
    end
  end
end
