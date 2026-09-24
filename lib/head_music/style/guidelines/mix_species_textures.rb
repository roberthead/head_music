# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Fifth species is the free mixture of the other four, so no one of their
# textures may run on: Salzer and Schachter allow "two, or at most,
# two-and-a-half measures of a single note value" (pp. 101-102). Configurable
# via the `maximum_run:` option.
#
# Strong, although MostlyConjunct's precedent makes a proportion weak: a
# proportion of steps measures the character of a line that is already some
# species, while a run of one texture decides whether the line is fifth
# species at all.
class HeadMusic::Style::Guidelines::MixSpeciesTextures < HeadMusic::Style::Guideline
  include HeadMusic::Style::Guideline::BarSpan

  MAXIMUM_RUN = 2
  SINGLE_SPECIES_TEXTURES = %i[whole half quarter ligature].freeze

  def marks
    return [] if notes.empty?

    long_runs.flatten.map { |bar_number| mark_bar(bar_number) }
  end

  private

  def maximum_run
    options.fetch(:maximum_run) { self.class::MAXIMUM_RUN }
  end

  # The last bar is a whole note by another rule, so it is not counted.
  def long_runs
    body_bar_numbers
      .chunk_while { |bar_number, next_bar_number| texture(bar_number) == texture(next_bar_number) }
      .select { |run| SINGLE_SPECIES_TEXTURES.include?(texture(run.first)) && run.length > maximum_run }
  end

  def texture(bar_number)
    @textures ||= {}
    @textures[bar_number] ||= classify(bar_number)
  end

  # A mixed bar is florid; an empty bar is the rest rules' fault. Either one
  # ends a run without counting toward one.
  def classify(bar_number)
    tail = tail_into(bar_number)
    attacks = notes_in_bar(bar_number)
    return tail ? tail_texture(tail, attacks, bar_number) : :empty if attacks.empty?
    return tail_texture(tail, attacks, bar_number) if tail

    attack_texture(attacks, bar_number)
  end

  def tail_into(bar_number)
    downbeat = downbeat_of(bar_number)
    held = voice.note_at(downbeat)
    held if held && held.position < downbeat
  end

  def tail_texture(tail, attacks, bar_number)
    return :whole if attacks.empty? && tail.next_position >= downbeat_of(bar_number + 1)
    return :ligature if attacks.any? && attacks.all? { |note| undotted?(note, "half") }

    :florid
  end

  # A note that fills its bar is the first-species texture however it is
  # notated, so the dotted whole of a triple-meter cantus counts.
  def attack_texture(attacks, bar_number)
    return :whole if attacks.one? && fills_bar?(attacks.first, bar_number)
    return :half if attacks.all? { |note| undotted?(note, "half") }
    return :quarter if attacks.all? { |note| undotted?(note, "quarter") || undotted?(note, "eighth") }

    :florid
  end

  def fills_bar?(note, bar_number)
    note.position == downbeat_of(bar_number) && note.next_position >= downbeat_of(bar_number + 1)
  end

  def undotted?(note, unit_name)
    note.rhythmic_value.unit_name == unit_name && note.rhythmic_value.dots.zero?
  end
end
