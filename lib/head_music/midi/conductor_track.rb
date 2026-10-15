module HeadMusic::MIDI
  # Track 0: the sequence name, and the meter, tempo, and key in force at each
  # played bar wherever they differ from the last written, so a jump back over
  # a change restores what was in force there. Times are exact whole notes.
  class ConductorTrack
    MINOR_QUALIFIERS = %i[minor aeolian].freeze

    attr_reader :flow, :timeline

    def initialize(flow, timeline)
      @flow = flow
      @timeline = timeline
    end

    def events
      written = {}
      events = flow.name.to_s.empty? ? [] : [Text.new(0, :sequence_name, flow.name)]
      timeline.spans.each do |span|
        [time_signature(span), tempo(span), key_signature(span)].each do |event|
          kind = event.class
          next if written[kind] == event.with(tick: 0)

          written[kind] = event.with(tick: 0)
          events << event
        end
      end
      events
    end

    private

    def time_signature(span)
      meter = flow.meter_at(span.bar_number)
      meter = pickup_meter(span, meter) if span.pickup?
      TimeSignature.new(span.start, meter.top_number, meter.bottom_number, TimeSignature.clocks_per_click(meter).to_i)
    end

    # A pickup a whole number of the meter's counts long is a bar of its own.
    def pickup_meter(span, meter)
      counts = span.length * meter.bottom_number
      return meter unless counts.denominator == 1 && counts.positive?

      HeadMusic::Rudiment::Meter.get("#{counts.to_i}/#{meter.bottom_number}")
    end

    def tempo(span)
      Tempo.new(span.start, Tempo.microseconds_per_quarter(flow.tempo_at(span.bar_number)))
    end

    # A MIDI key signature holds -7..7 fifths, major or minor, so a key beyond
    # is written as its enharmonic, and a mode as major.
    def key_signature(span)
      event = flow.timeline.key_signature_event_at(span.bar_number)
      fifths = event.signature
      fifths -= 12 while fifths > 7
      fifths += 12 while fifths < -7
      KeySignature.new(span.start, fifths, minor?(event.tonal_context))
    end

    def minor?(context)
      context.respond_to?(:qualifier) && MINOR_QUALIFIERS.include?(context.qualifier)
    end
  end
end
