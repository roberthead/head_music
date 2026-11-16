# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Free species lets each voice keep one texture as long as it likes, but not
# both at once: two voices moving together in one species texture for long
# is a species exercise, not free counterpoint. Marks runs of more than
# `maximum_run:` bars (default 2, Salzer and Schachter's figure for one line,
# pp. 101-102) where both voices share a single-species texture.
class HeadMusic::Style::Guidelines::IndependentTextures < HeadMusic::Style::Guideline
  include HeadMusic::Style::Guideline::BarSpan

  MAXIMUM_RUN = 2

  def marks
    return [] if notes.empty? || companion.nil?

    long_runs.flatten.map { |bar_number| mark_bar(bar_number) }
  end

  private

  def companion
    cantus_firmus
  end

  def maximum_run
    options.fetch(:maximum_run) { self.class::MAXIMUM_RUN }
  end

  # The last bar is a whole note by another rule, so it is not counted.
  def long_runs
    body_bar_numbers
      .chunk_while { |bar_number, next_bar_number| shared_texture(bar_number) == shared_texture(next_bar_number) }
      .select { |run| shared_texture(run.first) && run.length > maximum_run }
  end

  def shared_texture(bar_number)
    texture = own_textures[bar_number]
    texture if own_textures.single_species?(bar_number) && companion_textures[bar_number] == texture
  end

  def own_textures
    @own_textures ||= HeadMusic::Style::Guideline::BarTexture.new(voice)
  end

  def companion_textures
    @companion_textures ||= HeadMusic::Style::Guideline::BarTexture.new(companion)
  end
end
