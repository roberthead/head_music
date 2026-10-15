module HeadMusic::MIDI
  # Everything that would stop a flow from becoming a file, raised before any
  # bytes are written.
  class Preflight
    MAX_MICROSECONDS_PER_QUARTER = 0xFFFFFF
    DEFAULT_FIRST_BAR = HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR

    attr_reader :flow, :transposed

    def initialize(flow, transposed: false)
      @flow = flow
      @transposed = transposed
    end

    def check
      raise RenderError, "#{flow.name} has no voice events to render" if flow.voices.all? { |voice| voice.voice_events.empty? }

      check_meters
      check_tempos
      check_keys
      check_texts
      channels
      played_bars
      self
    end

    # Navigation reports a malformed order as an ArgumentError.
    def played_bars
      @played_bars ||= begin
        flow.performance_order
      rescue ArgumentError => error
        raise RenderError, error.message
      end
    end

    # Raises when the flow needs more pitched channels than MIDI has.
    def channels
      @channels ||= ChannelAllocator.new(flow)
    end

    def check_ticks(ticks, division)
      return if ticks <= SMF::MAX_VLQ

      raise RenderError, "the performance lasts #{ticks} ticks at #{division} to the quarter, " \
        "more than a MIDI file can count (#{SMF::MAX_VLQ})"
    end

    private

    # Every value the flow holds, not only those played, since the model
    # cannot place a position in a bar of a meter MIDI cannot hold.
    def in_force(opening, changes)
      {DEFAULT_FIRST_BAR => opening}.merge(changes)
    end

    def check_meters
      in_force(flow.timeline.opening_meter, flow.meter_changes).each do |number, meter|
        next if time_signature?(meter)

        raise RenderError, "a MIDI time signature cannot hold #{meter} in bar #{number}"
      end
    end

    def time_signature?(meter)
      return false unless meter.bottom_number.to_s(2).count("1") == 1 && meter.top_number.between?(1, 255)

      clocks = TimeSignature.clocks_per_click(meter)
      clocks.denominator == 1 && clocks.between?(1, 255)
    end

    def check_tempos
      in_force(flow.timeline.opening_tempo, flow.tempo_changes).each do |number, tempo|
        raise RenderError, "a tempo of 0 bpm in bar #{number} never reaches the next beat" unless tempo.beats_per_minute.positive?

        microseconds = Tempo.microseconds_per_quarter(tempo)
        next if microseconds.between?(1, MAX_MICROSECONDS_PER_QUARTER)

        raise RenderError, "a MIDI tempo cannot hold #{tempo.beat_value} = #{tempo.beats_per_minute} in bar #{number}"
      end
    end

    def check_keys
      flow.parts.each do |part|
        part.voices.flat_map(&:note_events).each do |voice_event|
          sounding_pitches(voice_event).each { |pitch| check_key(pitch, part, voice_event) }
        end
      end
    end

    def sounding_pitches(voice_event)
      voice_event.pitches + voice_event.grace_notes.flat_map(&:pitches)
    end

    def check_texts
      check_text(flow.name, "the flow name")
      flow.parts.each { |part| check_text(PartTrack.track_name(part), "a track name") }
      flow.voices.flat_map(&:note_events).each do |voice_event|
        voice_event.syllables.each_value { |syllable| check_text(syllable.text, "a lyric at #{voice_event.position}") }
      end
    end

    def check_text(text, source)
      return if text.nil? || utf8?(text.to_s)

      raise RenderError, "cannot write #{text.inspect}, #{source}, as UTF-8 text"
    end

    def utf8?(text)
      text.encode("UTF-8").valid_encoding?
    rescue EncodingError
      false
    end

    def check_key(pitch, part, voice_event)
      key = SoundKeys.key_for(pitch, part, voice_event.position.bar_number, transposed: transposed)
      return if key.between?(0, 127)

      raise RenderError, "#{pitch} at #{voice_event.position} sounds at MIDI key #{key}, outside 0..127"
    end
  end
end
