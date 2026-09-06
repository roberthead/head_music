# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # The computed musical facts a Writer needs to serialize a flow: the
  # divisions resolution, and the duration components and beams of every
  # notehead, on top of the measure signatures the base plan tracks.
  # Separating this model from the Writer lets the beam and meter-tracking
  # logic — the intricate part of MusicXML rendering — be reasoned about and
  # tested without generating XML.
  #
  # Construction eagerly computes everything that can raise on unmappable keys or durations,
  # so a RenderPlan that builds successfully cannot fail assembly on those
  # grounds; beam annotations stay lazy because their integer-duration check
  # raises only when a bar is actually laid out.
  class RenderPlan < HeadMusic::Notation::RenderPlan
    # The number of beams a notehead of each MusicXML <type> carries alone.
    # Every other type (quarter and longer) and every rest carries none.
    BEAM_LEVELS_BY_TYPE = {
      "eighth" => 1,
      "16th" => 2,
      "32nd" => 3,
      "64th" => 4,
      "128th" => 5,
      "256th" => 6
    }.freeze

    def divisions
      @divisions ||= Divisions.for(flow)
    end

    def components_by_placement
      @components_by_placement ||= flow.voices.flat_map(&:placements).to_h do |placement|
        [placement, duration_writer.components(placement.rhythmic_value)]
      end
    end

    # A Hash keyed by [placement, component_index] holding the Array<Beam>
    # that BeamGrouper computed for that notehead. Built one bar at a time so
    # a notehead's onset is its exact integer offset from the bar start.
    def beam_annotations
      @beam_annotations ||= {}.tap do |annotations|
        flow.voices.each do |voice|
          bar_numbers.each { |bar_number| annotate_bar(voice, bar_number, annotations) }
        end
      end
    end

    # Divisions.for guarantees a whole measure of any effective meter is an
    # integer number of divisions, so the Rational's numerator is the value.
    def whole_measure_duration(bar_number)
      meter = effective_meter(bar_number)
      (Rational(4 * meter.top_number, meter.bottom_number) * divisions).numerator
    end

    # The divisions a voice's notes occupy in a bar: the sum of its components
    # there, or the whole-measure rest that stands in for an empty bar. Less
    # than a measure where the voice ended mid-bar.
    def written_duration(voice, bar_number)
      placements = placements_by_bar(voice)[bar_number]
      return whole_measure_duration(bar_number) unless placements

      placements.sum { |placement| components_by_placement[placement].sum(&:duration) }
    end

    private

    def precompute_eager_data
      key_value(flow.timeline.opening_key_signature_event)
      super
      components_by_placement
    end

    # <fifths> is required and <mode> is optional, which is exactly the shape
    # of the event: the signature always, the interpretation when there is one.
    def key_value(event)
      {fifths: event.signature, mode: KeyMapper.mode(event.tonal_context)}
    end

    def duration_writer
      @duration_writer ||= DurationWriter.new(divisions)
    end

    def annotate_bar(voice, bar_number, annotations)
      placements = placements_by_bar(voice)[bar_number]
      return unless placements

      keys = []
      events = build_bar_events(placements, keys)
      beams = BeamGrouper.annotate(events, group_unit_divisions(bar_number))
      keys.each_with_index { |key, index| annotations[key] = beams[index] }
    end

    def build_bar_events(placements, keys)
      onset = 0
      placements.flat_map do |placement|
        components_by_placement[placement].each_with_index.map do |component, component_index|
          event = BeamGrouper::Event.new(
            levels: beam_levels(placement, component),
            onset: onset,
            beam_break_before: component_index.zero? ? placement.beam_break_before : nil
          )
          keys << [placement, component_index]
          onset += component.duration
          event
        end
      end
    end

    def beam_levels(placement, component)
      return 0 if placement.rest?

      BEAM_LEVELS_BY_TYPE.fetch(component.type, 0)
    end

    # The beam-group span in integer divisions for a bar's effective meter.
    # DurationWriter.single_quarter_fraction returns an exact Rational, so the
    # product with the integer divisions is integral for every supported meter.
    def group_unit_divisions(bar_number)
      fraction = DurationWriter.single_quarter_fraction(effective_meter(bar_number).beam_group_unit) * divisions
      unless fraction.denominator == 1
        raise RenderError,
          "cannot express the beam group unit as an integer duration at #{divisions} divisions per quarter note"
      end
      fraction.to_i
    end
  end
end
