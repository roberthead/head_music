class HeadMusic::Content::Flow
  # The tempo corner of a Timeline: its step changes, the ramps and "a tempo"
  # points between them, and the tempos those resolve to. Split from the meter
  # and key signature maps because a ramp's target and an "a tempo"'s
  # restored tempo both depend on the step changes around them, and that
  # resolution outgrew the class that also holds the other two maps.
  class TimelineTempos
    # @return [HeadMusic::Rudiment::Tempo] the tempo the flow opens in
    attr_reader :opening_tempo

    def initialize(opening_tempo = nil)
      @opening_tempo = opening_tempo ? self.class.tempo_for(opening_tempo) : HeadMusic::Rudiment::Tempo.new("quarter", 120)
      @changes = HeadMusic::Time::EventMap.new(default: @opening_tempo)
      @ramps = TimelineSpans.new("tempo ramp")
      @a_tempos = TimelineSpans.new("a tempo")
    end

    # The tempo as written, never interpolated, so that a reader's check for a
    # restated tempo sees only what was written: at a position inside a ramp,
    # the tempo at the ramp's start; at or after its end, its target; at or
    # after an "a tempo", the tempo it restores. A flow with no ramps and no
    # "a tempo" answers from its step changes alone.
    def at(position)
      authored_map.at(position)
    end

    def change(position, tempo)
      ensure_outside_ramps!(position, "a tempo change at bar #{position.bar}")
      changed { @changes.add(position, self.class.tempo_for(tempo)).value }
    end

    # Meter.get and KeySignature.get accept one of their own instances;
    # Tempo.get does not, and handed a Tempo would stringify it and answer the
    # default, so the check lives here.
    def self.tempo_for(tempo)
      return tempo if tempo.is_a?(HeadMusic::Rudiment::Tempo)

      HeadMusic::Rudiment::Tempo.get(tempo)
    end

    def change_at(position)
      @changes.change_at(position)&.value
    end

    def remove_change(position)
      changed { @changes.remove(position)&.value }
    end

    # @return [Array<HeadMusic::Time::EventMap::Event>] the step changes, earliest first
    def change_events
      @changes.events
    end

    # @return [Array<HeadMusic::Time::TempoRamp>] the ramps, earliest first,
    #   each with the target it was given, or nil
    def tempo_ramps
      @ramps.to_a
    end

    # @return [Array<HeadMusic::Time::ATempo>] the "a tempo" points, earliest first
    def a_tempos
      @a_tempos.to_a
    end

    # @return [Array<TimelineSpans>] the collections whose items take positions
    def spans
      [@ramps, @a_tempos]
    end

    # A ramp may begin or end on a tempo change, but no tempo change or
    # "a tempo" may fall strictly inside it.
    def add_tempo_ramp(from:, to:, to_tempo: nil, text: nil)
      ramp = HeadMusic::Time::TempoRamp.new(from: from, to: to, to_tempo: to_tempo && self.class.tempo_for(to_tempo), text: text)
      inside = [*@changes.events.map(&:position), *@a_tempos.map(&:position)].find { |position| strictly_inside?(ramp, position) }
      raise ArgumentError, "the tempo ramp from #{ramp.from} to #{ramp.to} would hold the tempo set at #{inside}" if inside

      changed { @ramps.add(ramp) }
    end

    def add_a_tempo(position, text: "a tempo")
      ensure_outside_ramps!(position, "an a tempo at #{position}")
      changed { @a_tempos.add(HeadMusic::Time::ATempo.new(position: position, text: text)) }
    end

    def remove_tempo_ramp(from)
      changed { @ramps.remove(from) }
    end

    def remove_a_tempo(position)
      changed { @a_tempos.remove(position) }
    end

    # The ramps with musical positions and their targets resolved: a target
    # as given, else the tempo change where the ramp ends, else the default
    # its text implies.
    def resolved_ramps
      resolution.last
    end

    # The step changes, with ramp targets and "a tempo" points as tempo
    # events among them; a step change wins where it shares a position with one.
    def authored_map
      return @changes if @ramps.empty? && @a_tempos.empty?

      resolution.first
    end

    private

    def changed
      @resolution = nil
      yield
    end

    # [the authored tempo map, the resolved ramps]. At one position, a ramp
    # ends, then an "a tempo" restores, then a tempo changes, then a ramp
    # starts; an "a tempo" restores the tempo the latest ramp began from.
    def resolution
      @resolution ||= expressions.each_with_object([changes_copy, []]) { |item, (map, resolved)| resolve(item, map, resolved) }
    end

    # A point sorts before a ramp that starts where it is.
    def expressions
      (tempo_ramps + a_tempos).sort_by { |item| [item.from.to_a, item.to.to_a] }
    end

    def changes_copy
      HeadMusic::Time::EventMap.new(default: opening_tempo).tap do |map|
        change_events.each { |event| map.add(event.position, event.value) }
      end
    end

    def resolve(item, map, resolved)
      if item.is_a?(HeadMusic::Time::ATempo)
        add_point(map, item.position, resolved.last && map.at(resolved.last.from))
      else
        ramp = resolved_ramp(item, map.at(musical(item.from)))
        add_point(map, ramp.to, ramp.to_tempo)
        resolved << ramp
      end
    end

    def add_point(map, position, tempo)
      position = musical(position)
      map.add(position, tempo) unless tempo.nil? || change_at(position)
    end

    def resolved_ramp(ramp, start_tempo)
      to = musical(ramp.to)
      ramp.with(from: musical(ramp.from), to: to, to_tempo: ramp.to_tempo || change_at(to) || ramp.default_target(start_tempo))
    end

    def musical(position)
      HeadMusic::Time::MusicalPosition.new(*position.to_a)
    end

    def strictly_inside?(ramp, position)
      tuple = position.to_a
      (ramp.from.to_a <=> tuple).negative? && (tuple <=> ramp.to.to_a).negative?
    end

    def ensure_outside_ramps!(position, description)
      ramp = @ramps.covering(position)
      return if ramp.nil? || ramp.from.to_a == position.to_a

      raise ArgumentError, "#{description} falls inside the tempo ramp from #{ramp.from} to #{ramp.to}"
    end
  end
end
