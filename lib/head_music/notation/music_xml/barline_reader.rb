require_relative "mark_reader"
require_relative "barline_writer"

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads barline styles, repeats, and endings onto the bars. A barline both
  # closes the bar before it and opens the bar after it: a right barline
  # closes its own bar, and a left one the bar before. A barline inside a
  # bar, where an implicit measure completes it, closes that bar, as kern
  # records a mid-bar repeat on the whole bar, and opens the next.
  #
  # Every part is read, and for each bar the first value found wins, but a
  # repeat start from any part counts.
  #
  # A repeat with no times plays as often as the highest ending of its
  # section names, as ABC's RepeatTagger reads it, so that a third ending
  # is reached.
  class BarlineReader < MarkReader
    BAR_STYLES = BarlineWriter::BAR_STYLES.filter_map { |style, text| [text, style] if text }.to_h.merge("regular" => :regular).freeze

    def initialize
      @styles = {}
      @starts = []
      @plays = {}
      @counted = []
      @passes = {}
      @open_endings = {}.compare_by_identity
    end

    def barline(record)
      element = record.element
      closing, opening = bars_around(record)
      repeat = repeat_of(element)
      read_style(record, element, closing, repeat)
      read_repeat(repeat, closing, opening)
      read_ending(record, element, closing, opening)
    end

    def apply(flow)
      first = flow.earliest_bar_number
      last = flow.latest_bar_number
      @starts.uniq.each { |number| bar(flow, number, first, last)&.starts_repeat = true }
      raise_plays_to_endings(first, last)
      @plays.each { |number, plays| bar(flow, number, first, last)&.ends_repeat_after_num_plays = plays }
      @passes.each { |number, passes| bar(flow, number, first, last)&.plays_on_passes = passes }
      @styles.each do |number, (style, last_bar)|
        current = bar(flow, number, first, last)
        next unless current

        current.barline = (style == :final && (last_bar || current.ends_repeat?)) ? :regular : style
      end
    end

    private

    def bars_around(record)
      number = record.bar_number
      inside = record.mid_bar? || location(record.element) == "middle"
      return [number, number + 1] if inside || location(record.element) == "right"

      [number - 1, number]
    end

    def location(element)
      XmlReading.attribute(element, "location") || "right"
    end

    def repeat_of(element)
      XmlReading.first_child(element, "repeat")
    end

    def repeat_direction(repeat)
      XmlReading.attribute(repeat, "direction")
    end

    def read_style(record, element, closing, repeat)
      style = BAR_STYLES[XmlReading.text(element, "bar-style")]
      return unless style
      return if repeat && repeat_direction(repeat) == "forward"

      last_bar = record.last? && closing == record.bar_number
      @styles[closing] ||= [style, last_bar || (repeat && repeat_direction(repeat) == "backward")]
    end

    def read_repeat(repeat, closing, opening)
      case repeat_direction(repeat)
      when "forward" then @starts << opening
      when "backward"
        @counted << closing if !@plays.key?(closing) && times(repeat)
        @plays[closing] ||= plays(repeat)
      end
    end

    def raise_plays_to_endings(first, last)
      section = []
      highest = 0
      (first..last).each do |number|
        passes = @passes[number]
        if passes.nil? || @starts.include?(number)
          section = []
          highest = 0
        end
        highest = [highest, *passes].max if passes
        section << number if @plays.key?(number) && !@counted.include?(number)
        section.each { |end_number| @plays[end_number] = [@plays[end_number], highest].max }
      end
    end

    def plays(repeat)
      times(repeat) || 2
    end

    def times(repeat)
      times = Integer(XmlReading.attribute(repeat, "times").to_s, 10, exception: false)
      times if times && times >= 2
    end

    def read_ending(record, element, closing, opening)
      ending = XmlReading.first_child(element, "ending")
      return unless ending

      case XmlReading.attribute(ending, "type")
      when "start" then start_ending(record, ending, opening)
      when "stop", "discontinue" then stop_ending(record, closing)
      end
    end

    def start_ending(record, ending, opening)
      passes = passes(XmlReading.attribute(ending, "number"))
      @open_endings[record.part] = passes && [passes, opening]
    end

    def stop_ending(record, closing)
      passes, opening = @open_endings.delete(record.part)
      return unless passes

      (opening..closing).each { |number| @passes[number] ||= passes }
    end

    def passes(numbers)
      passes = numbers.to_s.split(/[,\s]+/).reject(&:empty?).map { |number| Integer(number, 10, exception: false) }
      return if passes.empty? || passes.any? { |pass| pass.nil? || !pass.positive? } || passes.uniq.length < passes.length

      passes
    end

    def bar(flow, number, first, last)
      flow.bar(number) if number.between?(first, last)
    end
  end
end
