# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Records repeat and volta structure on the composition's bars.
  #
  # ABC spells this structure on bar lines and volta brackets, but the
  # composition carries it on the bars themselves, so the marks are applied as
  # each bar is completed rather than as each token arrives.
  class RepeatTagger
    # Bar styles that end a repeated section, terminating any volta.
    REPEAT_ENDING_STYLES = [":|", "::"].freeze
    REPEAT_STARTING_STYLES = ["|:", "::"].freeze
    SECTION_ENDING_STYLES = ["||", "|]", "[|"].freeze

    def initialize(composition)
      @composition = composition
    end

    # A bar line closes the bar before it and may open or close a repeat.
    def bar_line(state, style)
      tag_completed_bar(state)
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

    def open_volta(state, passes)
      state.active_passes = passes
      state.volta_start_bar = state.entered_bar_number
    end

    private

    attr_reader :composition

    def apply_repeat_flags(state, style)
      if REPEAT_ENDING_STYLES.include?(style)
        completed = state.completed_bar_number
        bar(completed).ends_repeat_after_num_plays = 2 if completed
      end
      return unless REPEAT_STARTING_STYLES.include?(style)

      bar(state.entered_bar_number).starts_repeat = true
    end

    def clear_passes_if_over(state, style)
      return unless REPEAT_ENDING_STYLES.include?(style) || SECTION_ENDING_STYLES.include?(style)

      state.active_passes = nil
      state.volta_start_bar = nil
    end

    def bar(bar_number)
      composition.bars(bar_number).last
    end
  end
end
