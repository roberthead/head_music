require_relative "xml_reading"
require_relative "tempo_direction"

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads the tempo marks of every part's <direction>s and <sound>s, each at
  # its cursor plus its <offset>, through TempoMarkReading, once the flow's
  # meters and fermatas are set.
  #
  # The directions of a part at one moment make one mark: a <metronome> is
  # preferred over a <sound tempo>, and tempo text in any of them is its
  # text, so words and a metronome mark written apart read together. A ramp
  # word starts a ramp, and the stop of the <dashes> started beside it ends
  # it; a <sound tempo> beside a ramp or "a tempo" word only plays it.
  class TempoReader
    Moment = Data.define(:bar_number, :onset, :directions) do
      def tempo
        plain = directions.reject(&:word_kind)
        metronome = plain.filter_map(&:metronome).first
        sound = plain.filter_map(&:sound).first
        text = plain.filter_map(&:tempo_text).first
        if metronome
          HeadMusic::Rudiment::Tempo.new(metronome.beat_value, metronome.beats_per_minute, text: text)
        elsif sound
          HeadMusic::Rudiment::Tempo.new("quarter", sound, text: text, metronome_mark: text.nil?)
        elsif text
          HeadMusic::Rudiment::Tempo.for_text(text)
        end
      end

      def words
        directions.select(&:word_kind).map(&:words)
      end

      def ramp_dashes
        directions.select { |direction| direction.word_kind == :ramp }.flat_map { |direction| direction.dashes_of("start") }
      end

      def dashes_stops
        directions.flat_map { |direction| direction.dashes_of("stop") }
      end
    end

    def initialize(readings, bar_map)
      @bar_map = bar_map
      @parts = readings.map { |reading| moments(reading) }
    end

    # The tempo at the start of the first bar, the first part's winning.
    def opening
      first_bar = @bar_map.first_bar
      @parts.each do |moments|
        moment = moments.find { |candidate| candidate.bar_number == first_bar && candidate.onset.zero? && candidate.tempo }
        return moment.tempo if moment
      end
      nil
    end

    def apply(flow)
      reading = HeadMusic::Notation::TempoMarkReading.new
      @parts.each { |moments| add_part(reading, flow, moments) }
      reading.apply(flow)
    end

    private

    def add_part(reading, flow, moments)
      open_dashes = []
      moments.each do |moment|
        position = position_of(flow, moment)
        moment.dashes_stops.each { |number| reading.add_ramp_end(position) if open_dashes.delete(number) }
        tempo = moment.tempo
        reading.add(position, tempo) if tempo
        moment.words.each { |words| reading.add(position, nil, words) }
        open_dashes.concat(moment.ramp_dashes)
      end
    end

    def moments(reading)
      entries = reading.records.select { |pending| pending.kind == :direction }.filter_map { |pending| entry(reading, pending) }
      entries.group_by { |bar_number, onset, _| [bar_number, onset] }.map do |(bar_number, onset), group|
        Moment.new(bar_number, onset, group.map(&:last))
      end
    end

    # A direction whose <offset> cannot be read is skipped, as DirectionReader
    # skips it.
    def entry(reading, pending)
      index = pending.measure_index
      where = reading.where(index)
      offset = offset(pending, where)
      return unless offset

      bar_number = @bar_map.bar_number(index)
      onset = @bar_map.shift(index) + pending.cursor + offset
      [bar_number, onset.clamp(0, bar_length(bar_number)), TempoDirection.read(pending.element, **where)]
    end

    def offset(pending, where)
      element = pending.element
      text = (element.name == "direction") ? XmlReading.text(element, "offset", **where) : nil
      (text && pending.divisions) ? XmlReading.rational(text, "<offset>", **where) / (4 * pending.divisions) : 0
    rescue ParseError
      nil
    end

    def position_of(flow, moment)
      bar_number = moment.bar_number
      if bar_number == flow.last_sounding_bar_number && moment.onset >= bar_length(bar_number)
        return flow.final_barline_position
      end

      HeadMusic::Notation::BarSplitter.position_at(flow, bar_number, moment.onset)
    end

    def bar_length(bar_number)
      meter = @bar_map.meter_at(bar_number)
      Rational(meter.top_number, meter.bottom_number)
    end
  end
end
