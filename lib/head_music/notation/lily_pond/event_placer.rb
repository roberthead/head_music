# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Places a voice stream's events on its voice. Every event lands at the
  # voice's position, so bar checks and key or meter commands are verified
  # against where the music actually is, the way LilyPond verifies them at
  # compile time.
  #
  # A spacer moves the voice's position without placing an event. One that
  # music follows becomes a rest, since a voice holds no gaps; one that ends
  # the voice in the bar where its music ends leaves nothing behind but the
  # level it carries. An \after
  # places its level that far past where the music it wraps starts.
  #
  # Slur and phrase marks pair within a voice by kind and name. As in
  # LilyPond, an open while one of the same kind and name is open is
  # ignored, a close with none open is dropped, and so is a span the voice
  # refuses, such as a slur ending on a rest. One opened on a note's first
  # grace note starts from_grace, and may end on that same note.
  #
  # Hairpin marks are gathered wherever a voice's marks are read and paired
  # once the voice is placed, by time rather than written order, since the
  # later links of a tied note are placed before the note's own marks.
  #
  # Tuplets are bracketed once every voice is placed, since a voice refuses a
  # note inside a bracket. One that names a span is cut into a bracket each
  # span of its time, as LilyPond draws it, and one the voice refuses, such as
  # a cut inside a note, leaves its values unbracketed.
  class EventPlacer
    SUBTICKS_PER_WHOLE_NOTE = HeadMusic::Rudiment::Rhythm::SUBTICKS_PER_WHOLE

    # The time a \tuplet holds in one voice.
    Tuplet = Data.define(:voice, :from, :to, :span) do
      def groups
        return [[from, to]] unless span

        starts = [from]
        step = (span * SUBTICKS_PER_WHOLE_NOTE).to_i
        starts << starts.last.advance(subticks: step) while starts.last.advance(subticks: step) < to
        starts.zip(starts.drop(1) + [to])
      end

      def bracket
        groups.each do |group_from, group_to|
          voice.group_tuplet(from: group_from, to: group_to)
        rescue ArgumentError
          nil
        end
      end
    end

    # The hairpin marks of one context, paired as LilyPond's dynamic
    # engraver pairs them: at each moment, any dynamic (a level, an accent,
    # a hairpin start, or \!) ends the open hairpin, and only then does the
    # last start written there open a new one, so \mf\< and \<\mf read alike.
    # An unterminated hairpin, a stray end, and a hairpin its owner refuses
    # are dropped.
    class HairpinMarks
      def initialize
        @marks = []
      end

      def add(position, marks)
        ends = (marks.level || marks.note_dynamic) ? [:end] : []
        (ends + marks.hairpin_marks).each { |mark| @marks << [position, mark] }
      end

      # LilyPond draws a hairpin ending after all the written time, spacers
      # included, to the final barline, which follows a short final bar where
      # its time stops.
      def pair(owners, written_end:, final_barline:)
        open = nil
        @marks.group_by(&:first).sort_by(&:first).each do |position, group|
          to = (position == written_end) ? final_barline : position
          owners.each { |owner| add_span(owner, *open, to) } if open
          start = group.map(&:last).reverse.find { |mark| mark != :end }
          open = start && [start, position]
        end
      end

      private

      def add_span(owner, kind, from, to)
        owner.add_span(kind, from: from, to: to)
      rescue ArgumentError
        nil
      end
    end

    def initialize(layout)
      @layout = layout
      @open_spans = Hash.new { |hash, voice| hash[voice] = {} }
      @hairpin_marks = Hash.new { |hash, voice| hash[voice] = HairpinMarks.new }.compare_by_identity
      @bar_marks = BarMarkPlacer.new
      @spacers = Hash.new { |hash, voice| hash[voice] = [] }.compare_by_identity
      @spacer_ends = {}.compare_by_identity
      @marker_marks = {}.compare_by_identity
      @open_tuplets = {}.compare_by_identity
      @tuplets = []
    end

    def place(event, voice)
      return place_spacer(event, voice) if event.kind == :spacer
      return apply_marker(event, voice, position(voice)) unless event.music?

      rest_spacers(voice)
      case event.kind
      when :note then place_note(event, voice)
      when :rest then apply_marks(voice.place(voice.next_position, event.rhythmic_value), event)
      when :whole_bar_rest then place_whole_bar_rest(event, voice)
      end
      bar_marks.music_placed(voice)
    end

    def finish(flow)
      @spacers.keys.each { |voice| rest_spacers(voice) if spacers_past_music_bar?(voice) }
      @tuplets.each(&:bracket)
      @written_end = flow.voices.map { |voice| position(voice) }.max
      @hairpin_marks.each do |voice, hairpin_marks|
        hairpin_marks.pair([voice], written_end: @written_end, final_barline: flow.final_barline_position)
      end
      bar_marks.finish(flow)
    end

    # Where the voices' written time ends, trailing spacers included, once
    # they are all placed.
    attr_reader :written_end

    # Where the voice's next item goes, past any spacers it has read.
    def position(voice)
      @spacer_ends.fetch(voice) { voice.next_position }
    end

    def after_spacer(position, event)
      shifted(position, event, "A spacer")
    end

    def check_bar(event, position)
      return if bar_start?(position)

      raise ParseError.new(
        "Bar check failed at: #{elapsed_fraction(position)} in bar #{position.bar_number}",
        line_number: event.line, snippet: "|"
      )
    end

    def place_level(target, position, event)
      level = event.marks.level
      target.place_dynamic(position, level) if level
    rescue ArgumentError => error
      raise ParseError.new(error.message, line_number: event.line)
    end

    private

    attr_reader :layout, :bar_marks

    def shifted(position, event, name)
      subticks = event.fraction * SUBTICKS_PER_WHOLE_NOTE
      unless subticks.denominator == 1
        raise UnsupportedFeatureError.new("#{name} of #{event.fraction} whole notes falls between subticks", line_number: event.line)
      end

      position.advance(subticks: subticks.to_i)
    end

    def place_dynamics(voice, position, event)
      place_level(voice, position, event)
      @hairpin_marks[voice].add(position, event.marks)
    end

    def place_spacer(event, voice)
      position = position(voice)
      place_dynamics(voice, position, event)
      @spacer_ends[voice] = after_spacer(position, event)
      @spacers[voice] << event
    end

    # Spacers left in the bar where the music ends hold only time for a level
    # there. Once they reach a later bar, that bar is part of the music.
    def spacers_past_music_bar?(voice)
      music_stop = voice.next_position
      barline = bar_start?(music_stop) ? music_stop : HeadMusic::Content::Position.new(voice.flow, music_stop.bar_number + 1, 1, 0)
      position(voice) > barline
    end

    def rest_spacers(voice)
      @spacer_ends.delete(voice)
      @spacers.delete(voice)&.each do |spacer|
        rhythmic_value = HeadMusic::Notation::DottedDuration.rhythmic_value_for(spacer.fraction, tuplet: spacer.tuplet)
        raise unsupported("A spacer of #{spacer.fraction} whole notes has no rest to stand for it", spacer) unless rhythmic_value

        voice.place(voice.next_position, rhythmic_value)
      end
    end

    def apply_marker(event, voice, position)
      case event.kind
      when :bar_check then check_bar(event, position)
      when :key then apply_change(event, voice.flow, position, "\\key", :key_signature, :key_signature_at, :change_key_signature)
      when :time then apply_change(event, voice.flow, position, "\\time", :meter, :meter_at, :change_meter)
      when :staff_change then change_staff(event, voice, position)
      when :dynamics then place_marker(voice, position, event)
      when :after then place_dynamics(voice, shifted(position, event, "An \\after"), event)
      when :bar_mark then bar_marks.hold(event, voice, position)
      when :tuplet_start then @open_tuplets[voice] = [position, event.fraction]
      when :tuplet_end then close_tuplet(voice, position)
      end
    end

    def close_tuplet(voice, position)
      from, span = @open_tuplets.delete(voice)
      @tuplets << Tuplet.new(voice, from, position, span) if from && from < position
    end

    # A <> takes no time, so its slur marks and accent belong to the note
    # that starts where it stands, and are dropped where none does.
    def place_marker(voice, position, event)
      place_dynamics(voice, position, event)
      @marker_marks[voice] = [position, event.marks]
    end

    # Marks are applied where their event was placed, captured before the
    # voice moves on. A rest keeps only its dynamics.
    def apply_marks(voice_event, event)
      apply_marker_marks(voice_event)
      marks = event.marks
      unless voice_event.rest?
        voice_event.articulate(*marks.articulations).embellish(*marks.ornaments)
        voice_event.note_dynamic = marks.note_dynamic if marks.note_dynamic
      end
      place_dynamics(voice_event.voice, voice_event.position, event)
      apply_spans(voice_event, marks.span_marks)
    end

    def apply_spans(voice_event, span_marks)
      open = @open_spans[voice_event.voice]
      span_marks.each do |mark|
        key = [mark.kind, mark.id]
        next open[key] ||= [voice_event.position, mark.from_grace] if mark.opening

        from, from_grace = open.delete(key)
        add_span(voice_event, mark.kind, from, from_grace) if from
      end
    end

    def add_span(voice_event, kind, from, from_grace)
      to = voice_event.position
      return if from > to || (from == to && !from_grace)

      voice_event.voice.add_span(kind, from: from, to: to, from_grace: from_grace)
    rescue ArgumentError
      nil
    end

    # A crossing is a staff assignment from a bar onward, so it can only be
    # made at a bar's start, and only to a staff of the voice's own group.
    def change_staff(event, voice, position)
      staff = layout.staff_named(voice.part, event.staff_name)
      unless staff
        raise ParseError.new(%(No staff named "#{event.staff_name}" in this voice's staff group), line_number: event.line)
      end

      voice.cross_to(staff, from: change_bar_number(event, position, "\\change Staff"))
    end

    # What was written between the halves of a tied note takes effect where it
    # was written, in order, so a meter change is in force before the position
    # of anything after it is worked out.
    def apply_marker_marks(voice_event)
      position, marks = @marker_marks.delete(voice_event.voice)
      return unless position == voice_event.position

      voice_event.note_dynamic ||= marks.note_dynamic unless voice_event.rest?
      apply_spans(voice_event, marks.span_marks)
    end

    def place_note(event, voice)
      position = voice.next_position
      event.inner_events.each { |inner| apply_marker(inner.event, voice, position + inner.elapsed) }
      voice_event = voice.place(position, event.rhythmic_value, event.pitches)
      add_graces(voice_event, event.graces)
      apply_marks(voice_event, event)
    end

    def add_graces(voice_event, graces)
      graces.each do |grace|
        voice_event.add_grace_note(
          grace.pitches, grace.rhythmic_value, slashed: grace.slashed, tied: grace.tied, articulations: grace.marks.articulations
        )
      end
    end

    # A whole-bar rest is one voice event filling the bar it starts; a
    # longer span (R1*2 is two bars in LilyPond) has no single voice event
    # representation yet.
    def place_whole_bar_rest(event, voice)
      position = voice.next_position
      unless bar_start?(position)
        raise unsupported("A whole-bar rest must start a bar", event)
      end

      meter = voice.flow.meter_at(position.bar_number)
      bar_fraction = Rational(meter.top_number, meter.bottom_number)
      rhythmic_value = HeadMusic::Notation::DottedDuration.rhythmic_value_for(event.fraction)
      unless event.fraction == bar_fraction && rhythmic_value
        raise unsupported("Multi-bar rests are not yet supported (#{whole_notes(event.fraction)} whole notes in #{meter})", event)
      end

      apply_marks(voice.place(position, rhythmic_value), event)
    end

    # A change already in force at its bar is a no-op (the writer repeats
    # each change in every voice); a different explicit value at that bar,
    # or any disagreement with the seed at bar one, is a conflict.
    def apply_change(event, flow, position, command, attribute, at_reader, changer)
      value = event.public_send(attribute)
      bar_number = change_bar_number(event, position, command)
      return if flow.public_send(at_reader, bar_number) == value
      if bar_number == 1 || flow.public_send(:"#{attribute}_change_at", bar_number)
        raise ParseError.new("Conflicting #{command} at bar #{bar_number}", line_number: event.line)
      end

      flow.public_send(changer, bar_number, value)
    end

    # Key and meter live on bars, so a change is only representable at a
    # bar's start.
    def change_bar_number(event, position, command)
      return position.bar_number if bar_start?(position)

      raise unsupported("#{command} in the middle of a bar is not supported", event)
    end

    def bar_start?(position)
      position.count == 1 && position.tick.zero? && position.subtick.zero?
    end

    def whole_notes(fraction)
      (fraction.denominator == 1) ? fraction.numerator : fraction
    end

    def elapsed_fraction(position)
      meter = position.meter
      Rational(position.count - 1, meter.bottom_number) +
        Rational((position.tick * HeadMusic::Rudiment::Rhythm::SUBTICKS_PER_TICK) + position.subtick, SUBTICKS_PER_WHOLE_NOTE)
    end

    def unsupported(message, event)
      UnsupportedFeatureError.new(message, line_number: event.line)
    end
  end
end
