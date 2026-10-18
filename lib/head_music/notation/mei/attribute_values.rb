require_relative "durations"

module HeadMusic::Notation::MEI
  # Every attribute value the reader turns into a number, a pitch letter, a
  # note value, or a choice, each read by name through READERS. A reader
  # matches a strict pattern and bounds what it reads, so "+3", "1_0",
  # "1e400", and "99999999" raise ParseError naming the element, and a value
  # MEI allows that the model has no place for raises UnsupportedFeatureError.
  # This is the only place that calls Integer() or Rational() on a value.
  module AttributeValues
    MAX_DOTS = 3
    MAX_RATE = 10_000
    MAX_COUNT = 9999
    MAX_STEPS = 96
    # Twenty places, as encoders write a float's full expansion.
    DECIMAL = /\A\d{1,9}(\.\d{1,20})?\z/

    COUNT = 1..MAX_COUNT
    STEPS = -MAX_STEPS..MAX_STEPS
    LINES = 1..10
    MODE = /\A[a-z.]{1,20}\z/
    CLEF_SHAPE = /\A(G|GG|F|C|perc|TAB)\z/
    # Octaves of displacement.
    OCTAVES_BY_DISPLACEMENT = {"8" => 1, "15" => 2, "22" => 3}.freeze
    # +1 above, -1 below.
    DISPLACEMENT_PLACES = {"above" => 1, "below" => -1}.freeze
    BOOLEANS = {"true" => true, "false" => false}.freeze

    # Each name's reader: a method, the Range of an integer, the Hash of a
    # choice, or the pattern a value is taken as it is by. A @grace's choice
    # is whether it is slashed, and a @tie says a note starts, continues, or
    # ends one.
    READERS = {
      "pname" => :letter, "pname.ges" => :letter, "key.pname" => :letter,
      "oct" => 0..9, "oct.ges" => 0..9,
      "dur" => :duration, "dur.default" => :duration, "mm.unit" => :duration,
      "dots" => :dots, "mm.dots" => :dots,
      "accid" => :accidental, "accid.ges" => :accidental,
      "keysig" => :key_signature, "key.sig" => :key_signature, "sig" => :key_signature,
      "key.mode" => MODE, "mode" => MODE,
      "meter.count" => :meter_count, "count" => :meter_count,
      "meter.unit" => :meter_unit, "unit" => :meter_unit,
      "meter.sym" => :meter_symbol, "sym" => :meter_symbol,
      "midi.bpm" => :rate, "mm" => :rate,
      "n" => COUNT, "layer" => COUNT, "staff" => :staff_list, "lines" => LINES,
      "shape" => CLEF_SHAPE, "clef.shape" => CLEF_SHAPE,
      "line" => LINES, "clef.line" => LINES,
      "dis" => OCTAVES_BY_DISPLACEMENT, "clef.dis" => OCTAVES_BY_DISPLACEMENT,
      "dis.place" => DISPLACEMENT_PLACES, "clef.dis.place" => DISPLACEMENT_PLACES,
      "midi.instrnum" => 0..127,
      "grace" => {"unacc" => true, "acc" => false, "unknown" => false}.freeze,
      "metcon" => BOOLEANS, "cue" => BOOLEANS, "tie" => /\A[imt]\z/, "tuplet" => :tuplet,
      "num" => COUNT, "numbase" => COUNT,
      "trans.diat" => STEPS, "trans.semi" => STEPS,
      "tstamp" => :tstamp, "tstamp2" => :tstamp2,
      "isodate" => :year, "startdate" => :year, "enddate" => :year
    }.freeze

    UNIT_NAMES_BY_DUR = Durations::BY_UNIT_NAME.invert.freeze
    # MEI's data.DURATION.cmn values that the model has no unit for.
    DURATIONS_WITHOUT_UNITS = %w[512 1024 2048].freeze

    SEMITONES_BY_ACCIDENTAL = {
      "s" => 1, "f" => -1, "ss" => 2, "x" => 2, "ff" => -2, "xs" => 3, "sx" => 3, "ts" => 3, "tf" => -3,
      "n" => 0, "nf" => -1, "ns" => 1
    }.freeze
    MICROTONAL_ACCIDENTALS = %w[
      su sd fu fd nu nd xu ssu 1qf 3qf 1qs 3qs bs bf bms kms bmf kmf koron sori
    ].freeze

    METERS_BY_SYMBOL = {"common" => "4/4", "cut" => "2/2"}.freeze
    METER_SYMBOLS = %w[common cut open norm].freeze

    module_function

    # The typed value of an element's attribute, or nil where it has none.
    # +where+ names the measure and staff for messages.
    def read(element, name, **options)
      where, bounds = split(options)
      value = XmlReading.attribute(element, name, element: element, **where)
      value && parse(name, value, element: element, **where, **bounds)
    end

    def parse(name, value, **options)
      where, bounds = split(options)
      reader = READERS.fetch(name)
      case reader
      when Range then bounded_integer(name, value, reader, where)
      when Hash then reader.fetch(value) { unreadable(name, value, where) }
      when Regexp then match!(name, value, reader, where)
      else send(reader, name, value, where, **bounds)
      end
    end

    def split(options)
      [options.slice(:measure, :staff, :element), options.except(:measure, :staff, :element)]
    end

    def unreadable(name, value, where)
      raise ParseError.new(%(Unreadable @#{name} "#{value.to_s[0, 40]}"), **where)
    end

    def unsupported(message, where)
      raise UnsupportedFeatureError.new(message, **where)
    end

    def match!(name, value, pattern, where)
      unreadable(name, value, where) unless value.match?(pattern)
      value
    end

    def bounded_integer(name, value, range, where)
      number = Integer(match!(name, value, /\A-?\d{1,9}\z/, where), 10)
      unreadable(name, value, where) unless range.cover?(number)
      number
    end

    # An uppercase letter name.
    def letter(name, value, where)
      match!(name, value, /\A[a-g]\z/, where).upcase
    end

    # The name of the unit a @dur is a link of.
    def duration(name, value, where)
      UNIT_NAMES_BY_DUR.fetch(value) do
        unsupported(%(A @#{name} of "#{value}" has no note value), where) if DURATIONS_WITHOUT_UNITS.include?(value)
        unreadable(name, value, where)
      end
    end

    def dots(name, value, where)
      count = Integer(match!(name, value, /\A\d{1,9}\z/, where), 10)
      unsupported("A note with #{count} dots is not supported", where) if count > MAX_DOTS
      count
    end

    # The semitones an accidental alters by.
    def accidental(name, value, where)
      SEMITONES_BY_ACCIDENTAL.fetch(value) do
        unsupported(%(The microtonal accidental "#{value}" is not supported), where) if MICROTONAL_ACCIDENTALS.include?(value)
        unreadable(name, value, where)
      end
    end

    # Sharps as positive fifths, flats as negative.
    def key_signature(name, value, where)
      unsupported("A mixed key signature is not supported", where) if value == "mixed"
      return 0 if value == "0"

      match!(name, value, /\A[1-7][sf]\z/, where)
      value.end_with?("s") ? value.to_i : -value.to_i
    end

    # A meter of added beats, such as 3+2, would read as its first number
    # alone, so it raises.
    def meter_count(name, value, where)
      unsupported(%(An additive @#{name} of "#{value[0, 40]}" is not supported), where) if value.match?(/\A\d+(\+\d+)+\z/)
      bounded_integer(name, value, COUNT, where)
    end

    def meter_unit(name, value, where)
      unit = bounded_integer(name, value, COUNT, where)
      unsupported("A @#{name} of #{unit} names no note value", where) unless HeadMusic::Rudiment::RhythmicUnit.for_denominator_value(unit)
      unit
    end

    # The meter a symbol alone implies, or nil for one that implies none.
    def meter_symbol(name, value, where)
      unreadable(name, value, where) unless METER_SYMBOLS.include?(value)
      METERS_BY_SYMBOL[value] && HeadMusic::Rudiment::Meter.get(METERS_BY_SYMBOL[value])
    end

    def rate(name, value, where)
      rational = Rational(match!(name, value, DECIMAL, where))
      unreadable(name, value, where) unless rational.positive? && rational <= MAX_RATE
      rational
    end

    # The first staff of a list such as "1 2".
    def staff_list(name, value, where)
      match!(name, value, /\A\d{1,4}( \d{1,4})*\z/, where)
      bounded_integer(name, value.split.first, COUNT, where)
    end

    # Where a note is in its tuplet, i, m, or t; a level past the first is a
    # nested tuplet.
    def tuplet(name, value, where)
      match!(name, value, /\A[imt][1-6]?\z/, where)
      unsupported("Nested tuplets are not supported", where) if value[1].to_i > 1
      value[0]
    end

    # The year an ISO date such as "1685" or "1685-03-21" names, or nil,
    # since a date the head states loosely is no reason to refuse a score.
    def year(_name, value, _where)
      match = value.match(/\A(-?\d{1,4})(-\d\d){0,2}\z/)
      match && Integer(match[1], 10)
    end

    MAX_PASS = 99

    # Passes listed as "1", "1, 2", or "1 2", or nil for text that is no
    # such list.
    def pass_list(text, where)
      return unless text.to_s.match?(/\A\s*\d{1,9}(\s*[,\s]\s*\d{1,9})*\s*\z/)

      passes(text.scan(/\d+/), text, where)
    end

    # The passes of a range such as "1-3", bounded without listing it first.
    def pass_range(text, where)
      match = text.to_s.match(/\A\s*(\d{1,9})\s*-\s*(\d{1,9})\s*\z/)
      unreadable("n", text, where) unless match
      first, last = match.captures.map { |number| Integer(number, 10) }
      unreadable("n", text, where) unless first.between?(1, last) && last <= MAX_PASS

      (first..last).to_a
    end

    def passes(numbers, text, where)
      passes = numbers.map { |number| Integer(number, 10) }.uniq
      unreadable("n", text, where) unless passes.all? { |pass| pass.between?(1, MAX_PASS) }
      passes
    end

    # The exact beat, from 0 to one past the meter's count.
    def tstamp(name, value, where, count:)
      beat = Rational(match!(name, value, DECIMAL, where))
      unreadable(name, value, where) unless beat <= count + 1
      beat
    end

    # [bars later, beat there], the bars no more than +bars_left+.
    def tstamp2(name, value, where, bars_left:, count:)
      match = value.match(/\A(\d{1,9})m\+(.+)\z/)
      unreadable(name, value, where) unless match
      bars = Integer(match[1], 10)
      unreadable(name, value, where) unless bars <= bars_left

      [bars, tstamp(name, match[2], where, count: count)]
    end
  end
end
