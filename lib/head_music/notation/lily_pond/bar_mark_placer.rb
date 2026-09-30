# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Puts a voice's bar marks on the bars they mark. A rehearsal mark, segno,
  # or coda sign at a bar's start marks that bar, once music follows it; a
  # barline, Fine, To Coda, or jump at a bar's start closes the bar before.
  # A closing mark in the middle of a bar counts only where the voice ends
  # there, as it does after a short final bar. Any other mark in the middle
  # of a bar has no bar to go on and is dropped.
  class BarMarkPlacer
    def initialize
      @openings = Hash.new { |hash, voice| hash[voice] = [] }.compare_by_identity
      @closings = Hash.new { |hash, voice| hash[voice] = [] }.compare_by_identity
    end

    def hold(event, voice, position)
      if event.bar_mark.opening?
        @openings[voice] << [event, position.bar_number] if bar_start?(position)
      elsif bar_start?(position)
        apply(event, voice.flow, position.bar_number - 1)
      else
        @closings[voice] << [event, position.bar_number]
      end
    end

    def music_placed(voice)
      @openings.delete(voice)&.each { |event, bar_number| apply(event, voice.flow, bar_number) }
      @closings.delete(voice)
    end

    # The final barline at the end of the music is implied, so it is not kept.
    def finish(flow)
      @closings.each_value { |marks| marks.each { |event, bar_number| apply(event, flow, bar_number) } }
      @closings.clear
      @openings.clear
      bar_number = last_bar_number(flow)
      bar = bar_number && flow.bars(bar_number).last
      bar.barline = :regular if bar&.barline == :final
    end

    private

    # A mark that agrees with the bar is a no-op, since the writer repeats
    # each mark in every voice; one that contradicts it is a conflict.
    def apply(event, flow, bar_number)
      return if bar_number < flow.earliest_bar_number

      mark = event.bar_mark
      bar = flow.bars(bar_number).last
      current = current_value(bar, mark.attribute)
      return if current == mark.value
      unless [nil, false, :regular].include?(current)
        raise ParseError.new("Conflicting bar marks at bar #{bar_number}", line_number: event.line)
      end

      bar.public_send(:"#{mark.attribute}=", mark.value)
    end

    def current_value(bar, attribute)
      bar.public_send(HeadMusic::Content::Bar::FLAGS.include?(attribute) ? :"#{attribute}?" : attribute)
    end

    def last_bar_number(flow)
      finish = flow.voices.filter_map { |voice| voice.last_voice_event&.next_position }.max
      return unless finish

      bar_start?(finish) ? finish.bar_number - 1 : finish.bar_number
    end

    def bar_start?(position)
      position.count == 1 && position.tick.zero?
    end
  end
end
