# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Replays a Document's rows onto a fresh flow.
  #
  # Rows are read in order, so an interpretation is in force before the
  # bar it governs. Each data row is a time slice: every note it attacks
  # must begin exactly when the previous note in its spine ends, and a
  # null token must fall inside a note that is still sounding. Placements
  # wait until the end, when every bar's number and start are known.
  class FlowBuilder
    TIMELINE_KINDS = %i[signature designation meter tempo].freeze
    TrackTags = Struct.new(:clef, :code, :name, :part, :staff)

    attr_reader :document

    def initialize(document)
      @document = document
    end

    def flow
      @built ||= build
    end

    private

    attr_reader :clock

    def build
      @tags = document.kern_tracks.to_h { |track| [track, TrackTags.new] }
      @opening = {}
      @cursors = {}
      @layers = []
      @flow = nil
      @clock = BarClock.new { |bar_number| @flow.meter_at(bar_number) }
      document.rows.each { |row| read(row) }
      raise ParseError, "kern input contains no music" unless @flow

      clock.finish(current_time, document.rows.last.record.line)
      @layers.each { |layer| layer.place(clock) }
      mark_repeats
      @flow
    end

    def mark_repeats
      clock.repeat_starts.each { |number| @flow.bars(number).last.starts_repeat = true }
      clock.repeat_ends.each { |number| @flow.bars(number).last.ends_repeat_after_num_plays = 2 }
    end

    def read(row)
      case row.record.kind
      when :interpretation then read_interpretations(row)
      when :barline then read_barline(row)
      when :data then read_data(row)
      end
    end

    # The kern fields of a row, each with its track and its 1-based column.
    def kern_fields(row)
      row.tracks.each_with_index.filter_map do |track, index|
        [track, row.record.fields[index], index + 1] if track.kern?
      end
    end

    def current_time
      @cursors.values.map(&:busy_until).min || @last_time || 0
    end

    def in_force_bar
      clock.number || HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR
    end

    # Interpretations

    def read_interpretations(row)
      line = row.record.line
      interpretations = kern_fields(row).filter_map do |track, field, _column|
        interpretation = InterpretationReader.read(field, line_number: line)
        [track, interpretation] if interpretation
      end
      timeline = agreed_timeline(interpretations, line)
      spine = interpretations.reject { |_track, interpretation| TIMELINE_KINDS.include?(interpretation.kind) }
      @flow ? read_changes(timeline, spine, line) : read_opening(timeline, spine, line)
      apply_manipulations(row)
    end

    # The timeline is the flow's, so every kern spine that states a value
    # on a row must state the same one.
    def agreed_timeline(interpretations, line)
      timeline = interpretations.map(&:last).select { |interpretation| TIMELINE_KINDS.include?(interpretation.kind) }
      timeline.group_by(&:kind).transform_values do |group|
        if group.map { |interpretation| comparable(interpretation.value) }.uniq.length > 1
          raise UnsupportedFeatureError.new(
            "Kern spines disagree on one row (#{group.map(&:field).uniq.join(", ")})", line_number: line
          )
        end
        group.first
      end
    end

    def comparable(value)
      case value
      when HeadMusic::Rudiment::Tempo then [value.beat_value.to_s, value.beats_per_minute]
      when Integer then value
      when HeadMusic::Rudiment::Meter then value.to_s
      else value.name.to_s
      end
    end

    def read_opening(timeline, spine, line)
      timeline.each_value { |interpretation| @opening[interpretation.kind] = [interpretation.value, line] }
      spine.each { |track, interpretation| @tags[track][interpretation.kind] = interpretation.value }
    end

    def read_changes(timeline, spine, line)
      timeline.each_value { |interpretation| change_timeline(interpretation, line) }
      spine.each { |track, interpretation| change_spine(track, interpretation, line) }
    end

    def change_timeline(interpretation, line)
      kind = interpretation.kind
      value = interpretation.value
      return unless timeline_change?(kind, value, in_force_bar)

      clock.at_downbeat(current_time, interpretation.field, line) do |bar_number|
        apply_timeline_change(kind, value, bar_number) if timeline_change?(kind, value, bar_number)
      end
    end

    def timeline_change?(kind, value, bar_number)
      event = @flow.timeline.key_signature_event_at(bar_number)
      case kind
      when :meter then @flow.meter_at(bar_number) != value
      when :tempo then comparable(@flow.tempo_at(bar_number)) != comparable(value)
      when :signature then event.signature != value
      when :designation then event.tonal_context&.name != value.name
      end
    end

    # A designation keeps the signature in force; a signature keeps only a
    # designation authored in the same bar, since the one in force before
    # was an interpretation of the old signature.
    def apply_timeline_change(kind, value, bar_number)
      case kind
      when :meter then @flow.change_meter(bar_number, value)
      when :tempo then @flow.change_tempo(bar_number, value)
      when :signature
        authored = @flow.timeline.key_signature_change_at(bar_number)
        @flow.change_key_signature(bar_number, value, tonal_context: authored&.tonal_context)
      when :designation
        signature = @flow.timeline.signature_at(bar_number)
        @flow.change_key_signature(bar_number, signature, tonal_context: value)
      end
    end

    def change_spine(track, interpretation, line)
      case interpretation.kind
      when :clef then change_clef(track, interpretation, line)
      when :code, :name, :part then ensure_unchanged(track, interpretation, line)
      end
    end

    def change_clef(track, interpretation, line)
      clef = interpretation.value
      staff = @cursors.fetch(track).layer.voice.staff_at(in_force_bar)
      return if clef.nil? || staff.clef_at(in_force_bar) == clef

      clock.at_downbeat(current_time, interpretation.field, line) do |bar_number|
        staff.change_clef(bar_number, clef) unless staff.clef_at(bar_number) == clef
      end
    end

    def ensure_unchanged(track, interpretation, line)
      return if @tags.fetch(track)[interpretation.kind] == interpretation.value

      raise UnsupportedFeatureError.new(
        "Changing #{interpretation.field} in the middle of a spine is not supported", line_number: line
      )
    end

    def apply_manipulations(row)
      row.manipulations.each do |manipulation|
        tracks = manipulation.tracks
        next unless tracks.first.kern?

        case manipulation.type
        when :split, :join then manipulate_before_music(manipulation, row.record.line)
        when :end then end_cursor(tracks.first)
        end
      end
    end

    # Once every spine has ended, the time is where the longest one did.
    def end_cursor(track)
      cursor = @cursors.delete(track)
      return unless cursor

      cursor.ensure_tie_closed
      @last_time = [@last_time, cursor.busy_until].compact.max
    end

    def manipulate_before_music(manipulation, line)
      raise UnsupportedFeatureError.new("Spine splits and joins are not yet supported", line_number: line) if @flow

      left, right = manipulation.tracks
      @tags[right] = @tags.fetch(left).dup if manipulation.type == :split
    end

    # The flow

    def start_flow(row)
      @flow = HeadMusic::Content::Flow.new(
        name: document.title,
        key_signature: opening_key_signature,
        meter: @opening[:meter]&.first,
        tempo: @opening[:tempo]&.first
      )
      row.tracks.select(&:kern?).reverse_each { |track| add_part(track) }
    end

    # The timeline opens with one event holding both the signature and its
    # interpretation, so an opening designation must agree with the
    # opening signature.
    def opening_key_signature
      fifths, fifths_line = @opening[:signature]
      context, context_line = @opening[:designation]
      return fifths && HeadMusic::Rudiment::KeySignature.get(HeadMusic::Rudiment::Key.for_fifths(fifths).name) unless context

      key_signature = HeadMusic::Rudiment::KeySignature.get(context.name)
      if fifths && HeadMusic::Content::Flow::Timeline.fifths_of(key_signature) != fifths
        raise UnsupportedFeatureError.new(
          "The opening key signature (#{KeyReader.signature_field(fifths)}) does not match the designation #{context}",
          line_number: [fifths_line, context_line].max
        )
      end
      key_signature
    end

    def add_part(track)
      tags = @tags.fetch(track)
      part = @flow.add_part(
        player: tags.name && HeadMusic::Content::Player.new(name: tags.name),
        instrument: tags.code && InstrumentCodes.instrument(tags.code),
        staff_system: tags.clef && HeadMusic::Content::StaffSystem.single_staff(clef: tags.clef)
      )
      layer = Layer.new(part.add_voice)
      @layers << layer
      @cursors[track] = VoiceCursor.new(layer, current_time)
    end

    # Data and barlines

    def read_data(row)
      start_flow(row) unless @flow
      line = row.record.line
      tokens = kern_fields(row).map do |track, field, column|
        [@cursors.fetch(track), TokenReader.read(field, line_number: line), column]
      end
      return if tokens.none? { |_cursor, token, _column| token.attack? }

      clock.ensure_music_allowed
      time = current_time
      tokens.each { |cursor, token, column| read_token(cursor, token, time, column, line) }
    end

    def read_token(cursor, token, time, column, line)
      if token.attack?
        if cursor.busy_until > time
          raise ParseError.new("A note in spine #{column} begins before the note before it ends", line_number: line)
        end
        cursor.read(token, time, line)
      elsif token.type == :null && cursor.busy_until <= time
        raise ParseError.new("A null token in spine #{column} falls where no note is sounding", line_number: line)
      end
    end

    def read_barline(row)
      fields = kern_fields(row)
      return if fields.empty?

      line = row.record.line
      barline = BarlineReader.read(fields.first[1], line_number: line)
      clock.barline(barline, aligned_time(line), line)
    end

    def aligned_time(line)
      ends = @cursors.values.map(&:busy_until).uniq
      return current_time if ends.length <= 1

      bar = clock.number ? "bar #{clock.number}" : "the opening bar"
      raise ParseError.new("Kern spines disagree on the length of #{bar}", line_number: line)
    end
  end
end
