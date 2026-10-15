module HeadMusic::MIDI
  # The programs a pitched part's channel plays, as [time, program] pairs with
  # times in exact whole notes from the file's start and programs 1-based.
  #
  # For now a part writes none.
  class ProgramChanges
    attr_reader :part, :timeline

    def initialize(part, timeline)
      @part = part
      @timeline = timeline
    end

    def changes
      []
    end
  end
end
