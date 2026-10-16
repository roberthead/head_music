module HeadMusic::Notation::MEI
  # Reads barline styles, repeats, endings, and repeat counts onto the bars.
  # The barline between two measures is the first one's @right and the
  # second one's @left; it closes the bar before the second measure's and
  # opens that bar, or, where it falls inside a bar, closes that bar and
  # opens the next, as the MusicXML reader places a mid-bar repeat. For each
  # bar the first style found wins, and a final barline on the last bar
  # stays regular, as MEI Export writes a regular one there.
  #
  # A <dir> reading "×N" or "xN" at a repeat's end sets its count, up to
  # the most passes an <ending> may name. A repeat with none plays as often
  # as the highest ending of its section names, as the MusicXML reader
  # counts it, so that a third ending is reached.
  class BarlineReader < MarkReader
    STYLES = {"single" => :regular, "dbl" => :double, "end" => :final, "dashed" => :dashed, "dotted" => :dotted}.freeze
    PLAYS = /\A[×x]\s*(\d{1,9})\z/i

    def initialize(anchors)
      super
      @styles = {}
      @starts = {}
      @ends = {}
      @plays = {}
      @passes = {}
      @previous = nil
    end

    def measure(record)
      closing = record.bar_number - (@previous&.mid_bar? ? 0 : 1)
      finish(@previous, closing) if @previous
      read_barline(attribute(record, "left"), closing, last_bar: false)
      @previous = record
    end

    def control(record)
      return unless record.element.name == "dir"

      plays = PLAYS.match(anchors.text(record.element))&.[](1)&.to_i
      @plays[bar_of(record)] ||= plays if plays&.between?(2, AttributeValues::MAX_PASS)
    end

    def apply(flow)
      finish(@previous, @previous.bar_number) if @previous
      first = flow.earliest_bar_number
      last = flow.latest_bar_number
      bar = ->(number) { flow.bar(number) if number.between?(first, last) }
      @starts.each_key { |number| bar[number]&.starts_repeat = true }
      repeat_plays(first, last).each { |number, plays| bar[number]&.ends_repeat_after_num_plays = plays }
      @passes.each { |number, passes| bar[number]&.plays_on_passes = passes }
      @styles.each { |number, style| bar[number]&.barline = style }
    end

    private

    def finish(record, closing)
      (record.bar_number..closing).each { |number| @passes[number] ||= record.ending_passes } if record.ending_passes
      read_barline(attribute(record, "right"), closing, last_bar: record.last?)
    end

    def read_barline(value, closing, last_bar:)
      case value
      when "rptstart" then @starts[closing + 1] = true
      when "rptend" then @ends[closing] = true
      when "rptboth"
        @ends[closing] = true
        @starts[closing + 1] = true
      else
        style = STYLES[value]
        @styles[closing] ||= style if style && !(style == :final && last_bar)
      end
    end

    def repeat_plays(first, last)
      plays = {}
      section = []
      highest = 2
      (first..last).each do |number|
        passes = @passes[number]
        if passes.nil? || @starts.key?(number)
          section = []
          highest = 2
        end
        highest = [highest, *passes].max if passes
        section << number if @ends.key?(number)
        section.each { |end_number| plays[end_number] = @plays[end_number] || highest }
      end
      plays
    end

    def attribute(record, name)
      XmlReading.attribute(record.element, name, measure: record.measure, element: record.element)
    end

    # Ids place a control at its event's bar; beats, at its measure's.
    def bar_of(record)
      record.start&.event? ? record.start.bar_number : record.bar_number
    end
  end
end

HeadMusic::Notation::MEI::MARK_READERS << HeadMusic::Notation::MEI::BarlineReader
