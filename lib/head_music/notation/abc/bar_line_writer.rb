# Parses and renders ABC notation as HeadMusic::Content flows
module HeadMusic::Notation::ABC
  # Writes the markings around a bar's music. Before it: its opening repeat,
  # volta, and part label. After it: its Fine, To Coda, or jump, the next
  # bar's segno or coda sign, and the bar line.
  #
  # A segno or coda sign before a bar line marks the bar it opens, which is
  # how the parser reads it back.
  module BarLineWriter
    BARLINES = {double: "||", final: "|]", dotted: ".|"}.freeze
    VOLTA_ENDING_TOKENS = [":|", "::", "||", "|]", "[|"].freeze

    JUMPS = {
      [:da_capo, nil] => "D.C.",
      [:da_capo, :fine] => "D.C.alfine",
      [:da_capo, :coda] => "D.C.alcoda",
      [:dal_segno, nil] => "D.S.",
      [:dal_segno, :fine] => "D.S.alfine",
      [:dal_segno, :coda] => "D.S.alcoda"
    }.freeze

    module_function

    # The first bar has no bar line before it to carry its repeat or signs.
    def opening(bar, previous)
      return volta(bar, previous) + part_label(bar) if previous

      (bar.starts_repeat? ? "|:" : "") + volta(bar, nil) + part_label(bar) + signs(bar)
    end

    def closing(bar, following)
      navigation = decorations([("fine" if bar.fine?), ("dacoda" if bar.to_coda?), bar.jump && JUMPS.fetch(bar.jump.deconstruct)])
      return navigation + last_token(bar) unless following

      navigation + signs(following) + token(bar, following)
    end

    # A repeat mark takes the place of a styled bar line, ABC has no dashed
    # bar line, and "[|" closes a volta where a plain bar line would carry it
    # into the next bar.
    def token(bar, following)
      ends = bar.ends_repeat?
      starts = following.starts_repeat?
      return "::" if ends && starts
      return ":|" if ends
      return "|:" if starts

      token = BARLINES.fetch(bar.barline, "|")
      return "[|" if bar.plays_on_passes && following.plays_on_passes.nil? && !VOLTA_ENDING_TOKENS.include?(token)

      token
    end

    def last_token(bar)
      return ":|" if bar.ends_repeat?

      BARLINES.fetch(bar.barline, "|]")
    end

    def signs(bar)
      decorations([("segno" if bar.segno?), ("coda" if bar.coda?)])
    end

    def decorations(names)
      names.compact.map { |name| "!#{name}!" }.join
    end

    # A volta already open with the same passes carries on until a repeat or
    # section bar line closes it.
    def volta(bar, previous)
      passes = bar.plays_on_passes
      return "" unless passes

      carried = previous&.plays_on_passes == passes && !VOLTA_ENDING_TOKENS.include?(token(previous, bar))
      carried ? "" : "[#{passes.join(",")} "
    end

    def part_label(bar)
      bar.rehearsal_mark ? "[P:#{bar.rehearsal_mark}]" : ""
    end
  end
end
