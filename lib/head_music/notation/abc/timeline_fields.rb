# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Reads the meter and key fields of the tune body onto the flow's timeline.
  # A field in any one voice changes the flow at its bar, so a tune may state
  # a change in its first voice alone. The first field of each kind read for
  # a bar wins, and one stated partway through a bar takes effect at the next
  # downbeat, though a voice spells in a key it states at once.
  class TimelineFields
    def initialize(flow)
      @flow = flow
      @meter_bars = []
      @key_bars = []
    end

    # A state of nil stands for a field before any voice has begun.
    def meter(state, token)
      bar = bar_number(state)
      return if @meter_bars.include?(bar)

      @meter_bars << bar
      meter = Header.meter(token.lexeme, token.line)
      @flow.change_meter(bar, meter) unless HeadMusic::Notation::TimelineReading.same_meter?(@flow.meter_at(bar), meter)
    end

    # A field holding only terms such as clef=bass changes no key.
    def key(state, token)
      mapper = KeyMapper.new(token.lexeme, line_number: token.line)
      return unless mapper.key?

      key_signature = mapper.key_signature
      state&.state_key(key_signature)
      bar = bar_number(state)
      return if @key_bars.include?(bar)

      @key_bars << bar
      return if HeadMusic::Notation::TimelineReading.same_key?(@flow.timeline.key_signature_event_at(bar), key_signature)

      @flow.change_key_signature(bar, key_signature)
    end

    private

    def bar_number(state)
      return HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR unless state

      position = state.cursor
      downbeat?(position) ? position.bar_number : position.bar_number + 1
    end

    def downbeat?(position)
      position.count == 1 && position.tick.zero? && position.subtick.zero?
    end
  end
end
