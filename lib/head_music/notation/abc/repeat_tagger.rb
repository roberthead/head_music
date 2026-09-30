# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Records barline styles and repeat and volta structure on the flow's bars.
  #
  # ABC spells this structure on bar lines and volta brackets, but the
  # flow carries it on the bars themselves, so the marks are applied as
  # each bar is completed rather than as each token arrives.
  class RepeatTagger
    # Bar styles that end a repeated section, terminating any volta.
    REPEAT_ENDING_STYLES = [":|", "::"].freeze
    REPEAT_STARTING_STYLES = ["|:", "::"].freeze
    SECTION_ENDING_STYLES = ["||", "|]", "[|"].freeze
    BARLINES = {"||" => :double, "|]" => :final, ".|" => :dotted}.freeze
    MINIMUM_PLAYS = 2

    def initialize(flow)
      @flow = flow
      @repeat_ends = Hash.new { |repeat_ends, state| repeat_ends[state] = [] }
      @plays = Hash.new(MINIMUM_PLAYS)
    end

    # A bar line closes the bar before it and may open or close a repeat.
    def bar_line(state, style)
      close_section(state) unless state.active_passes
      tag_completed_bar(state)
      mark_barline(state, style)
      apply_repeat_flags(state, style)
      clear_passes_if_over(state, style)
    end

    # A volta covers every bar from its opening bracket through the bar
    # line that ends it, so each completed bar in that span gets tagged.
    def tag_completed_bar(state)
      passes = state.active_passes
      return unless passes

      completed = state.completed_bar_number
      return unless completed && completed >= state.volta_start_bar

      bar(completed).plays_on_passes = passes
    end

    # A section plays as many times as its highest ending names, so a later
    # ending raises the play count of the repeats already read.
    def open_volta(state, passes)
      state.active_passes = passes
      state.volta_start_bar = state.entered_bar_number
      @plays[state] = [@plays[state], *passes].max
      @repeat_ends[state].each { |number| bar(number).ends_repeat_after_num_plays = @plays[state] }
    end

    private

    attr_reader :flow

    def mark_barline(state, style)
      barline = BARLINES[style]
      completed = state.completed_bar_number
      bar(completed).barline = barline if barline && completed
    end

    def apply_repeat_flags(state, style)
      if REPEAT_ENDING_STYLES.include?(style)
        completed = state.completed_bar_number
        end_repeat(state, completed) if completed
      end
      return unless REPEAT_STARTING_STYLES.include?(style)

      close_section(state)
      bar(state.entered_bar_number).starts_repeat = true
    end

    def end_repeat(state, bar_number)
      bar(bar_number).ends_repeat_after_num_plays = @plays[state]
      @repeat_ends[state] << bar_number
    end

    # A bar outside any volta, or a new repeat, ends the section whose play
    # count later endings could raise, as Flow::PerformanceOrder reads it.
    def close_section(state)
      @repeat_ends.delete(state)
      @plays.delete(state)
    end

    def clear_passes_if_over(state, style)
      return unless REPEAT_ENDING_STYLES.include?(style) || SECTION_ENDING_STYLES.include?(style)

      state.active_passes = nil
      state.volta_start_bar = nil
    end

    def bar(bar_number)
      flow.bars(bar_number).last
    end
  end
end
