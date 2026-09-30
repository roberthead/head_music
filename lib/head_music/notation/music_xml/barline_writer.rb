require_relative "xml_text"

# A namespace for MusicXML-notation rendering helpers
module HeadMusic::Notation::MusicXML
  # Renders a measure's <barline> elements: a left barline where a repeat or an
  # ending starts, and a right barline for a styled barline, the end of a
  # repeat or an ending, or the implied final barline of the last measure.
  class BarlineWriter
    include XmlText

    BAR_STYLES = {
      regular: nil,
      double: "light-light",
      final: "light-heavy",
      dashed: "dashed",
      dotted: "dotted"
    }.freeze

    delegate :bar, :bar_numbers, to: :plan

    def initialize(plan)
      @plan = plan
    end

    def left_lines(bar_number)
      current = bar(bar_number)
      ending = starts_ending?(bar_number) && ending_line(current, "start")
      return [] unless current.starts_repeat? || ending

      barline_lines("left", [
        current.starts_repeat? && bar_style_line("heavy-light"),
        ending,
        current.starts_repeat? && %(#{INDENT * 4}<repeat direction="forward"/>)
      ])
    end

    def right_lines(bar_number)
      current = bar(bar_number)
      children = [
        bar_style(bar_number) && bar_style_line(bar_style(bar_number)),
        ends_ending?(bar_number) && ending_line(current, current.ends_repeat? ? "stop" : "discontinue"),
        current.ends_repeat? && backward_repeat_line(current)
      ]
      return [] unless children.any?

      barline_lines("right", children)
    end

    private

    attr_reader :plan

    def bar_style(bar_number)
      current = bar(bar_number)
      return "light-heavy" if current.ends_repeat?
      return "light-heavy" if current.barline == :regular && bar_number == bar_numbers.last

      BAR_STYLES.fetch(current.barline)
    end

    def starts_ending?(bar_number)
      passes = bar(bar_number).plays_on_passes
      previous = bar(bar_number - 1)
      return false unless passes
      return true unless previous

      previous.ends_repeat? || previous.plays_on_passes != passes
    end

    def ends_ending?(bar_number)
      current = bar(bar_number)
      following = bar(bar_number + 1)
      return false unless current.plays_on_passes
      return true if current.ends_repeat? || following.nil?

      following.plays_on_passes != current.plays_on_passes
    end

    def barline_lines(location, children)
      [
        %(#{INDENT * 3}<barline location="#{location}">),
        *children.select { |child| child },
        "#{INDENT * 3}</barline>"
      ]
    end

    def bar_style_line(style)
      "#{INDENT * 4}<bar-style>#{style}</bar-style>"
    end

    def ending_line(current, type)
      number = current.plays_on_passes.join(", ")
      return %(#{INDENT * 4}<ending number="#{number}" type="#{type}"/>) unless type == "start"

      %(#{INDENT * 4}<ending number="#{number}" type="start">#{number}.</ending>)
    end

    def backward_repeat_line(current)
      plays = current.ends_repeat_after_num_plays
      times = (plays > 2) ? %( times="#{plays}") : ""
      %(#{INDENT * 4}<repeat direction="backward"#{times}/>)
    end
  end
end
