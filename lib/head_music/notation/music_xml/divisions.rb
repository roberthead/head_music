# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Computes the smallest MusicXML <divisions> value (subdivisions of a
  # quarter note) that lets every note, rest, and whole-measure duration
  # in a flow be expressed as an exact integer. Notes count by what they
  # sound, so a septuplet sixteenth asks for sevenths of a quarter.
  class Divisions
    def self.for(flow)
      denominators(flow).reduce(1) { |lcm, denominator| lcm.lcm(denominator) }
    end

    def self.denominators(flow)
      meter_denominators(flow) + note_denominators(flow) + timed_mark_denominators(flow)
    end
    private_class_method :denominators

    # A whole measure of rest must also be expressible as an integer, so the
    # base meter and every meter change's quarter-note-equivalent duration
    # contributes a denominator too (e.g. 3/8 needs divisions divisible by 2).
    def self.meter_denominators(flow)
      ([flow.meter] + flow.meter_changes.values).flat_map do |meter|
        [
          Rational(4 * meter.top_number, meter.bottom_number).denominator,
          beam_group_denominator(meter)
        ]
      end
    end
    private_class_method :meter_denominators

    # Beams group by the meter's beat, which must be whole divisions too: a
    # 6/8 bar of triplets alone has no eighth to make its dotted quarter so.
    # A beat longer than any note value, as in 12/1, beams nothing.
    def self.beam_group_denominator(meter)
      unit = meter.beam_group_unit
      unit&.unit ? DurationWriter.single_quarter_fraction(unit).denominator : 1
    end
    private_class_method :beam_group_denominator

    # The pieces a note splits into at barlines are written too, and under a
    # ratio they may need finer divisions than the note they come from.
    def self.note_denominators(flow)
      flow.voices.flat_map do |voice|
        voice.voice_events.flat_map do |voice_event|
          pieces = HeadMusic::Notation::BarSplitter.segments_of(voice_event).filter_map(&:rhythmic_value)
          [voice_event.rhythmic_value, *pieces].flat_map { |rhythmic_value| chain_denominators(rhythmic_value) }
        end
      end
    end
    private_class_method :note_denominators

    # A dynamic or a hairpin end can fall mid-note, where its <offset> must be
    # a whole number.
    def self.timed_mark_denominators(flow)
      owners = flow.parts.map { |part| [part, part.voices] } + flow.voices.map { |voice| [voice, [voice]] }
      owners.flat_map do |owner, voices|
        positions = owner.dynamic_events.map(&:position) +
          owner.spans.select(&:hairpin?).flat_map { |span| [span.from, span.to] }
        positions.map { |position| (HeadMusic::Notation::BarSplitter.mark_offset(flow, position, voices) * 4).denominator }
      end
    end
    private_class_method :timed_mark_denominators

    def self.chain_denominators(rhythmic_value)
      rhythmic_value.tied_chain.map { |link| DurationWriter.sounding_quarter_fraction(link).denominator }
    end
    private_class_method :chain_denominators
  end
end
