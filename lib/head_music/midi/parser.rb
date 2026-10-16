module HeadMusic::MIDI
  # Checks the options, decodes the bytes, and holds the file to its budget
  # before the flow builder runs. Model constructors report a value they
  # cannot hold with one of TRANSLATED, which the flow builder raises as
  # ParseErrors while it builds the flow; every other error is a bug, and
  # escapes as itself.
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
    end

    private

    # The speller checks a key, a key name, or key regions as it would
    # spell with them.
    def check_key(key)
      HeadMusic::Analysis::PitchSpeller.new([], key: key) unless key.nil? || key == :infer
      key
    end

    def check_grid(grid)
      Quantizer.check_grid(grid)
    end
  end
end
