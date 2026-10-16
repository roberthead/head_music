module HeadMusic::MIDI
  # Checks the options, decodes the bytes, and holds the file to its budget
  # before the flow builder runs. Model constructors report a value they
  # cannot hold with one of TRANSLATED, which become ParseErrors here; every
  # other error is a bug, and escapes as itself.
  class Parser
    TRANSLATED = [ArgumentError, ZeroDivisionError, FloatDomainError, RangeError, EncodingError].freeze

    def initialize(bytes, key: nil, grid: :auto)
      raise ArgumentError, "expected a String of bytes, not #{bytes.class}" unless bytes.is_a?(String)

      @bytes = bytes
      @key = check_key(key)
      @grid = check_grid(grid)
    end

    def flow
      sequence = Reader.new(@bytes).read
      FlowBuilder.new(sequence, Budget.new(sequence).check!, key: @key, grid: @grid).flow
    rescue *TRANSLATED => error
      raise ParseError, error.message
    end

    private

    # The speller checks a key, a key name, or key regions as it would
    # spell with them.
    def check_key(key)
      HeadMusic::Analysis::PitchSpeller.new([], key: key) unless key.nil? || key == :infer
      key
    end

    def check_grid(grid)
      return grid if grid == :auto || (grid.is_a?(Rational) && grid.positive?)

      raise ArgumentError, "grid: takes :auto or a positive Rational, not #{grid.inspect}"
    end
  end
end
