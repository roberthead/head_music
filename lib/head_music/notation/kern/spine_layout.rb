# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Follows a file's columns as spine manipulators split, join, exchange,
  # and end them.
  #
  # Each column is a Track with a stable identity, so a reader can keep
  # per-spine state across the rows that rearrange the columns. A split
  # keeps the left half as the original track; a join keeps the leftmost.
  class SpineLayout
    KINDS = {"**kern" => :kern, "**text" => :lyric, "**silbe" => :lyric, "**dynam" => :dynam}.freeze
    MANIPULATORS = %w[*^ *v *x *- *+].freeze

    # One column through the file. Compared by identity: two tracks of the
    # same kind from the same header spine are still two tracks.
    class Track
      attr_reader :exclusive, :origin

      def initialize(exclusive, origin)
        @exclusive = exclusive
        @origin = origin
      end

      def kind
        KINDS.fetch(exclusive, :skipped)
      end

      def kern?
        kind == :kern
      end

      def lyric?
        kind == :lyric
      end

      def dynam?
        kind == :dynam
      end

      def sprout
        self.class.new(exclusive, origin)
      end
    end

    # A change a manipulator row made: :split tracks are [left, right]; :join
    # tracks are the joined run, survivor first; :exchange tracks are the
    # swapped pair in their old order; :end tracks are the one terminated.
    Manipulation = Data.define(:type, :tracks)

    attr_reader :tracks

    def self.manipulator_row?(record)
      record.kind == :interpretation && record.fields.any? { |field| MANIPULATORS.include?(field) }
    end

    def initialize(header_record)
      @tracks = header_record.fields.each_with_index.map { |exclusive, index| Track.new(exclusive, index) }
    end

    def empty?
      tracks.empty?
    end

    def ensure_width(record)
      fields = record.fields
      width = fields.length
      live = tracks.length
      return if width == live

      raise ParseError.new(
        "Row has #{width} #{"field".pluralize(width)} but #{live} #{"spine".pluralize(live)} #{(live == 1) ? "is" : "are"} live",
        line_number: record.line, snippet: fields.join("\t")
      )
    end

    # Applies a manipulator row left to right and answers what it changed.
    def apply(record)
      @record = record
      @next_tracks = []
      @manipulations = []
      index = 0
      index = apply_at(index) while index < record.fields.length
      @tracks = @next_tracks
      @manipulations
    end

    private

    attr_reader :record

    def apply_at(index)
      case record.fields[index]
      when "*^" then split(index)
      when "*v" then join(index)
      when "*x" then exchange(index)
      when "*-" then terminate(index)
      when "*+" then raise error(UnsupportedFeatureError, "Adding a spine with *+ is not supported", "*+")
      else
        @next_tracks << tracks[index]
        index + 1
      end
    end

    def split(index)
      track = tracks[index]
      raise error(UnsupportedFeatureError, "Splitting a #{track.exclusive} spine is not supported", "*^") if track.lyric?

      halves = [track, track.sprout]
      change(:split, halves, halves)
      index + 1
    end

    def join(index)
      run = run_of("*v", index)
      length = run.length
      raise error(ParseError, "*v must join two or more adjacent spines", "*v") if length < 2

      exclusives = run.map(&:exclusive).uniq
      raise error(ParseError, "*v cannot join spines of different kinds (#{exclusives.join(", ")})", "*v") unless exclusives.one?

      change(:join, run, [run.first])
      index + length
    end

    def exchange(index)
      run = run_of("*x", index)
      raise error(ParseError, "*x must exchange exactly two adjacent spines", "*x") unless run.length == 2

      change(:exchange, run, run.reverse)
      index + 2
    end

    def terminate(index)
      change(:end, [tracks[index]], [])
      index + 1
    end

    def change(type, changed, survivors)
      @next_tracks.concat(survivors)
      @manipulations << Manipulation.new(type, changed)
    end

    def run_of(manipulator, index)
      length = record.fields.drop(index).take_while { |field| field == manipulator }.length
      tracks[index, length]
    end

    def error(klass, message, snippet)
      klass.new(message, line_number: record.line, snippet: snippet)
    end
  end
end
