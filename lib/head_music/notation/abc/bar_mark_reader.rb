# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Reads the tokens that mark bars rather than sound in them -- bar lines,
  # volta brackets, and part labels -- and records what they spell on the
  # flow's bars: barlines, repeats, and voltas through a RepeatTagger, and
  # part labels and navigation decorations through a NavigationTagger.
  class BarMarkReader
    def initialize(flow)
      @flow = flow
      @repeats = RepeatTagger.new(flow)
      @navigation = NavigationTagger.new(flow)
    end

    def at_note(state)
      @navigation.record_at_note(state)
    end

    # A note tied across the bar line is left pending rather than flushed, so
    # the note after the bar line fuses onto it the way an in-bar tie does,
    # keeping the pending note's pitch: the bar's accidental reset would
    # otherwise strip the sharp or flat the tie carries.
    def bar_line(state, token)
      @navigation.record_at_bar_line(state)
      state.cross_bar_line(token.line)
      @repeats.bar_line(state, token.style)
      state.pitch_builder_in_key.start_new_bar
    end

    def volta(state, token)
      line = token.line
      state.ensure_not_awaiting_note(line)
      passes = token.passes
      raise ParseError.new("Volta has no passes", line_number: line) if passes.empty?

      @navigation.record_at_bar_line(state)
      state.cross_bar_line(line)
      @repeats.open_volta(state, passes)
    end

    # A part label marks the bar it opens. One before any voice has music
    # opens the first bar.
    def part_label(state, token)
      label = token.lexeme
      return if label.empty?

      bar_number = state ? state.entered_bar_number : HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR
      @navigation.record_part_label(state, label, bar_number)
    end

    # Navigation waiting when a voice ends marks the bar it closes.
    def leave(state)
      @navigation.record_at_bar_line(state, entering: false)
    end

    # A voice's last bar may lie inside a volta.
    def close(state)
      @repeats.tag_completed_bar(state)
    end

    def finish(states)
      @navigation.apply
      imply_final_barline(states)
    end

    private

    # The last bar's final barline is implied, and writers draw it. A bar
    # holding only invisible rests counts, though it adds no voice event.
    def imply_final_barline(states)
      last_bar_number = [@flow.last_sounding_bar_number, *states.filter_map(&:completed_bar_number)].max
      last_bar = @flow.bar(last_bar_number)
      last_bar.barline = :regular if last_bar.barline == :final
    end
  end
end
