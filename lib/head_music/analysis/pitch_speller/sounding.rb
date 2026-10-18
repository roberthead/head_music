class HeadMusic::Analysis::PitchSpeller
  # Sweeps the notes in onset order, answering those sounding at each onset
  # asked for in turn.
  class Sounding
    def initialize(notes)
      @notes = notes
      @order = notes.each_index.sort_by { |position| [notes[position].onset, position] }
      @cursor = 0
      @active = []
    end

    def at(onset)
      while @cursor < @order.length && @notes[@order[@cursor]].onset <= onset
        @active << @order[@cursor]
        @cursor += 1
      end
      @active.select! { |position| @notes[position].onset + @notes[position].duration > onset }
      @active
    end
  end
end
