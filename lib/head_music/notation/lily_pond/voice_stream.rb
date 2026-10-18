# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # The ordered events of one voice as read from the document, before any
  # flow exists: notes, rests, whole-bar rests, spacers, bar checks, \after
  # marks, and key or meter commands. Ties fold here, so a tied pair reaches the builder
  # as one note whose rhythmic value carries the author's split.
  class VoiceStream
    # A bar check, \key, \time, or \change Staff between the halves of a
    # tied note records how much of the note precedes it, so the builder can
    # apply it once the note has a position.
    InnerEvent = Data.define(:elapsed, :event)

    Event = Data.define(
      :kind, :line, :pitches, :rhythmic_value, :fraction, :key_signature, :meter, :staff_name, :inner_events, :marks,
      :bar_mark, :tuplet, :graces
    ) do
      def initialize(
        kind:, line:, pitches: nil, rhythmic_value: nil, fraction: nil, key_signature: nil, meter: nil,
        staff_name: nil, inner_events: [], marks: MarkReader::NONE, bar_mark: nil, tuplet: nil, graces: []
      )
        super
      end

      def music?
        %i[note rest whole_bar_rest].include?(kind)
      end

      def timed?
        music? || kind == :spacer
      end

      def tied_to(link_value, link_marks)
        with(rhythmic_value: rhythmic_value.append_tied(link_value), marks: marks.merge(link_marks))
      end

      def holding(event)
        with(inner_events: inner_events + [InnerEvent.new(elapsed: rhythmic_value, event: event)])
      end
    end

    UNFOLLOWED_TIE = "A tie must be followed by a note"

    attr_reader :role, :events, :opening_clef
    attr_accessor :group_staff, :dynamics_target, :tuplet_span

    def initialize(role = nil)
      @role = role
      @events = []
      @pending_note = nil
      @pending_graces = GraceReader::NONE
      @tie_open = false
    end

    def music?
      finish
      events.any?(&:music?)
    end

    def add_note(pitches, rhythmic_value, line, marks = MarkReader::NONE)
      rhythmic_value = under_tuplet(rhythmic_value)
      graces = @pending_graces
      @pending_graces = GraceReader::NONE
      return extend_tie(pitches, rhythmic_value, line, marks) if @tie_open

      flush_pending_note
      @pending_note = Event.new(
        kind: :note, line: line, pitches: pitches, rhythmic_value: rhythmic_value,
        marks: graces.main_marks(marks), graces: graces.before(pitches)
      )
    end

    # Grace notes wait for the note they come before, and are dropped before
    # a rest, a spacer, the later link of a tied note, or the end of the voice,
    # since the model holds them only on a note they lead to.
    def add_graces(graces)
      return if graces.graces.empty?

      @pending_graces += graces
    end

    def add_rest(rhythmic_value, line, marks = MarkReader::NONE)
      silent(line, kind: :rest, rhythmic_value: under_tuplet(rhythmic_value), marks: marks)
    end

    def add_whole_bar_rest(fraction, line, marks = MarkReader::NONE)
      silent(line, kind: :whole_bar_rest, fraction: fraction, marks: marks)
    end

    # A spacer inside a tuplet is written time, so it sounds scaled, and the
    # rest that may come to stand for it carries the ratio.
    def add_spacer(fraction, line, marks = MarkReader::NONE)
      silent(line, kind: :spacer, fraction: sounding(fraction), marks: marks, tuplet: @tuplet)
    end

    # The dynamics a <> carries, held like a bar check inside a tied note.
    def add_marker(line, marks)
      mark(line, kind: :dynamics, marks: marks)
    end

    # A mark \after places part way into the music that follows it, held
    # like a bar check where it falls between the halves of a tied note.
    def add_after(fraction, line, marks)
      mark(line, kind: :after, fraction: sounding(fraction), marks: marks)
    end

    def tuplet?
      !@tuplet.nil?
    end

    # The notes and rests until the tuplet closes carry its ratio. A span is
    # the sounding time after which LilyPond starts a new bracket.
    def open_tuplet(ratio, span, line)
      mark(line, kind: :tuplet_start, tuplet: ratio, fraction: span)
      @tuplet = ratio
    end

    def close_tuplet(line)
      @tuplet = nil
      mark(line, kind: :tuplet_end)
    end

    def open_tie(line)
      raise error("A tie must follow a note", line) if @pending_note.nil? || @tie_open

      @tie_open = true
      @tie_line = line
    end

    def bar_check(line)
      mark(line, kind: :bar_check)
    end

    def change_key_signature(key_signature, line)
      mark(line, kind: :key, key_signature: key_signature)
    end

    def change_meter(meter, line)
      mark(line, kind: :time, meter: meter)
    end

    def change_staff(staff_name, line)
      mark(line, kind: :staff_change, staff_name: staff_name)
    end

    def bar_mark(bar_mark, line)
      mark(line, kind: :bar_mark, bar_mark: bar_mark)
    end

    # LilyPond's rehearsal mark counter: a numbered \mark sets it, and
    # \mark \default takes the next number.
    def rehearsal_number(number = nil)
      @rehearsal_number = number || (@rehearsal_number || 0) + 1
    end

    # Only the clef a voice opens with names its staff's clef; a later one is
    # read and ignored, as it always has been.
    def clef(name)
      return if @opening_clef || @pending_note || events.any?(&:music?)

      @opening_clef = name
    end

    # What the writer fills a staff nobody is written on with: rests and
    # nothing else, whole-bar ones except in a short final bar.
    def silent?
      finish
      events.none? { |event| event.kind == :note }
    end

    def finish
      terminate(nil)
      @pending_graces = GraceReader::NONE
      self
    end

    private

    def silent(line, **attributes)
      @pending_graces = GraceReader::NONE
      append(line, **attributes)
    end

    def under_tuplet(rhythmic_value)
      @tuplet ? rhythmic_value.with_tuplet(@tuplet) : rhythmic_value
    end

    def sounding(fraction)
      @tuplet ? fraction * @tuplet.factor : fraction
    end

    def append(line, **attributes)
      terminate(line)
      events << Event.new(line: line, **attributes)
    end

    def mark(line, **attributes)
      return hold_inside_tie(Event.new(line: line, **attributes)) if @tie_open

      append(line, **attributes)
    end

    # Any music that is not a note ends the pending note; an open tie can
    # then never close, so it is rejected.
    def terminate(line)
      raise error(UNFOLLOWED_TIE, line || @tie_line) if @tie_open

      flush_pending_note
    end

    def flush_pending_note
      return unless @pending_note

      events << @pending_note
      @pending_note = nil
    end

    # Closes an open tie: the arriving note's value is appended at the deep
    # end of the pending note's chain, so the pair (and any longer chain)
    # becomes a single note. Its marks join the note's, except a dynamic
    # level and hairpin marks, which are held where the link starts.
    def extend_tie(pitches, rhythmic_value, line, marks)
      raise error("A tie must connect two notes of the same pitch", line) unless @pending_note.pitches.sort == pitches.sort

      @tie_open = false
      hold_link_dynamics(marks, line)
      @pending_note = @pending_note.tied_to(rhythmic_value, marks.with(level: nil, hairpin_marks: []))
    end

    def hold_link_dynamics(marks, line)
      dynamics = marks.dynamics
      hold_inside_tie(Event.new(kind: :dynamics, line: line, marks: dynamics)) unless dynamics == MarkReader::NONE
    end

    def hold_inside_tie(event)
      @pending_note = @pending_note.holding(event)
    end

    def error(message, line)
      ParseError.new(message, line_number: line, snippet: "~")
    end
  end
end
