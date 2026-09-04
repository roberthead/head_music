# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # The ordered events of one voice as read from the document, before any
  # composition exists: notes, rests, whole-bar rests, bar checks, and key
  # or meter commands. Ties fold here, so a tied pair reaches the builder
  # as one note whose rhythmic value carries the author's split.
  class VoiceStream
    Event = Data.define(:kind, :line, :pitches, :rhythmic_value, :fraction, :key_signature, :meter) do
      def initialize(kind:, line:, pitches: nil, rhythmic_value: nil, fraction: nil, key_signature: nil, meter: nil)
        super
      end

      def music?
        %i[note rest whole_bar_rest].include?(kind)
      end
    end

    attr_reader :role, :events

    def initialize(role = nil)
      @role = role
      @events = []
      @pending_note = nil
      @tie_open = false
    end

    def music?
      finish
      events.any?(&:music?)
    end

    def add_note(pitches, rhythmic_value, line)
      return extend_tie(pitches, rhythmic_value, line) if @tie_open

      flush_pending_note
      @pending_note = Event.new(kind: :note, line: line, pitches: pitches, rhythmic_value: rhythmic_value)
    end

    def add_rest(rhythmic_value, line)
      terminate("A tie must be followed by a note", line)
      events << Event.new(kind: :rest, line: line, rhythmic_value: rhythmic_value)
    end

    def add_whole_bar_rest(fraction, line)
      terminate("A tie must be followed by a note", line)
      events << Event.new(kind: :whole_bar_rest, line: line, fraction: fraction)
    end

    def open_tie(line)
      raise error("A tie must follow a note", line) if @pending_note.nil? || @tie_open

      @tie_open = true
      @tie_line = line
    end

    def bar_check(line)
      terminate("Ties across bar checks are not yet supported", line)
      events << Event.new(kind: :bar_check, line: line)
    end

    def change_key_signature(key_signature, line)
      terminate("A tie must be followed by a note", line)
      events << Event.new(kind: :key, line: line, key_signature: key_signature)
    end

    def change_meter(meter, line)
      terminate("A tie must be followed by a note", line)
      events << Event.new(kind: :time, line: line, meter: meter)
    end

    def finish
      terminate("A tie must be followed by a note", nil)
      self
    end

    private

    # Anything that is not a note ends the pending note; an open tie can
    # then never close, so it is rejected with the caller's message.
    def terminate(tie_message, line)
      raise error(tie_message, line || @tie_line) if @tie_open

      flush_pending_note
    end

    def flush_pending_note
      return unless @pending_note

      events << @pending_note
      @pending_note = nil
    end

    # Closes an open tie: the arriving note's value is appended at the deep
    # end of the pending note's chain, so the pair (and any longer chain)
    # becomes a single note.
    def extend_tie(pitches, rhythmic_value, line)
      pending = @pending_note
      unless pending.pitches.sort == pitches.sort
        raise error("A tie must connect two notes of the same pitch", line)
      end

      @tie_open = false
      @pending_note = pending.with(rhythmic_value: pending.rhythmic_value.append_tied(rhythmic_value))
    end

    def error(message, line)
      ParseError.new(message, line_number: line, snippet: "~")
    end
  end
end
