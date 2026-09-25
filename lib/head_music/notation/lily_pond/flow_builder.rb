# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Replays a Document's voice streams onto a fresh flow.
  #
  # Every placement lands at the voice's next position, so bar checks and
  # key or meter commands are verified against where the music actually
  # is, the way LilyPond verifies them at compile time.
  class FlowBuilder
    TICKS_PER_WHOLE_NOTE = HeadMusic::Rudiment::Rhythm::PPQN * 4

    # One voice's place in the replay: the events it has left, and the
    # voice they are being placed on.
    class Cursor
      attr_reader :voice

      def initialize(stream, voice)
        @events = stream.events.dup
        @voice = voice
      end

      def event
        @events.first
      end

      def done?
        @events.empty?
      end

      def advance
        @events.shift
      end

      # Key and meter changes are answered before the notes of the same
      # position, so a bar is placed under the meter that governs it.
      def sort_key
        [voice.next_position, event.music? ? 1 : 0]
      end
    end

    attr_reader :document

    def initialize(document)
      @document = document
    end

    def flow
      @flow ||= build
    end

    private

    def build
      streams = document.streams
      raise ParseError, "LilyPond input contains no music" if streams.empty?

      flow = HeadMusic::Content::Flow.new(
        name: document.title, composer: document.composer,
        key_signature: document.first_key_signature, meter: document.first_meter
      )
      replay(streams.filter_map { |stream| cursor_for(flow, stream) })
      flow
    end

    # A staff group is one part, whose staff system holds the group's staves
    # in order. A silent staff keeps its place in the system without a voice,
    # since that is how the writer renders a staff nobody is written on.
    def cursor_for(flow, stream)
      group_staff = stream.group_staff
      return Cursor.new(stream, flow.add_voice(role: stream.role)) unless group_staff

      part = part_for(flow, group_staff.group)
      return if stream.silent? && stream.role.nil?

      voice = part.add_voice(role: stream.role)
      staff = staves_by_group_staff[group_staff]
      voice.assign_staff(HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR, staff) unless staff.equal?(part.staff_system.first_staff)
      Cursor.new(stream, voice)
    end

    def part_for(flow, group)
      parts_by_group[group] ||= begin
        staves = group.staves.map { |group_staff| staves_by_group_staff[group_staff] = HeadMusic::Content::Staff.new(clef: clef_key(group_staff)) }
        part = flow.add_part(staff_system: HeadMusic::Content::StaffSystem.new(staves: staves, bracket: group.bracket))
        staves_by_name[part] = group.staves.zip(staves).reverse.to_h { |group_staff, staff| [group_staff.name, staff] }
        part
      end
    end

    # The clef a staff's first voice opens with, where the writer puts it.
    def clef_key(group_staff)
      name = document.streams.select { |stream| stream.group_staff.equal?(group_staff) }.filter_map(&:opening_clef).first
      name && clef_keys[name]
    end

    def clef_keys
      @clef_keys ||= VoiceWriter::CLEF_NAMES.to_h { |key, name| [name.delete('"'), key] }
    end

    def parts_by_group
      @parts_by_group ||= {}.compare_by_identity
    end

    def staves_by_group_staff
      @staves_by_group_staff ||= {}.compare_by_identity
    end

    def staves_by_name
      @staves_by_name ||= {}.compare_by_identity
    end

    # The voices advance together rather than one after another, so a
    # \time or \key that one staff carries is in force before another
    # staff places the bar it governs. Replaying a whole voice at a time
    # would leave the earlier voices positioned under the old meter.
    def replay(cursors)
      cursors = cursors.reject(&:done?)
      until cursors.empty?
        cursor = cursors.min_by(&:sort_key)
        apply(cursor.event, cursor.voice)
        cursor.advance
        cursors = cursors.reject(&:done?)
      end
    end

    def apply(event, voice)
      case event.kind
      when :note then place_note(event, voice)
      when :rest then voice.place(voice.next_position, event.rhythmic_value)
      when :whole_bar_rest then place_whole_bar_rest(event, voice)
      else apply_marker(event, voice, voice.next_position)
      end
    end

    def apply_marker(event, voice, position)
      case event.kind
      when :bar_check then check_bar(event, position)
      when :key then apply_change(event, voice.flow, position, "\\key", :key_signature, :key_signature_at, :change_key_signature)
      when :time then apply_change(event, voice.flow, position, "\\time", :meter, :meter_at, :change_meter)
      when :staff_change then change_staff(event, voice, position)
      end
    end

    # A crossing is a staff assignment from a bar onward, so it can only be
    # made at a bar's start, and only to a staff of the voice's own group.
    def change_staff(event, voice, position)
      staff = staves_by_name.fetch(voice.part, {})[event.staff_name]
      unless staff
        raise ParseError.new(%(No staff named "#{event.staff_name}" in this voice's staff group), line_number: event.line)
      end

      voice.cross_to(staff, from: change_bar_number(event, position, "\\change Staff"))
    end

    # What was written between the halves of a tied note takes effect where it
    # was written, in order, so a meter change is in force before the position
    # of anything after it is worked out.
    def place_note(event, voice)
      position = voice.next_position
      event.inner_events.each { |inner| apply_marker(inner.event, voice, position + inner.elapsed) }
      voice.place(position, event.rhythmic_value, event.pitches)
    end

    def check_bar(event, position)
      return if bar_start?(position)

      raise ParseError.new(
        "Bar check failed at: #{elapsed_fraction(position)} in bar #{position.bar_number}",
        line_number: event.line, snippet: "|"
      )
    end

    # A whole-bar rest is one placement filling the bar it starts; a
    # longer span (R1*2 is two bars in LilyPond) has no single-placement
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

      voice.place(position, rhythmic_value)
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
      position.count == 1 && position.tick.zero?
    end

    def whole_notes(fraction)
      (fraction.denominator == 1) ? fraction.numerator : fraction
    end

    def elapsed_fraction(position)
      meter = position.meter
      Rational(position.count - 1, meter.bottom_number) + Rational(position.tick, TICKS_PER_WHOLE_NOTE)
    end

    def unsupported(message, event)
      UnsupportedFeatureError.new(message, line_number: event.line)
    end
  end
end
