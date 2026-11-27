module HeadMusic::Style; end

class HeadMusic::Style::Guideline
  # Where a nota cambiata or a double neighbor falls in the bar, and the note
  # values its dissonances take. A double neighbor "must begin on the first
  # beat of the measure", and a cambiata "on an accented beat" (Salzer and
  # Schachter, pp. 62-63).
  #
  # A figure's beginning is read from its dissonant note, not from where its
  # first note was attacked, so a first note tied over the barline does not
  # move the figure.
  module FigurePlacement
    HALF_NOTE = HeadMusic::Rudiment::RhythmicDuration.get(:half)

    private

    # With quarter_dissonances, the figure's dissonant notes must be quarter
    # notes: a dissonant half note may only pass, and an eighth may not be
    # left by leap (Salzer and Schachter, pp. 103-105).
    def leaping_figure?(figures, note, quarter_dissonances:)
      placed_cambiata_dissonance?(figures, note, quarters: quarter_dissonances) ||
        placed_double_neighbor_member?(figures, note, quarters: quarter_dissonances)
    end

    def placed_cambiata_dissonance?(figures, note, quarters:)
      figures.cambiata_dissonance?(note) && cambiata_placed?(note) && (!quarters || quarter_note?(note))
    end

    def placed_double_neighbor_member?(figures, note, quarters:)
      figures.double_neighbors_with(note).any? { |figure| recognized_double_neighbor?(figures, figure, quarters: quarters) }
    end

    def recognized_double_neighbor?(figures, figure, quarters:)
      double_neighbor_placed?(figure) && (!quarters || figures.dissonant_among(figure).all? { |neighbor| quarter_note?(neighbor) })
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

    def quarter_note?(note)
      note.rhythmic_duration == :quarter
    end

    def half_note_or_longer?(note)
      note.rhythmic_duration >= HALF_NOTE
    end
  end
end
