# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Reads the interpretations that live on the flow's timeline rather than
  # on one spine: key signature, key designation, meter and its common- or
  # cut-time sign, and tempo.
  #
  # Those read before the first data row open the flow; any after it change
  # the timeline at a downbeat. The timeline is the flow's, so every kern
  # spine that states a value on a row must state the same one.
  #
  # Interpretations on the rows between two data rows or barlines take
  # effect together, so a meter and its sign, or a tempo's words and its
  # number, each written on a row of its own, are one change.
  class TimelineReader
    KINDS = %i[signature designation meter meter_symbol tempo].freeze

    def self.timeline?(interpretation)
      KINDS.include?(interpretation.kind)
    end

    def initialize(clock)
      @clock = clock
      @pending = {}
      @time = nil
      @flow = nil
    end

    # A movement designation, !!!OMD, is the opening tempo's text.
    def open_flow(movement_designation: nil, **attributes)
      @opening = resolved(HeadMusic::Rudiment::Meter.default)
      @pending = {}
      @flow = HeadMusic::Content::Flow.new(
        **attributes, key_signature: opening_key_signature, meter: @opening[:meter]&.first&.value,
        tempo: opening_tempo(movement_designation)
      )
    end

    def read(interpretations, time, line)
      agreed(interpretations, line).each do |interpretation|
        kind = interpretation.kind
        earlier = @pending[kind]&.first
        value = (kind == :tempo && earlier) ? merged_tempo(earlier.value, interpretation.value) : interpretation.value
        @pending[kind] = [interpretation.with(value: value), line]
      end
      @time = time
    end

    # Called before each data row and barline, and at the end, once the flow
    # is open.
    def flush
      return unless @flow

      changes = resolved(@flow.meter_at(@clock.in_force_number))
      @pending = {}
      changes.each_value { |interpretation, line| change(interpretation, @time, line) }
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

    # A tempo of words alone and a number with no words, read together, are
    # one tempo.
    def merged_tempo(earlier, later)
      if later.metronome_mark? && later.text.nil? && !earlier.metronome_mark?
        HeadMusic::Rudiment::Tempo.new(later.beat_value, later.beats_per_minute, text: earlier.text)
      elsif !later.metronome_mark? && earlier.metronome_mark? && earlier.text.nil?
        HeadMusic::Rudiment::Tempo.new(earlier.beat_value, earlier.beats_per_minute, text: later.text)
      else
        later
      end
    end

    # The pending interpretations, with a meter sign joined to the meter
    # read with it, or else to the meter in force.
    def resolved(meter_in_force)
      sign, sign_line = @pending[:meter_symbol]
      changes = @pending.except(:meter_symbol)
      return changes unless sign

      meter, line = changes[:meter] || [sign.with(kind: :meter, value: meter_in_force), sign_line]
      changes.merge(meter: [meter.with(value: MeterReader.with_symbol(meter.value, sign.value)), [line, sign_line].max])
    end

    def comparable(value)
      case value
      when HeadMusic::Rudiment::Tempo then [value.beat_value.to_s, value.beats_per_minute, value.text, value.metronome_mark?]
      when Integer, Symbol then value
      when HeadMusic::Rudiment::Meter then [value.to_s, value.symbol]
      else value.name.to_s
      end
    end

    def opening_tempo(movement_designation)
      tempo = @opening[:tempo]&.first&.value
      return tempo unless movement_designation
      return HeadMusic::Rudiment::Tempo.for_text(movement_designation) unless tempo&.metronome_mark?

      HeadMusic::Rudiment::Tempo.new(tempo.beat_value, tempo.beats_per_minute, text: movement_designation)
    end

    # The timeline opens with one event holding both the signature and its
    # interpretation, so an opening designation must agree with the
    # opening signature.
    def opening_key_signature
      signature, fifths_line = @opening[:signature]
      designation, context_line = @opening[:designation]
      fifths = signature&.value
      context = designation&.value
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

    # A meter's sign and a tempo's words count, so a change to either alone
    # is a change.
    def change?(kind, value, bar_number)
      event = @flow.timeline.key_signature_event_at(bar_number)
      case kind
      when :meter then comparable(@flow.meter_at(bar_number)) != comparable(value)
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
