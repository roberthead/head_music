# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # The \tuplets read from a flow's voices, held until every voice is
  # placed and then bracketed, since a voice refuses a note inside a bracket. One that
  # names a span is cut into a bracket each span of its time, as LilyPond
  # draws it, and one the voice refuses, such as a cut inside a note, leaves
  # its values unbracketed.
  class PendingTuplets
    # The time a \tuplet holds in one voice.
    Tuplet = Data.define(:voice, :from, :to, :span) do
      def groups
        return [[from, to]] unless span

        starts = [from]
        step = (span * HeadMusic::Rudiment::Rhythm::SUBTICKS_PER_WHOLE).to_i
        starts << starts.last.advance(subticks: step) while starts.last.advance(subticks: step) < to
        starts.zip(starts.drop(1) + [to])
      end

      def bracket
        groups.each do |group_from, group_to|
          voice.group_tuplet(from: group_from, to: group_to)
        rescue ArgumentError
          nil
        end
      end
    end

    def initialize
      @open = {}.compare_by_identity
      @closed = []
    end

    def start(voice, position, span)
      @open[voice] = [position, span]
    end

    def stop(voice, position)
      from, span = @open.delete(voice)
      @closed << Tuplet.new(voice, from, position, span) if from && from < position
    end

    def bracket
      @closed.each(&:bracket)
    end
  end
end
