module HeadMusic::Style; end

class HeadMusic::Style::Guideline
  # Where a nota cambiata or a double neighbor falls in the bar. A double
  # neighbor "must begin on the first beat of the measure", and a cambiata
  # "on an accented beat" (Salzer and Schachter, pp. 62-63).
  #
  # A figure's beginning is read from its dissonant note, not from where its
  # first note was attacked, so a first note tied over the barline does not
  # move the figure.
  module FigurePlacement
    private

    def leaping_figure?(figures, note)
      placed_cambiata_dissonance?(figures, note) || placed_double_neighbor_member?(figures, note)
    end

    def placed_cambiata_dissonance?(figures, note)
      figures.cambiata_dissonance?(note) && cambiata_placed?(note)
    end

    def placed_double_neighbor_member?(figures, note)
      figures.double_neighbors_with(note).any? { |figure| double_neighbor_placed?(figure) }
    end

    def cambiata_placed?(dissonance)
      !accented_onset(dissonance).nil?
    end

    def cambiata_from_downbeat?(dissonance)
      onset = accented_onset(dissonance)
      !onset.nil? && downbeat_position?(onset)
    end

    def double_neighbor_placed?(figure)
      onset = accented_onset(figure[1])
      !onset.nil? && downbeat_position?(onset) && figure.last.position.bar_number == onset.bar_number
    end

    # The strong beat in the note's bar from which one of the note's own value
    # reaches the note. Found forwards, since a position does not subtract
    # across a barline.
    def accented_onset(note)
      position = note.position
      (1..position.meter.counts_per_bar)
        .map { |count| HeadMusic::Content::Position.new(position.flow, position.bar_number, count, 0) }
        .select(&:strong?)
        .detect { |beat| beat + note.rhythmic_duration == position }
    end
  end
end
