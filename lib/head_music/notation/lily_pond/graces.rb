# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # The grace notes waiting for their main note, and the transposition that
  # follows the last of them. A voice gathers them from each grace command
  # and hands them to the note they come before.
  class Graces < Data.define(:graces, :implied_slur, :transposition)
    IMPLIED_SLUR_ID = :grace

    Grace = Data.define(:pitches, :rhythmic_value, :slashed, :tied, :marks, :transposition) do
      def initialize(transposition: nil, **)
        super
      end

      # A tie holds only into a note of the same pitches.
      def before(follower)
        with(tied: tied && pitches.sort == follower.sort)
      end

      def grace_note
        HeadMusic::Content::GraceNote.new(
          sounds: pitches, rhythmic_value: rhythmic_value, slashed: slashed, tied: tied, articulations: marks.articulations
        )
      end
    end

    def initialize(transposition: nil, **)
      super
    end

    NONE = new(graces: [], implied_slur: false, transposition: nil)

    def +(other)
      following = other.graces
      following = [following.first.with(transposition: following.first.transposition || transposition), *following.drop(1)] if following.any?
      with(
        graces: graces + following, implied_slur: implied_slur || other.implied_slur,
        transposition: other.transposition || (transposition if following.empty?)
      )
    end

    def last_transposition
      transposition || graces.filter_map(&:transposition).last
    end

    def before(pitches)
      graces.zip(graces.drop(1).map(&:pitches) + [pitches]).map { |grace, follower| grace.before(follower) }
    end

    # The main note takes its grace notes' levels and hairpins, and the
    # slurs they end. A slur opened on the first grace note starts there.
    def main_marks(marks)
      grace_marks = graces.map(&:marks)
      MarkReader::Marks.new(
        level: marks.level || grace_marks.filter_map(&:level).last,
        hairpin_marks: grace_marks.flat_map(&:hairpin_marks),
        span_marks: implied_slur_marks + grace_span_marks
      ).merge(marks.with(level: nil))
    end

    private

    def first_span_marks
      graces.first&.marks&.span_marks || []
    end

    def grace_span_marks
      first_span_marks.map(&:on_grace) + graces.drop(1).flat_map { |grace| grace.marks.span_marks }
    end

    def implied_slur_marks
      return [] unless implied_slur
      return [] if first_span_marks.any? { |mark| mark.opens?(:slur) }

      [
        MarkReader::SpanMark.new(kind: :slur, opening: true, id: IMPLIED_SLUR_ID, from_grace: true),
        MarkReader::SpanMark.new(kind: :slur, opening: false, id: IMPLIED_SLUR_ID)
      ]
    end
  end
end
