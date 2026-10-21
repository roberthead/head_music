class HeadMusic::Content::Flow
  # The three things that change over a flow's course: meter, tempo, and key
  # signature, and the tempo ramps, "a tempo" points, and fermatas that may
  # fall in the middle of a bar.
  #
  # They get an owner rather than hanging off the flow directly, because a flow
  # already absorbs bars, parts, voices, and three renderings, and three more
  # maps on top of that is more than one class should hold.
  #
  # **Keyed by bar number, not position.** Meter and key changes are bar-aligned
  # by definition -- a time signature applies from a downbeat -- and keying by
  # position would create a construction cycle, since building a position rolls
  # over its counts, which needs the meter, which would need a position. Bar
  # numbers have no such dependency.
  #
  # **The opening value is the map's default, not its first event.** That is
  # what keeps "this flow is in 3/4" distinct from "the meter changes to 3/4 at
  # bar 1" -- a distinction the writers depend on, since a change is what makes
  # them print a signature mid-piece.
  class Timeline
    DOWNBEAT = HeadMusic::Time::MusicalPosition::FIRST_COUNT

    # @return [HeadMusic::Rudiment::Meter] the meter the flow opens in
    attr_reader :opening_meter

    # @return [HeadMusic::Rudiment::Tempo] the tempo the flow opens in
    attr_reader :opening_tempo

    # @return [HeadMusic::Time::KeySignatureEvent] the signature the flow opens in
    attr_reader :opening_key_signature_event

    def initialize(meter: nil, key_signature: nil, tempo: nil)
      @opening_meter = HeadMusic::Rudiment::Meter.get(meter || HeadMusic::Rudiment::Meter.default)
      @opening_tempo = tempo ? self.class.tempo_for(tempo) : HeadMusic::Rudiment::Tempo.new("quarter", 120)
      @opening_key_signature_event = self.class.event_for(
        HeadMusic::Rudiment::KeySignature.get(key_signature || HeadMusic::Rudiment::KeySignature.default),
        downbeat_of(HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR)
      )

      @meter_map = HeadMusic::Time::EventMap.new(default: @opening_meter)
      @tempo_map = HeadMusic::Time::EventMap.new(default: @opening_tempo)
      @key_signature_map = HeadMusic::Time::EventMap.new(default: @opening_key_signature_event)

      @tempo_ramps = TimelineSpans.new("tempo ramp")
      @a_tempos = TimelineSpans.new("a tempo")
      @fermatas = TimelineSpans.new("fermata")
    end

    def meter_at(bar_number)
      @meter_map.at(downbeat_of(bar_number))
    end

    # The tempo as written, never interpolated, so that a reader's check for a
    # restated tempo sees only what was written: in a bar that begins inside a
    # ramp, the tempo at the ramp's start; at or after its end, its target; at
    # or after an "a tempo", the tempo it restores.
    def tempo_at(bar_number)
      authored_tempo_map.at(downbeat_of(bar_number))
    end

    def key_signature_event_at(bar_number)
      @key_signature_map.at(downbeat_of(bar_number))
    end

    def key_signature_at(bar_number)
      key_signature_event_at(bar_number).key_signature
    end

    def signature_at(bar_number)
      key_signature_event_at(bar_number).signature
    end

    def tonal_context_at(bar_number)
      key_signature_event_at(bar_number).tonal_context
    end

    # Positions are fixed when an item is added, so a meter that would leave
    # one on a count or tick its bar no longer has is refused.
    def change_meter(bar_number, meter)
      ensure_value!(meter, "meter", :remove_meter_change)
      position = downbeat_of(bar_number)
      previous = @meter_map.change_at(position)&.value
      @meter_map.add(position, HeadMusic::Rudiment::Meter.get(meter)).value.tap do
        restore_meter_change(position, previous) { ensure_items_fit_meters! }
      end
    end

    # Meter and key signature changes are bar-aligned by definition: a time
    # signature applies from a downbeat, and a signature printed mid-bar is not
    # a thing notation expresses. The timeline takes a bar number rather than a
    # position so that the off-downbeat case cannot be written down, and
    # refuses anything that is not one rather than rounding it into a bar.
    def self.ensure_downbeat!(bar_number)
      return bar_number if bar_number.is_a?(Integer)

      raise ArgumentError,
        "a change falls on the downbeat of a bar, so it takes a bar number, got #{bar_number.inspect}"
    end

    def change_tempo(bar_number, tempo)
      ensure_value!(tempo, "tempo", :remove_tempo_change)
      position = downbeat_of(bar_number)
      ensure_outside_ramps!(position, "a tempo change at bar #{bar_number}")
      tempos_changed
      @tempo_map.add(position, self.class.tempo_for(tempo)).value
    end

    # @return [Array<HeadMusic::Time::TempoRamp>] the ramps, earliest first,
    #   each with the target it was given, or nil
    def tempo_ramps
      @tempo_ramps.to_a
    end

    # @return [Array<HeadMusic::Time::ATempo>] the "a tempo" points, earliest first
    def a_tempos
      @a_tempos.to_a
    end

    # @return [Array<HeadMusic::Time::Fermata>] the fermatas, earliest first
    def fermatas
      @fermatas.to_a
    end

    # A ramp may begin or end on a tempo change, but no tempo change or
    # "a tempo" may fall strictly inside it.
    def add_tempo_ramp(from:, to:, to_tempo: nil, text: nil)
      ramp = HeadMusic::Time::TempoRamp.new(from: from, to: to, to_tempo: to_tempo && self.class.tempo_for(to_tempo), text: text)
      inside = [*@tempo_map.events.map(&:position), *@a_tempos.map(&:position)].find { |position| strictly_inside?(ramp, position) }
      raise ArgumentError, "the tempo ramp from #{from} to #{to} would hold the tempo set at #{inside}" if inside

      tempos_changed
      @tempo_ramps.add(ramp)
    end

    def add_a_tempo(position, text: "a tempo")
      ensure_outside_ramps!(position, "an a tempo at #{position}")
      a_tempo = HeadMusic::Time::ATempo.new(position: position, text: text)
      tempos_changed
      @a_tempos.add(a_tempo)
    end

    def add_fermata(from:, to:, stretch: HeadMusic::Time::Fermata::DEFAULT_STRETCH)
      @fermatas.add(HeadMusic::Time::Fermata.new(from: from, to: to, stretch: stretch))
    end

    def remove_tempo_ramp(from)
      tempos_changed
      @tempo_ramps.remove(from)
    end

    def remove_a_tempo(position)
      tempos_changed
      @a_tempos.remove(position)
    end

    def remove_fermata(from)
      @fermatas.remove(from)
    end

    # A Conductor for the timeline, with clock zero at the downbeat of a bar.
    # Ramp targets and "a tempo" points become tempo events, and the step
    # changes are added last, so they win where they share a position; the
    # Conductor itself knows only ramps and fermatas.
    def conductor(starting_bar_number = HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR)
      start = downbeat_of(starting_bar_number)
      HeadMusic::Time::Conductor.new(
        starting_musical_position: start,
        meter_map: conductor_meter_map(start),
        tempo_map: conductor_tempo_map(start),
        tempo_ramps: tempo_resolution.last,
        fermatas: fermatas.map { |fermata| fermata.with(from: musical(fermata.from), to: musical(fermata.to)) }
      )
    end

    # Meter.get and KeySignature.get accept one of their own instances;
    # Tempo.get does not, and handed a Tempo would stringify it and answer the
    # default, so the check lives here.
    def self.tempo_for(tempo)
      return tempo if tempo.is_a?(HeadMusic::Rudiment::Tempo)

      HeadMusic::Rudiment::Tempo.get(tempo)
    end

    # @param signature [Integer, HeadMusic::Rudiment::KeySignature, String] fifths,
    #   or something namable as a key signature, from which fifths and an
    #   interpretation are both taken
    def change_key_signature(bar_number, signature, tonal_context: nil)
      ensure_value!(signature, "key signature", :remove_key_signature_change)
      position = downbeat_of(bar_number)
      event =
        if signature.is_a?(Integer)
          ensure_readable!(signature, tonal_context, bar_number)
          HeadMusic::Time::KeySignatureEvent.new(position, signature, tonal_context: tonal_context)
        else
          self.class.event_for(HeadMusic::Rudiment::KeySignature.get(signature), position, tonal_context: tonal_context)
        end
      @key_signature_map.add(position, event).value
    end

    # The change authored in a bar, as distinct from the value in force there.
    # Nil in a bar the author declared nothing in, including the opening bar of
    # a flow that simply has a meter.
    def meter_change_at(bar_number)
      @meter_map.change_at(downbeat_of(bar_number))&.value
    end

    def key_signature_change_at(bar_number)
      @key_signature_map.change_at(downbeat_of(bar_number))&.value
    end

    def tempo_change_at(bar_number)
      @tempo_map.change_at(downbeat_of(bar_number))&.value
    end

    # Un-author a change. The value in force reverts to whatever the previous
    # change, or the opening value, says. Answers the removed value, or nil
    # where nothing was authored in that bar.
    def remove_meter_change(bar_number)
      position = downbeat_of(bar_number)
      @meter_map.remove(position)&.value&.tap do |removed|
        restore_meter_change(position, removed) { ensure_items_fit_meters! }
      end
    end

    def remove_key_signature_change(bar_number)
      @key_signature_map.remove(downbeat_of(bar_number))&.value
    end

    def remove_tempo_change(bar_number)
      tempos_changed
      @tempo_map.remove(downbeat_of(bar_number))&.value
    end

    # The authored changes, by bar number. The {bar_number => value} shape is
    # what the writers already consume, so repointing them off the bars costs
    # nothing at the call site.
    def meter_changes
      changes_by_bar(@meter_map)
    end

    def key_signature_changes
      changes_by_bar(@key_signature_map)
    end

    def tempo_changes
      changes_by_bar(@tempo_map)
    end

    # Every bar in which something was authored. Empty for a flow that merely
    # opens in a meter and a key.
    def changed_bar_numbers
      (@meter_map.events + @tempo_map.events + @key_signature_map.events)
        .map { |event| event.position.bar }.uniq.sort
    end

    # Both fields of a key signature event, always: the signature is what is
    # printed at the clef, and the tonal context is the interpretation, and
    # neither derives the other.
    def to_h
      {
        "meter" => opening_meter.to_s,
        **meter_symbol_to_h("meter_symbol", opening_meter),
        "key_signature" => opening_key_signature_event.key_signature.name,
        "tempo" => tempo_to_h(opening_tempo),
        "meter_changes" => meter_changes.map { |bar_number, value|
          {"number" => bar_number, "meter" => value.to_s, **meter_symbol_to_h("symbol", value)}
        },
        "key_signature_changes" => key_signature_changes.map { |bar_number, event|
          {"number" => bar_number, "signature" => event.signature, "tonal_context" => event.tonal_context&.name}
        },
        "tempo_changes" => tempo_changes.map { |bar_number, value| {"number" => bar_number, "tempo" => tempo_to_h(value)} },
        "tempo_ramps" => tempo_ramps.map { |ramp| tempo_ramp_to_h(ramp) },
        "a_tempos" => a_tempos.map { |a_tempo| {"position" => a_tempo.position.code, "text" => a_tempo.text} },
        "fermatas" => fermatas.map { |fermata| fermata_to_h(fermata) }
      }
    end

    # A KeySignature already carries a tonic and a scale type -- there is no
    # signature-only diatonic context in the gem -- so the interpretation it was
    # built from is recovered rather than discarded.
    def self.event_for(key_signature, position, tonal_context: nil)
      HeadMusic::Time::KeySignatureEvent.new(
        position,
        fifths_of(key_signature),
        tonal_context: tonal_context || tonal_context_of(key_signature)
      )
    end

    # Sharps positive, flats negative. Theoretical keys count each double
    # accidental twice, which is what MusicXML's <fifths> means too.
    def self.fifths_of(key_signature)
      key_signature.num_sharps - key_signature.num_flats
    end

    # Narrowed to a Key or a Mode where the scale type is one, and left as the
    # key signature where it is not.
    #
    # The gem admits key signatures the two subclasses cannot hold -- a
    # harmonic minor, a whole tone -- and those are constructible flows even
    # though MusicXML cannot render them as a <key> element. Forcing every
    # signature through Key or Mode would move that limit from render time to
    # construction time and make such a flow unbuildable.
    def self.tonal_context_of(key_signature)
      scale_type = key_signature.scale_type.name.to_sym
      name = "#{key_signature.tonic_spelling} #{scale_type}"
      if HeadMusic::Rudiment::Key::QUALITIES.include?(scale_type)
        HeadMusic::Rudiment::Key.get(name)
      elsif HeadMusic::Rudiment::Mode::MODES.include?(scale_type)
        HeadMusic::Rudiment::Mode.get(name)
      else
        key_signature
      end
    end

    private

    # 20.x cleared a change by passing nil. That now has its own verb, and nil
    # is refused here rather than reaching a rudiment getter that would raise
    # something unrelated.
    def ensure_value!(value, noun, remover)
      return unless value.nil?

      raise ArgumentError, "a #{noun} change takes a #{noun}, got nil; to clear an authored change, use ##{remover}"
    end

    # A signature past the conventional table -- eight sharps is G sharp major
    # -- has no reading of its own, so every consumer that needs a tonic would
    # raise later, far from here. Requiring the interpretation up front puts
    # the error where the signature was authored.
    def ensure_readable!(signature, tonal_context, bar_number)
      return if tonal_context || HeadMusic::Rudiment::Key::MAJOR_KEY_NAMES_BY_FIFTHS.key?(signature)

      raise ArgumentError,
        "a signature of #{signature} fifths at bar #{bar_number} has no conventional key; give it a tonal_context"
    end

    # Two fields rather than a "quarter = 72" string, so that a fractional
    # tempo survives: Tempo.get reads the number by stripping non-digits.
    def tempo_to_h(tempo)
      {"beat_value" => tempo.beat_value.to_s, "beats_per_minute" => tempo.beats_per_minute}.tap do |hash|
        hash["text"] = tempo.text if tempo.text
        hash["metronome_mark"] = false unless tempo.metronome_mark?
      end
    end

    def tempo_ramp_to_h(ramp)
      hash = {"from" => ramp.from.code, "to" => ramp.to.code}
      hash["tempo"] = tempo_to_h(ramp.to_tempo) if ramp.to_tempo
      hash["text"] = ramp.text if ramp.text
      hash
    end

    def fermata_to_h(fermata)
      stretch = fermata.stretch
      {"from" => fermata.from.code, "to" => fermata.to.code, "stretch" => (stretch == stretch.to_i) ? stretch.to_i : stretch.to_f}
    end

    def meter_symbol_to_h(key, meter)
      meter.symbol ? {key => meter.symbol.to_s} : {}
    end

    def changes_by_bar(map)
      map.events.to_h { |event| [event.position.bar, event.value] }
    end

    def musical(position)
      HeadMusic::Time::MusicalPosition.new(*position.to_a)
    end

    def strictly_inside?(ramp, position)
      tuple = position.to_a
      (ramp.from.to_a <=> tuple).negative? && (tuple <=> ramp.to.to_a).negative?
    end

    def ensure_outside_ramps!(position, description)
      ramp = @tempo_ramps.covering(position)
      return if ramp.nil? || ramp.from.to_a == position.to_a

      raise ArgumentError, "#{description} falls inside the tempo ramp from #{ramp.from} to #{ramp.to}"
    end

    def restore_meter_change(position, previous)
      yield
    rescue ArgumentError
      previous ? @meter_map.add(position, previous) : @meter_map.remove(position)
      raise
    end

    def ensure_items_fit_meters!
      [@tempo_ramps, @a_tempos, @fermatas].each do |items|
        items.each do |item|
          misfit = [item.from, item.to].find { |position| !fits_meter?(position) }
          raise ArgumentError, "the meter would leave no #{misfit} for the #{items.describe(item)}" if misfit
        end
      end
    end

    def fits_meter?(position)
      bar, count, tick, _subtick = position.to_a
      meter = meter_at(bar)
      count.between?(1, meter.counts_per_bar) && tick < meter.ticks_per_count
    end

    def tempos_changed
      @authored_tempo_map = @tempo_resolution = nil
    end

    # A flow with no ramps and no "a tempo" answers from its step changes, as
    # it always has.
    def authored_tempo_map
      return @tempo_map if @tempo_ramps.empty? && @a_tempos.empty?

      @authored_tempo_map ||= HeadMusic::Time::EventMap.new(default: opening_tempo).tap do |map|
        tempo_resolution.first.each { |position, tempo| map.add(position, tempo) }
        @tempo_map.events.each { |event| map.add(event.position, event.value) }
      end
    end

    # [[position, tempo] at each ramp end and "a tempo"], and the ramps with
    # musical positions and their targets resolved: a target as given, else
    # the tempo change where the ramp ends, else the default its text implies.
    # At one position, a ramp ends, then an "a tempo" restores, then a tempo
    # changes, then a ramp starts.
    def tempo_resolution
      @tempo_resolution ||= begin
        points = []
        resolved = {}
        current = opening_tempo
        restorable = nil
        tempo_moments.each do |order, item|
          case order
          when 0
            current = resolved[item.from.to_a].to_tempo
            points << [musical(item.to), current]
          when 1
            next unless restorable

            current = restorable
            points << [musical(item.position), current]
          when 2
            current = item
          else
            restorable = current
            resolved[item.from.to_a] = resolved_ramp(item, current)
          end
        end
        [points, resolved.values]
      end
    end

    def tempo_moments
      moments = @tempo_ramps.flat_map { |ramp| [[ramp.from.to_a, 3, ramp], [ramp.to.to_a, 0, ramp]] } +
        @a_tempos.map { |a_tempo| [a_tempo.position.to_a, 1, a_tempo] } +
        @tempo_map.events.map { |event| [event.tuple, 2, event.value] }
      moments.sort_by { |tuple, order, _item| [tuple, order] }.map { |_tuple, order, item| [order, item] }
    end

    def resolved_ramp(ramp, start_tempo)
      target = ramp.to_tempo || @tempo_map.change_at(musical(ramp.to))&.value || ramp.default_target(start_tempo)
      ramp.with(from: musical(ramp.from), to: musical(ramp.to), to_tempo: target)
    end

    def conductor_meter_map(start)
      HeadMusic::Time::MeterMap.new(starting_meter: @meter_map.at(start), starting_position: start).tap do |map|
        @meter_map.events.each { |event| map.add_change(event.position, event.value) if event.after?(start.to_a) }
      end
    end

    def conductor_tempo_map(start)
      HeadMusic::Time::TempoMap.new(starting_tempo: authored_tempo_map.at(start), starting_position: start).tap do |map|
        authored_tempo_map.events.each { |event| map.add_change(event.position, event.value) if event.after?(start.to_a) }
      end
    end

    def downbeat_of(bar_number)
      HeadMusic::Time::MusicalPosition.new(self.class.ensure_downbeat!(bar_number), DOWNBEAT, 0, 0)
    end
  end
end
