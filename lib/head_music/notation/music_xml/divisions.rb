# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Computes the smallest MusicXML <divisions> value (subdivisions of a
  # quarter note) that lets every note, rest, and whole-measure duration
  # in a flow be expressed as an exact integer.
  class Divisions
    def self.for(flow)
      denominators(flow).reduce(1) { |lcm, denominator| lcm.lcm(denominator) }
    end

    def self.denominators(flow)
      meter_denominators(flow) + note_denominators(flow)
    end
    private_class_method :denominators

    # A whole measure of rest must also be expressible as an integer, so the
    # base meter and every meter change's quarter-note-equivalent duration
    # contributes a denominator too (e.g. 3/8 needs divisions divisible by 2).
    def self.meter_denominators(flow)
      ([flow.meter] + flow.meter_changes.values)
        .map { |meter| Rational(4 * meter.top_number, meter.bottom_number).denominator }
    end
    private_class_method :meter_denominators

    def self.note_denominators(flow)
      flow.voices.flat_map do |voice|
        voice.placements.flat_map { |placement| chain_denominators(placement.rhythmic_value) }
      end
    end
    private_class_method :note_denominators

    def self.chain_denominators(rhythmic_value)
      denominators = [DurationWriter.single_quarter_fraction(rhythmic_value).denominator]
      tied_value = rhythmic_value.tied_value
      denominators += chain_denominators(tied_value) if tied_value
      denominators
    end
    private_class_method :chain_denominators
  end
end
