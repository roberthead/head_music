module HeadMusic::MIDI
  # The programs a pitched part's channel plays, as [time, program] pairs with
  # times in exact whole notes from the file's start and programs 1-based.
  # Each played bar gets the program of the instrument in force whenever it
  # differs from the last written, so a D.C. restores the first program.
  class ProgramChanges
    DEFAULT_PROGRAM = 1

    attr_reader :part, :timeline

    def initialize(part, timeline)
      @part = part
      @timeline = timeline
    end

    def changes
      last_program = nil
      timeline.spans.each_with_object([]) do |span, changes|
        program = program_at(span.bar_number)
        next if program == last_program

        changes << [span.start, program]
        last_program = program
      end
    end

    private

    def program_at(bar_number)
      part.instrument_at(bar_number)&.gm_program || DEFAULT_PROGRAM
    end
  end
end
