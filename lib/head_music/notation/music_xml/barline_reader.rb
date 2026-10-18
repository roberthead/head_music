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
      @starts = {}
      @plays = {}
      @counted = []
      @passes = {}
      @open_endings = {}.compare_by_identity
    end

    def barline(record)
      element = record.element
      closing, opening = bars_around(record)
      repeat = XmlReading.first_child(element, "repeat")
      direction = XmlReading.attribute(repeat, "direction")
      read_style(record, closing, direction)
      read_repeat(repeat, direction, closing, opening)
      read_ending(record, closing, opening)
    end

    def apply(flow)
      numbers = flow.earliest_bar_number..flow.latest_bar_number
      raise_plays_to_endings(numbers)
      each_bar(flow, numbers, @starts) { |bar, _| bar.starts_repeat = true }
      each_bar(flow, numbers, @plays) { |bar, plays| bar.ends_repeat_after_num_plays = plays }
      each_bar(flow, numbers, @passes) { |bar, passes| bar.plays_on_passes = passes }
      each_bar(flow, numbers, @styles) do |bar, (style, last_bar)|
        bar.barline = (style == :final && (last_bar || bar.ends_repeat?)) ? :regular : style
      end
    end

    private

    def bars_around(record)
      number = record.bar_number
      location = XmlReading.attribute(record.element, "location") || "right"
      return [number, number + 1] if record.mid_bar? || %w[middle right].include?(location)

      [number - 1, number]
    end

    def read_style(record, closing, direction)
      style = BAR_STYLES[XmlReading.text(record.element, "bar-style")]
      return if style.nil? || direction == "forward"

      last_bar = record.last? && closing == record.bar_number
      @styles[closing] ||= [style, last_bar || direction == "backward"]
    end

    def read_repeat(repeat, direction, closing, opening)
      case direction
      when "forward" then @starts[opening] = true
      when "backward"
        @counted << closing if !@plays.key?(closing) && times(repeat)
        @plays[closing] ||= times(repeat) || 2
      end
    end

    # A section runs from a repeat start or a bar outside any ending, and
    # each repeat end in it without times plays as often as its highest pass.
    def raise_plays_to_endings(numbers)
      numbers.slice_before { |number| !@passes.key?(number) || @starts.key?(number) }.each do |section|
        highest = section.flat_map { |number| @passes.fetch(number, []) }.max || 0
        section.each { |number| @plays[number] = [@plays[number], highest].max if @plays.key?(number) && !@counted.include?(number) }
      end
    end

    def times(repeat)
      times = Integer(XmlReading.attribute(repeat, "times").to_s, 10, exception: false)
      times if times && times >= 2
    end

    def read_ending(record, closing, opening)
      ending = XmlReading.first_child(record.element, "ending")
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
      passes if passes.any? && passes.all? { |pass| pass&.positive? } && passes.uniq == passes
    end

    def each_bar(flow, numbers, values)
      values.each { |number, value| yield flow.bar(number), value if numbers.cover?(number) }
    end
  end
end
