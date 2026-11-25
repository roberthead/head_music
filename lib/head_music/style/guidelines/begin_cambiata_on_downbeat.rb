# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A nota cambiata "must begin on an accented beat", and "the first quarter of
# the measure forms a better beginning than does the third": begun on the
# third, the note after the leap falls on a downbeat, and the ear hears a
# stepwise fourth with a passing tone left out (Salzer and Schachter, p. 63).
#
# A cambiata begun on a weak beat is no cambiata, and the dissonance guideline
# marks it.
class HeadMusic::Style::Guidelines::BeginCambiataOnDownbeat < HeadMusic::Style::Guideline
  include HeadMusic::Style::Guidelines::DissonanceFigureDetection
  include HeadMusic::Style::Guideline::FigurePlacement

  strength :weak, because: "Salzer and Schachter say only that the first quarter is in general the better beginning"

  def marks
    cambiatas_from_another_accent.map { |figure| HeadMusic::Style::Mark.for_all(figure) }
  end

  private

  # Only a quarter-note dissonance, so a figure the dissonance guideline has
  # refused for its note value is not marked twice.
  def cambiatas_from_another_accent
    cambiatas.select do |figure|
      dissonance = figure[1]
      quarter_note?(dissonance) && cambiata_placed?(dissonance) && !cambiata_from_downbeat?(dissonance)
    end
  end
end
