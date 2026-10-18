# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Applies the commands that act on bars: bar checks, key and meter
  # changes, and staff crossings. Each is verified against where the voice
  # actually is, the way LilyPond verifies it at compile time. Key, meter,
  # and staff live on bars, so a change is only representable at a bar's
  # start.
  class BarCommands
    KINDS = %i[bar_check key time staff_change].freeze
    CHANGES = {key: ["\\key", :key_signature], time: ["\\time", :meter]}.freeze

    def initialize(layout)
      @layout = layout
    end

    def apply(event, voice, position)
      case event.kind
      when :bar_check then check_bar(event, position)
      when :staff_change then change_staff(event, voice, position)
      else apply_change(event, voice.flow, position, *CHANGES.fetch(event.kind))
      end
    end

    def check_bar(event, position)
      return if bar_start?(position)

      raise ParseError.new(
        "Bar check failed at: #{elapsed_fraction(position)} in bar #{position.bar_number}",
        line_number: event.line, snippet: "|"
      )
    end

    def bar_start?(position)
      position.count == 1 && position.tick.zero? && position.subtick.zero?
    end

    private

    attr_reader :layout

    # A crossing is a staff assignment from a bar onward, so it can only be
    # made to a staff of the voice's own group.
    def change_staff(event, voice, position)
      staff = layout.staff_named(voice.part, event.staff_name)
      unless staff
        raise ParseError.new(%(No staff named "#{event.staff_name}" in this voice's staff group), line_number: event.line)
      end

      voice.cross_to(staff, from: change_bar_number(event, position, "\\change Staff"))
    end

    # A change already in force at its bar is a no-op (the writer repeats
    # each change in every voice); a different explicit value at that bar,
    # or any disagreement with the seed at bar one, is a conflict.
    def apply_change(event, flow, position, command, attribute)
      value = event.public_send(attribute)
      bar_number = change_bar_number(event, position, command)
      return if flow.public_send(:"#{attribute}_at", bar_number) == value
      if bar_number == 1 || flow.public_send(:"#{attribute}_change_at", bar_number)
        raise ParseError.new("Conflicting #{command} at bar #{bar_number}", line_number: event.line)
      end

      flow.public_send(:"change_#{attribute}", bar_number, value)
    end

    def change_bar_number(event, position, command)
      return position.bar_number if bar_start?(position)

      raise UnsupportedFeatureError.new("#{command} in the middle of a bar is not supported", line_number: event.line)
    end

    def elapsed_fraction(position)
      Rational(position.count - 1, position.meter.bottom_number) +
        Rational((position.tick * HeadMusic::Rudiment::Rhythm::SUBTICKS_PER_TICK) + position.subtick, HeadMusic::Rudiment::Rhythm::SUBTICKS_PER_WHOLE)
    end
  end
end
