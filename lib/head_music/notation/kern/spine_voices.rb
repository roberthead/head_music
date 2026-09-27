# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # The voice each live kern spine writes to, kept in step as spine
  # manipulators split, join, and end the spines.
  #
  # A voice outlives the spine that wrote it: one a join or a terminator
  # leaves dormant can be woken by a later split on its part and staff.
  class SpineVoices
    def initialize
      @cursors = {}
      @layers = []
      @last_time = nil
    end

    # Once every spine has ended, the time is where the longest one did.
    def current_time
      @cursors.values.map(&:busy_until).min || @last_time || 0
    end

    def start(track, part, staff)
      @cursors[track] = VoiceCursor.new(add_layer(part, staff), current_time)
    end

    def layer(track)
      @cursors.fetch(track).layer
    end

    def part(track)
      layer(track).voice.part
    end

    # Answers the event each spine's token attacked, if any.
    def read(tokens, time, line)
      tokens.to_h { |track, token, column| [track, read_token(track, token, time, column, line)] }
    end

    def manipulate(manipulation, line)
      tracks = manipulation.tracks
      case manipulation.type
      when :split then split(*tracks)
      when :join then join(tracks, line)
      when :end then end_track(tracks.first)
      end
    end

    def aligned_time(clock, line)
      return current_time if @cursors.values.map(&:busy_until).uniq.length <= 1

      bar = clock.number ? "bar #{clock.number}" : "the opening bar"
      raise ParseError.new("Kern spines disagree on the length of #{bar}", line_number: line)
    end

    def place(clock)
      finish_time = @layers.filter_map(&:end_time).max
      @layers.each { |layer| layer.place(clock, finish_time) }
    end

    private

    def read_token(track, token, time, column, line)
      cursor = @cursors.fetch(track)
      if token.attack?
        unless cursor.attackable_at?(time)
          raise ParseError.new("A note in spine #{column} begins before the note before it ends", line_number: line)
        end
        cursor.read(token, time, line)
      elsif token.type == :null && cursor.busy_until <= time
        raise ParseError.new("A null token in spine #{column} falls where no note is sounding", line_number: line)
      end
    end

    # The left sub-spine continues its voice as the upper voice. The right
    # one wakes a dormant voice of the same part and staff, or else starts
    # a new one; either is padded with rests up to its first note.
    #
    # The right one may attack while the left still holds a note, since the
    # split is where it begins.
    def split(left, right)
      cursor = @cursors.fetch(left)
      layer = dormant_layer(cursor.layer) || add_layer(cursor.layer.voice.part, cursor.layer.staff)
      @cursors[right] = VoiceCursor.new(layer, cursor.busy_until, starts_at: current_time)
    end

    # Reusing a dormant voice keeps a part to as many voices as it ever has
    # sub-spines at once. One still sounding when the split comes is not
    # dormant yet.
    def dormant_layer(sibling)
      live = @cursors.values.map(&:layer)
      time = current_time
      @layers.find do |layer|
        !live.include?(layer) && same_staff?(layer, sibling) && (layer.end_time.nil? || layer.end_time <= time)
      end
    end

    # The leftmost sub-spine continues its voice; the others go dormant.
    def join(tracks, line)
      survivor, *others = tracks.map { |track| layer(track) }
      if others.any? { |other| !same_staff?(other, survivor) }
        raise UnsupportedFeatureError.new("Joining spines of different parts or staves is not supported", line_number: line)
      end

      tracks.drop(1).each { |track| end_track(track) }
    end

    def same_staff?(layer, other)
      layer.voice.part.equal?(other.voice.part) && layer.staff.equal?(other.staff)
    end

    def end_track(track)
      cursor = @cursors.delete(track)
      return unless cursor

      cursor.ensure_tie_closed
      @last_time = [@last_time, cursor.busy_until].compact.max
    end

    def add_layer(part, staff)
      Layer.new(part.add_voice, staff).tap { |layer| @layers << layer }
    end
  end
end
