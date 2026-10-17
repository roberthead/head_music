module HeadMusic::Notation::MEI
  # Reads rehearsal marks, segno, coda, Fine, To Coda, D.C., and D.S. onto
  # the bars their controls are in. A <repeatMark>'s @func decides what it
  # is, its text telling To Coda from a coda sign and naming a jump's
  # target; one with no @func, and a <dir>, are read by their words. For
  # each bar the first rehearsal mark and jump win, and a flag set on any
  # staff is set.
  class NavigationReader < MarkReader
    FINE = /\AFine\.?\z/i
    TO_CODA = /\ATo\s+Coda\z/i
    SEGNO_SIGNS = ["\u{E047}", "\u{1D10B}"].freeze
    CODA_SIGNS = ["\u{E048}", "\u{1D10C}"].freeze
    JUMPS = {"daCapo" => :da_capo, "dalSegno" => :dal_segno}.freeze

    def initialize(anchors)
      super
      @marks = Hash.new { |marks, number| marks[number] = {} }
    end

    def control(record)
      element = record.element
      mark = case element.name
      when "reh" then rehearsal_mark(anchors.text(element))
      when "repeatMark" then repeat_mark(record, anchors.text(element))
      when "dir" then word_mark(anchors.text(element))
      end
      return unless mark

      field, value = mark
      @marks[bar_of(record)][field] ||= value
    end

    def apply(flow)
      HeadMusic::Notation::BarMarks.apply(flow, @marks)
    end

    private

    def rehearsal_mark(text)
      [:rehearsal_mark, text] unless text.empty?
    end

    def repeat_mark(record, text)
      func = attribute_of(record, "func")
      case func
      when "segno" then [:segno, true]
      when "coda" then [TO_CODA.match?(text) ? :to_coda : :coda, true]
      when "fine" then [:fine, true]
      when *JUMPS.keys then [:jump, HeadMusic::Content::Jump.new(JUMPS[func], to: HeadMusic::Content::Jump.get(text)&.to)]
      else word_mark(text)
      end
    end

    def word_mark(text)
      return [:segno, true] if SEGNO_SIGNS.include?(text)
      return [:coda, true] if CODA_SIGNS.include?(text)
      return [:fine, true] if FINE.match?(text)
      return [:to_coda, true] if TO_CODA.match?(text)

      jump = HeadMusic::Content::Jump.get(text)
      jump && [:jump, jump]
    end

    # Ids place a control at its event's bar; beats, at its measure's.
    def bar_of(record)
      record.start&.event? ? record.start.bar_number : record.bar_number
    end
  end
end

HeadMusic::Notation::MEI::MARK_READERS << HeadMusic::Notation::MEI::NavigationReader
