require_relative "fermata_reader"

module HeadMusic::Notation::MEI
  # Reads <tempo> into the flow's tempo changes, ramps, and "a tempo"
  # points, once the fermatas are read, by TempoMarkReading's rule. A <tempo
  # func="continuous"> is a ramp from its start to its @tstamp2 or @endid,
  # toward the numbered <tempo> at its end, if any; one with no end ends as a
  # ramp word does. A <tempo> with no @tstamp or @startid stands at the start
  # of its measure, which in the second half of a split bar is mid-bar, so it
  # is dropped.
  class TempoMarkReader < MarkReader
    Ramp = Data.define(:from, :to, :text)

    def initialize(anchors)
      super
      @reading = HeadMusic::Notation::TempoMarkReading.new
      @ramps = []
      @tempos = []
      @split = false
    end

    def measure(record)
      @measure_start = !@split
      @split = record.mid_bar
    end

    def control(record)
      element = record.element
      return unless element.name == "tempo"

      position = start_of(record)
      return unless position

      text = anchors.text(element)
      if TempoReading.continuous?(element, measure: record.measure)
        ramp(record, position, text)
      else
        @tempos << [position, TempoReading.tempo(element, text, measure: record.measure)]
      end
    end

    def apply(flow)
      @tempos = @tempos.map { |position, tempo| [position.is_a?(Integer) ? flow.position(position, 1, 0, 0) : position, tempo] }
      @ramps.each { |ramp| add_ramp(flow, ramp) }
      final_barline = flow.final_barline_position
      @tempos.each { |position, tempo| @reading.add(position, tempo) if tempo && position < final_barline }
      @reading.apply(flow)
    end

    private

    # A position, or the number of the bar whose downbeat it is.
    def start_of(record)
      return record.start.position if record.start
      return if %w[tstamp startid].any? { |name| attribute_of(record, name) }

      record.bar_number if @measure_start
    end

    def ramp(record, position, text)
      text = nil if text.empty?
      if record.finish
        @ramps << Ramp.new(position, record.finish.position, text)
      else
        @reading.add(position, nil, text)
      end
    end

    # The ramp's target is a numbered tempo where it ends.
    def add_ramp(flow, ramp)
      target = @tempos.find { |position, tempo| position.to_a == ramp.to.to_a && tempo&.metronome_mark? }&.last
      flow.add_tempo_ramp(from: ramp.from, to: ramp.to, to_tempo: target, text: ramp.text)
    rescue ArgumentError
      nil
    end
  end
end

HeadMusic::Notation::MEI::MARK_READERS << HeadMusic::Notation::MEI::TempoMarkReader
