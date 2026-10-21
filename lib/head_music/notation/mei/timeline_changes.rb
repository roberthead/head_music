module HeadMusic::Notation::MEI
  # What changes after the opening bar: a <scoreDef> before a bar whose key or
  # meter changes, its symbol included, and a <staffDef> before a bar where a
  # staff's clef, written key, or instrument changes; TempoControls writes the
  # tempos. In a transposed render a staff states its own written key wherever
  # it differs from the score's, and its trans.* from the opening on.
  class TimelineChanges
    def initialize(plan)
      @plan = plan
    end

    def staff_def_attributes(entry)
      return {} unless plan.transposed?

      key = plan.first_measure_key(entry.part)
      {
        "keysig" => (key == plan.first_measure_key) ? nil : key,
        **transposition_attributes(entry.part.instrument_at(first_bar))
      }
    end

    def pre_measure_elements
      later_bars.flat_map do |bar_number|
        elements = [score_def_element(bar_number), *plan.staff_entries.map { |entry| staff_def_element(entry, bar_number) }]
        elements.compact.map { |element| BarElement.new(bar_number, element) }
      end
    end

    private

    attr_reader :plan

    def ids
      plan.ids
    end

    def first_bar
      plan.bar_numbers.first
    end

    def later_bars
      plan.bar_numbers.select { |bar_number| later_bar?(bar_number) }
    end

    def later_bar?(bar_number)
      bar_number > first_bar && plan.bar_numbers.cover?(bar_number)
    end

    def score_def_element(bar_number)
      key = plan.measure_key_changes[bar_number]
      meter = plan.measure_time_changes[bar_number]
      return unless key || meter

      attributes = {
        "keysig" => key, "key.mode" => key && plan.key_mode_change(bar_number),
        "meter.count" => meter&.top_number, "meter.unit" => meter&.bottom_number, "meter.sym" => meter&.symbol&.to_s
      }
      Element.new("scoreDef", ids.container("scoredef", ids.bar_key(bar_number)), attributes)
    end

    def staff_def_element(entry, bar_number)
      key = ids.staff_key(bar_number, entry.number)
      changes_instrument = instrument_changes(entry.part).key?(bar_number)
      attributes = {
        "keysig" => staff_key_signature(entry.part, bar_number),
        **(changes_instrument ? changed_transposition_attributes(entry.part, bar_number) : {})
      }.compact
      children = [
        ScoreDefWriter.clef_element(ids, key, clef_changes(entry.staff)[bar_number]),
        (ScoreDefWriter.instr_def_element(ids, key, entry.part.instrument_at(bar_number)) if changes_instrument)
      ].compact
      return if attributes.empty? && children.empty?

      Element.new("staffDef", ids.container("staffdef", key), {"n" => entry.number, **attributes}, children)
    end

    # A score-wide key change resets every staff, so a staff restates its key
    # only where it differs, or where its key changes with no score-wide change.
    def staff_key_signature(part, bar_number)
      return unless plan.transposed?

      key = plan.measure_key_changes(part)[bar_number]
      score_key = plan.measure_key_changes[bar_number]
      key if key && key != score_key
    end

    # A change back to an instrument in C states 0/0, since trans.* stays in
    # force until another replaces it.
    def changed_transposition_attributes(part, bar_number)
      return {} unless plan.transposed?

      reset = part.instrument_at(bar_number - 1)&.sounding_transposition.to_i.nonzero?
      transposition_attributes(part.instrument_at(bar_number), reset: reset)
    end

    # MEI's trans.* state sounding = written + trans, octaves included, as the
    # instrument catalog states its sounding_transposition.
    def transposition_attributes(instrument, reset: false)
      semitones = instrument&.sounding_transposition.to_i
      return {} if semitones.zero? && !reset

      diatonic = HeadMusic::Content::Layout::Transposition.for_semitones(semitones).diatonic_steps
      {"trans.diat" => diatonic, "trans.semi" => semitones}
    end

    def clef_changes(staff)
      @clef_changes ||= {}.compare_by_identity
      @clef_changes[staff] ||= staff.clef_changes
    end

    def instrument_changes(part)
      @instrument_changes ||= {}.compare_by_identity
      @instrument_changes[part] ||= part.instrument_changes
    end
  end

  SectionWriter.pre_measure_sources << TimelineChanges
  ScoreDefWriter.staff_def_attribute_sources << TimelineChanges
end
