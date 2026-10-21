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
  # grounds. Beam annotations, which cannot raise, stay lazy.
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

    def components_by_segment
      @components_by_segment ||= flow.voices.flat_map(&:voice_events).each_with_object({}) do |voice_event, components|
        segments = HeadMusic::Notation::BarSplitter.segments_of(voice_event)
        pieces = duration_writer.split_components(segments.map { |segment| segment.rhythmic_value!(RenderError) })
        segments.zip(pieces) { |segment, piece| components[segment] = piece }
      end
    end

    # A Hash keyed by [segment, component_index] holding the Array<Beam>
    # that BeamGrouper computed for that notehead, one bar at a time.
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

    def tuplet_marks
      @tuplet_marks ||= TupletMarks.new(self)
    end

    def tempo_writer
      @tempo_writer ||= TempoWriter.new(flow)
    end

    def direction_plan(part)
      @direction_plans ||= {}.compare_by_identity
      @direction_plans[part] ||= DirectionPlan.new(part, self)
    end

    def wedge_numbers(part)
      @wedge_numbers ||= {}.compare_by_identity
      @wedge_numbers[part] ||= WedgeNumbers.new(part, self)
    end

    def slur_numbers(part)
      @slur_numbers ||= {}.compare_by_identity
      @slur_numbers[part] ||= SlurNumbers.new(part, self)
    end

    # The divisions a voice's notes occupy in a bar: the sum of its components
    # there, or the whole-measure rest that stands in for an empty bar. Less
    # than a measure where the voice ended mid-bar.
    def written_duration(voice, bar_number)
      segments = segments_by_bar(voice)[bar_number]
      return whole_measure_duration(bar_number) unless segments

      segments.sum { |segment| components_by_segment[segment].sum(&:duration) }
    end

    private

    def precompute_eager_data
      key_value(flow.timeline.opening_key_signature_event)
      super
      components_by_segment
      tuplet_marks
      flow.parts.each do |part|
        slur_numbers(part)
        wedge_numbers(part)
      end
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
      segments = segments_by_bar(voice)[bar_number]
      return unless segments

      links = HeadMusic::Notation::WrittenLinks.for(segments, error_class: RenderError)
      beams = BeamGrouper.annotate(links.map { |link| beam_event(link) }, effective_meter(bar_number))
      links.each_with_index { |link, index| annotations[[link.segment, link.index]] = beams[index] }
    end

    def beam_event(link)
      voice_event = link.segment.voice_event
      HeadMusic::Notation::BeamGroups::Event.new(
        levels: beam_levels(voice_event, components_by_segment[link.segment][link.index]),
        onset: link.offset,
        beam_break_before: link.index.zero? ? voice_event.beam_break_before : nil
      )
    end

    def beam_levels(voice_event, component)
      return 0 if voice_event.rest?

      BEAM_LEVELS_BY_TYPE.fetch(component.type, 0)
    end
  end
end
