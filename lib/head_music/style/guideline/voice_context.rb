module HeadMusic::Style; end

class HeadMusic::Style::Guideline
  # The company the voice keeps: the other parts of the flow, sorted and
  # named the way a counterpoint rule asks after them.
  module VoiceContext
    protected

    def voices
      @voices ||= voice.flow.voices
    end

    def other_voices
      @other_voices ||= voices.reject { |part| part == voice }
    end

    def cantus_firmus
      @cantus_firmus ||= other_voices.detect(&:cantus_firmus?) || other_voices.first
    end

    def higher_voices
      @higher_voices ||= unsorted_higher_voices.sort_by(&:highest_pitch).reverse
    end

    def lower_voices
      @lower_voices ||= unsorted_lower_voices.sort_by(&:lowest_pitch).reverse
    end

    def downbeat_position?(position)
      position.count == 1 && position.tick.zero? && position.subtick.zero?
    end

    def strong_beat_position?(position)
      position.strong?
    end

    # The first strong beat after the position: later in its bar, or else the
    # next bar's downbeat.
    def next_strong_beat(position)
      later_counts = (position.count + 1)..position.meter.counts_per_bar
      later_counts.map { |count| HeadMusic::Content::Position.new(voice.flow, position.bar_number, count, 0) }
        .detect(&:strong?) || position.start_of_next_bar
    end

    def bar_downbeats
      @bar_downbeats ||= bar_numbers.map { |bar| HeadMusic::Content::Position.new(voice.flow, bar, 1, 0) }
    end

    def bar_numbers
      sounding = voices.reject { |part| part.notes.empty? }
      return [] if sounding.empty?

      (sounding.map(&:earliest_bar_number).min..sounding.map(&:latest_bar_number).max).to_a
    end

    def bass_voice?
      lower_voices.empty?
    end

    def unsorted_higher_voices
      other_voices.select { |part| part.highest_pitch && highest_pitch && part.highest_pitch > highest_pitch }
    end

    def unsorted_lower_voices
      other_voices.select { |part| part.lowest_pitch && lowest_pitch && part.lowest_pitch < lowest_pitch }
    end
  end
end
