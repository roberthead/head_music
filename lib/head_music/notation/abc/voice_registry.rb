# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Owns the tune's per-voice interpretation states and tracks which voice the
  # body is currently writing into.
  #
  # A tune may declare its voices in V: header fields, switch between them with
  # V: body lines, or use neither — in which case all the music belongs to one
  # unnamed voice.
  class VoiceRegistry
    include Enumerable

    def initialize(flow, key_signature, duration_resolver)
      @flow = flow
      @key_signature = key_signature
      @duration_resolver = duration_resolver
      @states = {}
    end

    def each(&block)
      @states.each_value(&block)
    end

    # Creates a state for each declared role, or — when nothing is declared and
    # the body never switches voices — the single unnamed voice that tune uses,
    # and makes the first of them current.
    def declare(roles, default:)
      roles.each { |role| state(role) }
      state(nil) if @states.empty? && default
      @current = @states.values.first
    end

    def state(role)
      @states[role] ||= VoiceState.new(
        @flow.add_voice(role: role),
        PitchBuilder.new(@key_signature),
        @duration_resolver
      )
    end

    # Body music before any V: line falls into a default unnamed voice, created
    # here on demand so a leading V: line doesn't force an empty one into the
    # flow.
    def current
      @current ||= state(nil)
    end

    def switch_to(role)
      @current = state(role)
    end
  end
end
