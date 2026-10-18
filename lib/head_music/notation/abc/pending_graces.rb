# A namespace for ABC-notation parsing helpers
module HeadMusic::Notation::ABC
  # The grace notes written ahead of a voice's next note or chord. A slur
  # opened before them starts on the first of them, and once they are
  # dropped, on what comes next.
  class PendingGraces
    def initialize(slurs)
      @slurs = slurs
      @graces = []
    end

    def add(graces)
      return if graces.empty?

      @graces.concat(graces)
      @slurs.start_on_graces
    end

    def drop
      @graces = []
      @slurs.start_after_graces
    end

    def take
      graces = @graces
      @graces = []
      graces
    end
  end
end
