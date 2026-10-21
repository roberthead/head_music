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

    # @return [HeadMusic::Time::KeySignatureEvent] the signature the flow opens in
    attr_reader :opening_key_signature_event

    delegate :opening_tempo, :tempo_ramps, :a_tempos, :add_tempo_ramp, :add_a_tempo, :remove_tempo_ramp, :remove_a_tempo,
      to: :@tempos

    def initialize(meter: nil, key_signature: nil, tempo: nil)
      @opening_meter = HeadMusic::Rudiment::Meter.get(meter || HeadMusic::Rudiment::Meter.default)
      @opening_key_signature_event = HeadMusic::Time::KeySignatureEvent.from_key_signature(
        HeadMusic::Rudiment::KeySignature.get(key_signature || HeadMusic::Rudiment::KeySignature.default),
        downbeat_of(HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR)
      )

      @meter_map = HeadMusic::Time::EventMap.new(default: @opening_meter)
      @key_signature_map = HeadMusic::Time::EventMap.new(default: @opening_key_signature_event)
      @tempos = TimelineTempos.new(tempo)
      @fermatas = TimelineSpans.new("fermata")
    end

    def meter_at(bar_number)
      @meter_map.at(downbeat_of(bar_number))
    end

    # The tempo as written, never interpolated; see TimelineTempos#at.
    def tempo_at(bar_number)
      @tempos.at(downbeat_of(bar_number))
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

    def change_meter(bar_number, meter)
      ensure_value!(meter, "meter", :remove_meter_change)
      position = downbeat_of(bar_number)
      revising_meter(position) { @meter_map.add(position, HeadMusic::Rudiment::Meter.get(meter)).value }
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
      @tempos.change(downbeat_of(bar_number), tempo)
    end

    # @return [Array<HeadMusic::Time::Fermata>] the fermatas, earliest first
    def fermatas
      @fermatas.to_a
    end

    def add_fermata(from:, to:, stretch: HeadMusic::Time::Fermata::DEFAULT_STRETCH)
      @fermatas.add(HeadMusic::Time::Fermata.new(from: from, to: to, stretch: stretch))
    end

    def remove_fermata(from)
      @fermatas.remove(from)
    end

    # A Conductor for the timeline, with clock zero at the downbeat of a bar.
    # The Conductor itself knows only ramps and fermatas.
    def conductor(starting_bar_number = HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR)
      start = downbeat_of(starting_bar_number)
      HeadMusic::Time::Conductor.new(
        starting_musical_position: start,
        meter_map: rebased(@meter_map, start) { |meter| HeadMusic::Time::MeterMap.new(starting_meter: meter, starting_position: start) },
        tempo_map: rebased(@tempos.authored_map, start) { |tempo| HeadMusic::Time::TempoMap.new(starting_tempo: tempo, starting_position: start) },
        tempo_ramps: @tempos.resolved_ramps,
        fermatas: fermatas.map { |fermata| fermata.with(from: musical(fermata.from), to: musical(fermata.to)) }
      )
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
          HeadMusic::Time::KeySignatureEvent.from_key_signature(HeadMusic::Rudiment::KeySignature.get(signature), position, tonal_context: tonal_context)
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
      @tempos.change_at(downbeat_of(bar_number))
    end

    # Un-author a change. The value in force reverts to whatever the previous
    # change, or the opening value, says. Answers the removed value, or nil
    # where nothing was authored in that bar.
    def remove_meter_change(bar_number)
      position = downbeat_of(bar_number)
      revising_meter(position) { @meter_map.remove(position)&.value }
    end

    def remove_key_signature_change(bar_number)
      @key_signature_map.remove(downbeat_of(bar_number))&.value
    end

    def remove_tempo_change(bar_number)
      @tempos.remove_change(downbeat_of(bar_number))
    end

    # The authored changes, by bar number. The {bar_number => value} shape is
    # what the writers already consume, so repointing them off the bars costs
    # nothing at the call site.
    def meter_changes
      changes_by_bar(@meter_map.events)
    end

    def key_signature_changes
      changes_by_bar(@key_signature_map.events)
    end

    def tempo_changes
      changes_by_bar(@tempos.change_events)
    end

    # Every bar in which something was authored. Empty for a flow that merely
    # opens in a meter and a key.
    def changed_bar_numbers
      [meter_changes, tempo_changes, key_signature_changes].flat_map(&:keys).uniq.sort
    end

    def to_h
      TimelineSerializer.new(self).to_h
    end

    def self.fifths_of(key_signature)
      HeadMusic::Time::KeySignatureEvent.fifths_of(key_signature)
    end

    def self.tonal_context_of(key_signature)
      HeadMusic::Time::KeySignatureEvent.tonal_context_of(key_signature)
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

    def changes_by_bar(events)
      events.to_h { |event| [event.position.bar, event.value] }
    end

    def musical(position)
      HeadMusic::Time::MusicalPosition.new(*position.to_a)
    end

    # Positions are fixed when an item is added, so a meter change that would
    # leave one on a count or tick its bar no longer has is undone and refused.
    def revising_meter(position)
      previous = @meter_map.change_at(position)&.value
      yield.tap { ensure_items_fit_meters! }
    rescue ArgumentError
      previous ? @meter_map.add(position, previous) : @meter_map.remove(position)
      raise
    end

    def ensure_items_fit_meters!
      [*@tempos.spans, @fermatas].each do |items|
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

    # A change map for the Conductor, opening at its start with the value in
    # force there.
    def rebased(source, start)
      yield(source.at(start)).tap do |map|
        source.events.each { |event| map.add_change(event.position, event.value) if event.after?(start.to_a) }
      end
    end

    def downbeat_of(bar_number)
      HeadMusic::Time::MusicalPosition.new(self.class.ensure_downbeat!(bar_number), DOWNBEAT, 0, 0)
    end
  end
end
