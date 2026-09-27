# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Reads the interpretations that live on the flow's timeline rather than
  # on one spine: key signature, key designation, meter, and tempo.
  #
  # Those read before the first data row open the flow; any after it change
  # the timeline at a downbeat. The timeline is the flow's, so every kern
  # spine that states a value on a row must state the same one.
  class TimelineReader
    KINDS = %i[signature designation meter tempo].freeze

    def self.timeline?(interpretation)
      KINDS.include?(interpretation.kind)
    end

    def initialize(clock)
      @clock = clock
      @opening = {}
      @flow = nil
    end

    def open_flow(**attributes)
      @flow = HeadMusic::Content::Flow.new(
        **attributes, key_signature: opening_key_signature, meter: @opening[:meter]&.first, tempo: @opening[:tempo]&.first
      )
    end

    def read(interpretations, time, line)
      agreed(interpretations, line).each do |interpretation|
        if @flow
          change(interpretation, time, line)
        else
          @opening[interpretation.kind] = [interpretation.value, line]
        end
      end
    end

    private

    def agreed(interpretations, line)
      interpretations.group_by(&:kind).values.map do |group|
        if group.map { |interpretation| comparable(interpretation.value) }.uniq.length > 1
          raise UnsupportedFeatureError.new(
            "Kern spines disagree on one row (#{group.map(&:field).uniq.join(", ")})", line_number: line
          )
        end
        group.first
      end
    end

    def comparable(value)
      case value
      when HeadMusic::Rudiment::Tempo then [value.beat_value.to_s, value.beats_per_minute]
      when Integer then value
      when HeadMusic::Rudiment::Meter then value.to_s
      else value.name.to_s
      end
    end

    # The timeline opens with one event holding both the signature and its
    # interpretation, so an opening designation must agree with the
    # opening signature.
    def opening_key_signature
      fifths, fifths_line = @opening[:signature]
      context, context_line = @opening[:designation]
      return fifths && HeadMusic::Rudiment::KeySignature.get(HeadMusic::Rudiment::Key.for_fifths(fifths).name) unless context

      key_signature = HeadMusic::Rudiment::KeySignature.get(context.name)
      if fifths && HeadMusic::Content::Flow::Timeline.fifths_of(key_signature) != fifths
        raise UnsupportedFeatureError.new(
          "The opening key signature (#{KeyReader.signature_field(fifths)}) does not match the designation #{context}",
          line_number: [fifths_line, context_line].max
        )
      end
      key_signature
    end

    def change(interpretation, time, line)
      kind = interpretation.kind
      value = interpretation.value
      return unless change?(kind, value, @clock.in_force_number)

      @clock.at_downbeat(time, interpretation.field, line) do |bar_number|
        apply(kind, value, bar_number) if change?(kind, value, bar_number)
      end
    end

    def change?(kind, value, bar_number)
      event = @flow.timeline.key_signature_event_at(bar_number)
      case kind
      when :meter then @flow.meter_at(bar_number) != value
      when :tempo then comparable(@flow.tempo_at(bar_number)) != comparable(value)
      when :signature then event.signature != value
      when :designation then event.tonal_context&.name != value.name
      end
    end

    # A designation keeps the signature in force; a signature keeps only a
    # designation authored in the same bar, since the one in force before
    # was an interpretation of the old signature.
    def apply(kind, value, bar_number)
      case kind
      when :meter then @flow.change_meter(bar_number, value)
      when :tempo then @flow.change_tempo(bar_number, value)
      when :signature
        authored = @flow.timeline.key_signature_change_at(bar_number)
        @flow.change_key_signature(bar_number, value, tonal_context: authored&.tonal_context)
      when :designation
        signature = @flow.timeline.signature_at(bar_number)
        @flow.change_key_signature(bar_number, signature, tonal_context: value)
      end
    end
  end
end
