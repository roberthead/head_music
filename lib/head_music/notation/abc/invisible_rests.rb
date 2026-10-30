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
    def add(rhythmic_duration)
      from = music_end
      @values << rhythmic_duration
      [from, music_end]
    end

    def music_end
      @values.reduce(@voice.next_position) { |position, rhythmic_duration| position + rhythmic_duration }
    end

    # Once they reach a bar past the last voice event's, that bar is part of
    # the music, and they are rests.
    def past_last_bar?
      music_end.ending_bar_number > @voice.next_position.ending_bar_number
    end

    def place
      @values.each { |rhythmic_duration| @voice.place(@voice.next_position, rhythmic_duration) }
      @values.clear
    end
  end
end
