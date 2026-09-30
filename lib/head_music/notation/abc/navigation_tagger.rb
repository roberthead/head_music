# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # Records part labels and segno, coda, Fine, To Coda, and D.C. or D.S.
  # decorations on the flow's bars once the whole tune is read.
  #
  # A part label, segno, or coda sign marks the start of a bar, and the rest
  # mark its end, so each decoration is noted with both of the bars it could
  # mean: before a note, that note's bar; before a bar line, the bar it opens
  # and the bar it closes. One that opens a bar after the music ends has no
  # bar to mark, and is dropped.
  class NavigationTagger
    Mark = Data.define(:key, :opening_bar, :closing_bar, :value)

    OPENING_KEYS = %w[segno coda rehearsal_mark].freeze
    FLAG_KEYS = %w[segno coda fine to_coda].freeze

    def initialize(flow)
      @flow = flow
      @marks = Hash.new { |marks, state| marks[state] = [] }
    end

    def record(state, decorations, opening_bar:, closing_bar:)
      decorations.each { |decoration| @marks[state] << Mark.new(decoration.key, opening_bar, closing_bar, nil) }
    end

    def record_part_label(state, label, bar_number)
      @marks[state] << Mark.new("rehearsal_mark", bar_number, nil, label)
    end

    def apply
      al_coda = @marks.values.flatten.any? { |mark| HeadMusic::Content::Jump.get(mark.key)&.to == :coda }
      @marks.each_value do |marks|
        marks = read_to_coda(marks) if al_coda
        marks.each { |mark| apply_mark(mark) }
      end
    end

    private

    # Tunes written without !dacoda! mark the To Coda of a D.S. or D.C. al
    # Coda with a second coda sign. Read only where the jump needs it, so a
    # flow whose two coda signs mean two coda signs reads back as written.
    def read_to_coda(marks)
      codas = marks.select { |mark| mark.key == "coda" }
      return marks if codas.length < 2 || marks.any? { |mark| mark.key == "to_coda" }

      marks.map { |mark| mark.equal?(codas.first) ? mark.with(key: "to_coda") : mark }
    end

    def apply_mark(mark)
      key = mark.key
      bar_number = OPENING_KEYS.include?(key) ? mark.opening_bar : mark.closing_bar
      return unless bar_number
      return if bar_number > last_bar_number

      bar = @flow.bar(bar_number)
      if key == "rehearsal_mark"
        bar.rehearsal_mark = mark.value
      elsif FLAG_KEYS.include?(key)
        bar.public_send(:"#{key}=", true)
      else
        bar.jump = HeadMusic::Content::Jump.get(key)
      end
    end

    def last_bar_number
      @last_bar_number ||= @flow.last_sounding_bar_number
    end
  end
end
