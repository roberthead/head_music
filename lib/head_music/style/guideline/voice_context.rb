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
