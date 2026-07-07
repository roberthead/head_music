# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Computes the smallest MusicXML <divisions> value (subdivisions of a
  # quarter note) that lets every note, rest, and whole-measure duration
  # in a composition be expressed as an exact integer.
  class Divisions
    def self.for(composition)
      denominators(composition).reduce(1) { |lcm, denominator| lcm.lcm(denominator) }
    end

    def self.denominators(composition)
      meter_denominators(composition) + note_denominators(composition)
    end
    private_class_method :denominators

    # A whole measure of rest must also be expressible as an integer, so the
    # base meter and every meter change's quarter-note-equivalent duration
    # contributes a denominator too (e.g. 3/8 needs divisions divisible by 2).
    # Bar#meter is a plain attr_accessor, so a bar's meter is normalized
    # through Meter.get here in case a caller assigned it a bare string.
    def self.meter_denominators(composition)
      meters = [composition.meter] + composition.bars.map(&:meter).compact
      meters.map { |meter| HeadMusic::Rudiment::Meter.get(meter) }
        .map { |meter| Rational(4 * meter.top_number, meter.bottom_number).denominator }
    end
    private_class_method :meter_denominators

    def self.note_denominators(composition)
      composition.voices.flat_map do |voice|
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
