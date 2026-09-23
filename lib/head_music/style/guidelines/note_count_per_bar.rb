# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Checks that each middle bar (not first or last) contains an exact number of
# notes of a given rhythmic value. Configurable via the `count:` and
# `rhythmic_value:` options; subclasses may set COUNT and RHYTHMIC_VALUE defaults.
# Judged over the voice's own bars, as SustainAcrossBarlines is, so a solo line
# is held to it too.
class HeadMusic::Style::Guidelines::NoteCountPerBar < HeadMusic::Style::Guideline
  def marks
    return [] if notes.empty?

    middle_bars.filter_map { |bar_number| check_middle_bar(bar_number) }
  end

  # One template for all four subclasses: they differ by count and unit, not by
  # sentence. Named explicitly so the subclasses do not each need an entry.
  def self.template_key = "note_count_per_bar"

  def self.template_values(config)
    count = config.fetch(:count) { self::COUNT }
    unit = config.fetch(:rhythmic_value) { self::RHYTHMIC_VALUE }
    {
      count: count,
      number: HeadMusic::Style::Template.number_word(count),
      # Pluralized because British names the value with a noun and drops the
      # "note" the American sentence carries: four crotchets, not four crotchet
      # notes. English's entries stay scalar, which I18n reads past the count.
      rhythmic_unit: HeadMusic::Style::Template.pluralize(
        "rhythmic_units.#{unit}", count: count, scope: HeadMusic::Style::Template::RUDIMENT_SCOPE
      )
    }
  end

  private

  def count
    options.fetch(:count) { self.class::COUNT }
  end

  def rhythmic_unit
    options.fetch(:rhythmic_value) { self.class::RHYTHMIC_VALUE }
  end

  def rhythmic_value
    @rhythmic_value ||= HeadMusic::Rudiment::RhythmicValue.get(rhythmic_unit)
  end

  def check_middle_bar(bar_number)
    bar_notes = notes_in_bar(bar_number)
    return if bar_notes.length == count && bar_notes.all? { |note| note.rhythmic_value == rhythmic_value }

    mark_bar(bar_number)
  end

  def middle_bars
    first = notes.first.position.bar_number
    last = notes.last.position.bar_number
    ((first + 1)...last).to_a
  end

  def notes_in_bar(bar_number)
    notes.select { |note| note.position.bar_number == bar_number }
  end

  def downbeat_of(bar_number)
    HeadMusic::Content::Position.new(flow, "#{bar_number}:1")
  end

  def mark_bar(bar_number)
    bar_notes = notes_in_bar(bar_number)
    return HeadMusic::Style::Mark.for_all(bar_notes) if bar_notes.any?

    HeadMusic::Style::Mark.new(downbeat_of(bar_number), downbeat_of(bar_number + 1))
  end
end
