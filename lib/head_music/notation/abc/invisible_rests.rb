# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # The invisible rests a voice holds past its last voice event. Each becomes
  # a rest only once music follows it, so until then it only moves where the
  # voice's time has reached.
  class InvisibleRests
    def initialize(voice)
      @voice = voice
      @values = []
    end

    def any?
      @values.any?
    end

    # Where the rest starts and ends.
    def add(rhythmic_value)
      from = music_end
      @values << rhythmic_value
      [from, music_end]
    end

    def music_end
      @values.reduce(@voice.next_position) { |position, rhythmic_value| position + rhythmic_value }
    end

    def place
      @values.each { |rhythmic_value| @voice.place(@voice.next_position, rhythmic_value) }
      @values.clear
    end
  end
end
