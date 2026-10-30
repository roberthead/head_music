# A module for musical analysis
module HeadMusic::Analysis; end

# The unspelled notes the key finder and the pitch speller read, and the bars
# they fall in. Bar starts map each bar number to its downbeat onset, in order;
# a bar lasts until the next one starts, and the last until the input ends.
#
# Without a flow, +bars:+ lists the downbeat onsets, numbered from
# +first_bar:+; +meter:+ alone gives uniform bars; with neither, the whole
# input is one bar. A tuple's onset may be a "bar:count" string when +meter:+
# is given.
#
# Read from a flow, each note has an address: the path to its sound in
# flow.to_h, so that hash.dig(*address) is its pitch string.
class HeadMusic::Analysis::NoteInput
  UnspelledNote = HeadMusic::Analysis::UnspelledNote
  BAR_COUNT = /\A\s*(-?\d+):(\d+)\s*\z/

  attr_reader :notes, :bar_starts, :addresses, :flow

  def self.for(input, meter: nil, bars: nil, first_bar: 1)
    return input if input.is_a?(self)

    if input.is_a?(HeadMusic::Content::Flow)
      raise ArgumentError, "a flow carries its own bars; pass neither meter: nor bars:" if meter || bars

      return FlowReader.new(input).note_input
    end

    from_list(input, meter: meter, bars: bars, first_bar: first_bar)
  end

  def self.from_list(input, meter:, bars:, first_bar:)
    meter = HeadMusic::Rudiment::Meter.get(meter) if meter
    raise ArgumentError, "meter: #{meter} has bars of no length" if meter && !bar_length(meter).positive?
    listed_starts = bars && listed_bar_starts(bars, first_bar)
    notes = Array(input).map { |element| note_from(element, meter, listed_starts, first_bar) }
    new(notes, listed_starts || computed_bar_starts(notes, meter, first_bar))
  end

  def self.note_from(element, meter, listed_starts, first_bar)
    return element if element.is_a?(UnspelledNote)
    raise ArgumentError, "expected an UnspelledNote or a tuple, got #{element.inspect}" unless element.is_a?(Array)

    number, onset, duration, voice = element
    UnspelledNote.new(
      number: number,
      onset: onset_from(onset, meter, listed_starts, first_bar),
      duration: duration_from(duration),
      voice: voice
    )
  end

  def self.onset_from(onset, meter, listed_starts, first_bar)
    return onset.to_r unless onset.is_a?(String)

    match = BAR_COUNT.match(onset)
    raise ArgumentError, "unreadable onset #{onset.inspect}; use \"bar:count\"" unless match
    raise ArgumentError, "a \"bar:count\" onset needs meter:" unless meter

    bar_number = match[1].to_i
    if listed_starts && !listed_starts.key?(bar_number)
      raise ArgumentError, "the onset #{onset.inspect} names bar #{bar_number}, which bars: does not list"
    end

    downbeat = listed_starts ? listed_starts[bar_number] : (bar_number - first_bar) * bar_length(meter)
    downbeat + Rational(match[2].to_i - 1, meter.bottom_number)
  end

  def self.duration_from(duration)
    return duration.to_r if duration.is_a?(Numeric)

    rhythmic_duration = HeadMusic::Rudiment::RhythmicDuration.get(duration)
    raise ArgumentError, "unknown duration #{duration.inspect}" unless rhythmic_duration

    rhythmic_duration.fraction
  end

  def self.listed_bar_starts(bars, first_bar)
    starts = Array(bars).map(&:to_r)
    raise ArgumentError, "bars: needs at least one downbeat" if starts.empty?
    raise ArgumentError, "bars: must be strictly increasing" unless starts.each_cons(2).all? { |a, b| a < b }

    starts.each_with_index.to_h { |start, index| [first_bar + index, start] }
  end

  def self.computed_bar_starts(notes, meter, first_bar)
    return {first_bar => 0r} unless meter

    length = bar_length(meter)
    finish = notes.map { |note| note.onset + note.duration }.max || 0
    count = [(finish / length).ceil, 1].max
    (0...count).to_h { |index| [first_bar + index, index * length] }
  end

  def self.bar_length(meter)
    Rational(meter.top_number, meter.bottom_number)
  end

  private_class_method :from_list, :note_from, :onset_from, :duration_from,
    :listed_bar_starts, :computed_bar_starts, :bar_length

  def initialize(notes, bar_starts, flow: nil, addresses: nil)
    @notes = notes.freeze
    @bar_starts = bar_starts.freeze
    @flow = flow
    @addresses = (addresses || Array.new(notes.length)).freeze
    @bar_numbers = bar_starts.keys
    @bar_onsets = bar_starts.values
  end

  # The bar sounding at an onset. An onset before the first downbeat is in
  # the first bar.
  def bar_at(onset)
    following = @bar_onsets.bsearch_index { |start| start > onset }
    return @bar_numbers.last if following.nil?
    return @bar_numbers.first if following.zero?

    @bar_numbers[following - 1]
  end
end
