class HeadMusic::Content::Flow
  # The three things that change over a flow's course: meter, tempo, and key
  # signature.
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
    end

    def meter_at(bar_number)
      @meter_map.at(downbeat_of(bar_number))
    end

    def tempo_at(bar_number)
      @tempo_map.at(downbeat_of(bar_number))
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
      @meter_map.add(downbeat_of(bar_number), HeadMusic::Rudiment::Meter.get(meter)).value
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
      @tempo_map.add(downbeat_of(bar_number), self.class.tempo_for(tempo)).value
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
      position = downbeat_of(bar_number)
      event =
        if signature.is_a?(Integer)
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

    def changes_by_bar(map)
      map.events.to_h { |event| [event.position.bar, event.value] }
    end

    def downbeat_of(bar_number)
      HeadMusic::Time::MusicalPosition.new(self.class.ensure_downbeat!(bar_number), DOWNBEAT, 0, 0)
    end
  end
end
