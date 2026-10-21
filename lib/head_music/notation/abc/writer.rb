# Parses and renders ABC notation as HeadMusic::Content flows
module HeadMusic::Notation::ABC
  # Renders a flow as an ABC tune string. Whole-flow problems raise before any
  # string assembly, so callers never receive a truncated tune. A repeat played
  # more than twice is written as a plain ":|", which ABC reads back as two
  # plays unless its endings name more passes.
  class Writer
    # A fixed unit note length keeps the L: field and the duration
    # multiplier arithmetic in sync.
    UNIT_NOTE_LENGTH = Rational(1, 8)
    BARS_PER_LINE = 4
    METER_SYMBOLS = {common: "C", cut: "C|"}.freeze
    # A tune with no Q: field reads at this tempo.
    DEFAULT_TEMPO = HeadMusic::Rudiment::Tempo.new("quarter", 120)

    attr_reader :flow, :reference_number, :transposed

    def self.meter_value(meter)
      METER_SYMBOLS.fetch(meter.symbol, meter.to_s)
    end

    def initialize(flow, reference_number: 1, transposed: false)
      @flow = flow
      @reference_number = reference_number
      @transposed = transposed
    end

    def to_s
      validate!
      (header_lines + body_lines).join("\n") + "\n"
    end

    private

    def validate!
      RenderPreflight.check!(flow, transposed: transposed)
      voice_writer&.validate!
    end

    def plan
      @plan ||= RenderPlan.new(flow, transposed: transposed)
    end

    def voice_writer
      voice = flow.voices.first
      @voice_writer ||= voice && VoiceWriter.new(voice, plan)
    end

    def header_lines
      [
        "X:#{reference_number}",
        "T:#{flow.name}",
        optional_field("C", flow.composer),
        optional_field("O", flow.origin),
        "M:#{self.class.meter_value(flow.meter)}",
        unit_note_length_field,
        tempo_field,
        key_field
      ].compact
    end

    def optional_field(letter, value)
      "#{letter}:#{value}" if value
    end

    def tempo_field
      tempo = flow.timeline.opening_tempo
      "Q:#{TempoField.write(tempo)}" unless tempo == DEFAULT_TEMPO
    end

    def unit_note_length_field
      "L:#{UNIT_NOTE_LENGTH.numerator}/#{UNIT_NOTE_LENGTH.denominator}"
    end

    # The parser requires K: to terminate the header. No %%transpose directive
    # is emitted: the pitches are already written, and abcm2ps would move them
    # a second time.
    def key_field
      "K:#{plan.first_measure_key(flow.voices.first&.part || flow.parts.first)}"
    end

    def body_lines
      bars = voice_writer ? voice_writer.bars : []
      bars.each_slice(BARS_PER_LINE).map(&:join)
    end
  end
end
