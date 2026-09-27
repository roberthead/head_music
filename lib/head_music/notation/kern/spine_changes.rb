# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Reads the interpretations a kern spine states after the first data row.
  #
  # A clef change and a staff crossing both live on bars, so each takes
  # effect at a downbeat. A spine's part, instrument, and name may only be
  # restated as they were declared.
  class SpineChanges
    def initialize(voices:, parts:, tags:, clock:)
      @voices = voices
      @parts = parts
      @tags = tags
      @clock = clock
    end

    def read(interpretations, time, line)
      @time = time
      @line = line
      @row_clefs = {}
      interpretations.each { |track, interpretation| change(track, interpretation) }
    end

    private

    attr_reader :clock, :line

    def change(track, interpretation)
      layer = @voices.layer(track)
      case interpretation.kind
      when :clef then change_clef(layer.staff, interpretation)
      when :staff then change_staff(layer, interpretation)
      when :part then ensure_unchanged(@tags.fetch(track).part, interpretation)
      when :code, :name then ensure_unchanged(@parts.declared(layer.voice.part, interpretation.kind), interpretation)
      end
    end

    def change_clef(staff, interpretation)
      clef = interpretation.value
      return if clef.nil?

      ensure_one_clef(staff, clef)
      return if staff.clef_at(clock.in_force_number) == clef

      clock.at_downbeat(@time, interpretation.field, line) do |bar_number|
        staff.change_clef(bar_number, clef) unless staff.clef_at(bar_number) == clef
      end
    end

    def ensure_one_clef(staff, clef)
      stated = @row_clefs[staff]
      @row_clefs[staff] = clef
      return if stated.nil? || stated == clef

      raise UnsupportedFeatureError.new("Spines on one staff disagree on its clef", line_number: line)
    end

    def change_staff(layer, interpretation)
      staff = @parts.staff(layer.voice.part, interpretation.value)
      unless staff
        raise UnsupportedFeatureError.new("#{interpretation.field} is not a staff of its spine's part", line_number: line)
      end
      return if staff.equal?(layer.staff)

      layer.staff = staff
      clock.at_downbeat(@time, interpretation.field, line) do |bar_number|
        layer.voice.assign_staff(bar_number, staff)
      end
    end

    def ensure_unchanged(value, interpretation)
      return if value == interpretation.value

      raise UnsupportedFeatureError.new(
        "Changing #{interpretation.field} in the middle of a spine is not supported", line_number: line
      )
    end
  end
end
