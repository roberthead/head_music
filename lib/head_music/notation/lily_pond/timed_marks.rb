# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # Places a voice's marks that take no time, such as its dynamic levels, at
  # their exact positions among the links the voice is written in. A mark
  # where a link attacks is written after that link. A mark inside a link is
  # written with \after on it, which leaves the link whole. A mark after the
  # voice's last link in a bar is left for the spacers that follow the music.
  #
  # Offsets are fractions of a whole note into a bar, as the links' are.
  class TimedMarks
    Mark = Data.define(:bar_number, :offset, :token)

    # The voice's levels that are in force where they fall, since an accent
    # such as fp on the same note overrides its level there.
    def self.levels(voice)
      events = voice.dynamic_events.select { |event| voice.dynamic_at(event.position) == event.level }
      new(events.map { |event| mark(event.position, "\\#{event.level.name_key}") })
    end

    def self.mark(position, token)
      Mark.new(position.bar_number, HeadMusic::Notation::BarSplitter.offset_in_bar(position), token)
    end

    # How far into a link an \after reaches: a duration where one note value
    # spans it, and a multiplied whole note otherwise.
    def self.duration(fraction)
      value = HeadMusic::Notation::DottedDuration.rhythmic_value_for(fraction)
      return DurationWriter.token(value) if value && !value.tied_value

      "1*#{fraction.numerator}/#{fraction.denominator}"
    end

    def initialize(marks)
      @marks_by_bar = marks.sort_by(&:offset).group_by(&:bar_number)
    end

    # What follows the link that starts at the offset.
    def attacks(bar_number, offset)
      marks_in(bar_number).select { |mark| mark.offset == offset }.map(&:token).join
    end

    # What precedes the link: an \after for each mark inside it.
    def afters(bar_number, from, to)
      marks_in(bar_number).select { |mark| mark.offset > from && mark.offset < to }
        .map { |mark| "\\after #{self.class.duration(mark.offset - from)} #{mark.token} " }.join
    end

    # The marks at or after the offset where the voice's music in the bar ends.
    def trailing(bar_number, offset)
      marks_in(bar_number).select { |mark| mark.offset >= offset }
    end

    private

    def marks_in(bar_number)
      @marks_by_bar.fetch(bar_number, [])
    end
  end
end
