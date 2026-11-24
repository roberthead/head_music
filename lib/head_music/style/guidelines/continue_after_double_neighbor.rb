# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# A double neighbor decorates one tone and risks "becoming a static area,
# detached from the line as a whole", unless the line steps on in the
# direction of the figure's last step (Salzer and Schachter, pp. 60-62).
class HeadMusic::Style::Guidelines::ContinueAfterDoubleNeighbor < HeadMusic::Style::Guideline
  include HeadMusic::Style::Guidelines::DissonanceFigureDetection

  strength :weak, because: "Salzer and Schachter call the other continuations less good rather than wrong"

  def marks
    return [] unless cantus_firmus&.notes&.any?

    stalled_exits.map { |exit| HeadMusic::Style::Mark.for_all(exit) }
  end

  private

  def stalled_exits
    double_neighbors.filter_map do |figure|
      closing = figure.last
      following = notes[notes.index(closing) + 1]
      [closing, following] if following && !continues?(figure, following)
    end
  end

  def continues?(figure, following)
    last_step = HeadMusic::Analysis::MelodicInterval.new(*figure.last(2))
    departure = HeadMusic::Analysis::MelodicInterval.new(figure.last, following)
    departure.step? && departure.direction == last_step.direction
  end
end
