# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # The spacers each voice has read, which move its position without placing
  # an event. Those that music follows become rests, since a voice holds no
  # gaps. Those left in the bar where the music ends hold only time for a
  # level there; once they reach a later bar, that bar is part of the music.
  class Spacers
    def initialize
      @held = Hash.new { |hash, voice| hash[voice] = [] }.compare_by_identity
      @ends = {}.compare_by_identity
      @remainders = {}
    end

    # Where the voice's next item goes, past any spacers it has read.
    def position(voice)
      @ends.fetch(voice) { voice.next_position }
    end

    def hold(voice, event)
      @ends[voice] = after(position(voice), event)
      @held[voice] << event
    end

    # Spacers round to the nearest subtick, as the notes of a septuplet do,
    # measured from where a run of them reached exactly, so s1*1/28 s1*3/28
    # lands on the onsets of the septuplet sixteenths it stands beside.
    def after(position, event)
      exact = @remainders.fetch(position, 0) + (event.fraction * HeadMusic::Rudiment::Rhythm::SUBTICKS_PER_WHOLE)
      step = exact.round
      position.advance(subticks: step).tap { |reached| @remainders[reached] = exact - step }
    end

    def rest(voice)
      @ends.delete(voice)
      @held.delete(voice)&.each do |spacer|
        rhythmic_duration = HeadMusic::Notation::DottedDuration.rhythmic_duration_for(spacer.fraction, tuplet: spacer.tuplet)
        unless rhythmic_duration
          raise UnsupportedFeatureError.new("A spacer of #{spacer.fraction} whole notes has no rest to stand for it", line_number: spacer.line)
        end

        voice.place(voice.next_position, rhythmic_duration)
      end
    end

    def finish
      @held.keys.each { |voice| rest(voice) if past_music_bar?(voice) }
    end

    private

    def past_music_bar?(voice)
      music_stop = voice.next_position
      bar_start = HeadMusic::Content::Position.new(voice.flow, music_stop.bar_number, 1, 0)
      barline = (music_stop == bar_start) ? music_stop : music_stop.start_of_next_bar
      position(voice) > barline
    end
  end
end
