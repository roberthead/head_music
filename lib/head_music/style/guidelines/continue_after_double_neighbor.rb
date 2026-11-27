# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A double neighbor decorates one tone and risks "becoming a static area,
# detached from the line as a whole", unless the line steps on in the
# direction of the figure's last step (Salzer and Schachter, pp. 60-62).
class HeadMusic::Style::Guidelines::ContinueAfterDoubleNeighbor < HeadMusic::Style::Guideline
  include HeadMusic::Style::Guidelines::DissonanceFigureDetection
  include HeadMusic::Style::Guideline::FigurePlacement

  strength :weak, because: "Salzer and Schachter call the other continuations less good rather than wrong"

  def marks
    stalled_exits.map { |exit| HeadMusic::Style::Mark.for_all(exit) }
  end

  private

  def stalled_exits
    recognized_double_neighbors.filter_map do |figure|
      closing = figure.last
      following = notes[notes.index(closing) + 1]
      [closing, following] if following && !continues?(figure, following)
    end
  end

  # Only the figures the dissonance guidelines accept in every species, so a
  # shape they have refused is not then graded as a double neighbor.
  def recognized_double_neighbors
    double_neighbors.select { |figure| recognized_double_neighbor?(dissonance_figures, figure, quarters: true) }
  end

  def continues?(figure, following)
    last_step = HeadMusic::Analysis::MelodicInterval.new(*figure.last(2))
    departure = HeadMusic::Analysis::MelodicInterval.new(figure.last, following)
    departure.step? && departure.direction == last_step.direction
  end
end
