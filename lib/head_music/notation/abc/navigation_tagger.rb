# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Records segno, coda, Fine, To Coda, and D.C. or D.S. decorations on the
  # flow's bars once the whole tune is read.
  #
  # A segno or coda sign marks the start of a bar, and the rest mark its end,
  # so each decoration is noted with both of the bars it could mean: before a
  # note, that note's bar; before a bar line, the bar it opens and the bar it
  # closes.
  class NavigationTagger
    Mark = Data.define(:key, :opening_bar, :closing_bar)

    OPENING_KEYS = %w[segno coda].freeze
    FLAG_KEYS = %w[segno coda fine to_coda].freeze

    def initialize(flow)
      @flow = flow
      @marks = Hash.new { |marks, state| marks[state] = [] }
    end

    def record(state, decorations, opening_bar:, closing_bar:)
      decorations.each { |decoration| @marks[state] << Mark.new(decoration.key, opening_bar, closing_bar) }
    end

    def apply
      @marks.each_value { |marks| read_to_coda(marks).each { |mark| apply_mark(mark) } }
    end

    private

    # Tunes written without !dacoda! mark the To Coda with a second coda sign.
    def read_to_coda(marks)
      codas = marks.select { |mark| mark.key == "coda" }
      return marks if codas.length < 2 || marks.any? { |mark| mark.key == "to_coda" }

      marks.map { |mark| mark.equal?(codas.first) ? mark.with(key: "to_coda") : mark }
    end

    def apply_mark(mark)
      key = mark.key
      bar_number = OPENING_KEYS.include?(key) ? mark.opening_bar : mark.closing_bar
      return unless bar_number

      bar = @flow.bars(bar_number).last
      if FLAG_KEYS.include?(key)
        bar.public_send(:"#{key}=", true)
      else
        bar.jump = HeadMusic::Content::Jump.get(key)
      end
    end
  end
end
