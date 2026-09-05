# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # The pitch readers in scope. \relative and \absolute each push a reader
  # for the music they wrap, so the notes inside are read by the innermost
  # one and the notes after it by whichever reader was in force before.
  class PitchReaderStack
    def initialize
      @readers = [PitchReader.absolute]
    end

    def current
      @readers.last
    end

    def relative(reference, &block)
      scoped(PitchReader.relative(reference), &block)
    end

    def absolute(&block)
      scoped(PitchReader.absolute, &block)
    end

    private

    def scoped(reader)
      @readers.push(reader)
      yield
      @readers.pop
    end
  end
end
