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
      .select { |run| bar_texture.single_species?(run.first) && run.length > maximum_run }
  end

  def texture(bar_number)
    bar_texture[bar_number]
  end

  def bar_texture
    @bar_texture ||= HeadMusic::Style::Guideline::BarTexture.new(voice)
  end
end
