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
    PartState = Data.define(:code, :name, :staves_by_number)
    # What a spine's interpretations said before the first data row, and
    # the line each was read on.
    TrackTags = Struct.new(:clef, :code, :name, :part, :staff, :lines)

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
      @tags = document.kern_tracks.to_h { |track| [track, TrackTags.new(lines: {})] }
      @part_states = {}
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
      spine.each do |track, interpretation|
        tags = @tags.fetch(track)
        tags[interpretation.kind] = interpretation.value
        tags.lines[interpretation.kind] = line
      end
    end

    def read_changes(timeline, spine, line)
      timeline.each_value { |interpretation| change_timeline(interpretation, line) }
      @row_clefs = {}
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
      layer = @cursors.fetch(track).layer
      case interpretation.kind
      when :clef then change_clef(layer, interpretation, line)
      when :staff then change_staff(layer, interpretation, line)
      when :part then ensure_unchanged(@tags.fetch(track).part, interpretation, line)
      when :code, :name then ensure_unchanged(@part_states.fetch(layer.voice.part).public_send(interpretation.kind), interpretation, line)
      end
    end

    def change_clef(layer, interpretation, line)
      clef = interpretation.value
      return if clef.nil?

      staff = layer.staff
      ensure_one_clef(staff, clef, line)
      return if staff.clef_at(in_force_bar) == clef

      clock.at_downbeat(current_time, interpretation.field, line) do |bar_number|
        staff.change_clef(bar_number, clef) unless staff.clef_at(bar_number) == clef
      end
    end

    def ensure_one_clef(staff, clef, line)
      stated = @row_clefs[staff]
      @row_clefs[staff] = clef
      return if stated.nil? || stated == clef

      raise UnsupportedFeatureError.new("Spines on one staff disagree on its clef", line_number: line)
    end

    # A staff crossing, which lives on bars as a clef change does.
    def change_staff(layer, interpretation, line)
      staff = @part_states.fetch(layer.voice.part).staves_by_number[interpretation.value]
      unless staff
        raise UnsupportedFeatureError.new("#{interpretation.field} is not a staff of its spine's part", line_number: line)
      end
      return if staff.equal?(layer.staff)

      layer.staff = staff
      clock.at_downbeat(current_time, interpretation.field, line) do |bar_number|
        layer.voice.assign_staff(bar_number, staff)
      end
    end

    def ensure_unchanged(value, interpretation, line)
      return if value == interpretation.value

      raise UnsupportedFeatureError.new(
        "Changing #{interpretation.field} in the middle of a spine is not supported", line_number: line
      )
    end

    def apply_manipulations(row)
      row.manipulations.each do |manipulation|
        tracks = manipulation.tracks
        next unless tracks.first.kern?

        case manipulation.type
        when :split then split(*tracks)
        when :join then join(tracks, row.record.line)
        when :end then end_cursor(tracks.first)
        end
      end
    end

    # The left sub-spine continues its voice as the upper voice. The right
    # one wakes a dormant voice of the same part and staff, or else starts
    # a new one; either is padded with rests up to its first note.
    def split(left, right)
      unless @flow
        @tags[right] = @tags.fetch(left).dup.tap { |tags| tags.lines = tags.lines.dup }
        return
      end

      cursor = @cursors.fetch(left)
      layer = dormant_layer(cursor.layer) || add_layer(cursor.layer.voice.part, cursor.layer.staff)
      @cursors[right] = VoiceCursor.new(layer, cursor.busy_until)
    end

    # Reusing a dormant voice keeps a part to as many voices as it ever has
    # sub-spines at once. One still sounding when the split comes is not
    # dormant yet.
    def dormant_layer(sibling)
      live = @cursors.values.map(&:layer)
      @layers.find do |layer|
        !live.include?(layer) && layer.voice.part.equal?(sibling.voice.part) && layer.staff.equal?(sibling.staff) &&
          (layer.end_time.nil? || layer.end_time <= current_time)
      end
    end

    # The leftmost sub-spine continues its voice; the others go dormant.
    def join(tracks, line)
      return unless @flow

      survivor, *others = tracks.map { |track| @cursors.fetch(track) }
      if others.any? { |cursor| !same_staff?(cursor.layer, survivor.layer) }
        raise UnsupportedFeatureError.new("Joining spines of different parts or staves is not supported", line_number: line)
      end

      tracks.drop(1).each { |track| end_cursor(track) }
    end

    def same_staff?(layer, other)
      layer.voice.part.equal?(other.voice.part) && layer.staff.equal?(other.staff)
    end

    # A spine that ends before the others leaves its voice dormant, as a
    # join does. Once every spine has ended, the time is where the longest
    # one did.
    def end_cursor(track)
      cursor = @cursors.delete(track)
      return unless cursor

      cursor.ensure_tie_closed
      @last_time = [@last_time, cursor.busy_until].compact.max
    end

    # The flow

    def start_flow(row)
      @flow = HeadMusic::Content::Flow.new(
        name: document.title,
        key_signature: opening_key_signature,
        meter: @opening[:meter]&.first,
        tempo: @opening[:tempo]&.first
      )
      PartGrouping.new(row.tracks.select(&:kern?), @tags).parts.each { |plan| add_part(plan) }
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

    # One player per part, even where two parts share a name: kern has no
    # way to say two spines are one chair.
    def add_part(plan)
      part = @flow.add_part(
        player: plan.name && HeadMusic::Content::Player.new(name: plan.name),
        instrument: plan.code && InstrumentCodes.instrument(plan.code),
        staff_system: staff_system_for(plan)
      )
      staves = part.staff_system.staves
      @part_states[part] = PartState.new(
        code: plan.code, name: plan.name, staves_by_number: plan.staves.map(&:number).zip(staves).to_h
      )
      plan.staves.zip(staves).each do |staff_plan, staff|
        staff_plan.tracks.each { |track| @cursors[track] = VoiceCursor.new(add_layer(part, staff), current_time) }
      end
    end

    # A single staff with no clef is left to the part's fallback system, so
    # that nothing unauthored is serialized.
    def staff_system_for(plan)
      clefs = plan.staves.map(&:clef)
      return if clefs.length == 1 && clefs.first.nil?

      HeadMusic::Content::StaffSystem.new(
        staves: clefs.map { |clef| HeadMusic::Content::Staff.new(clef: clef) },
        bracket: (clefs.length > 1) ? :brace : :none
      )
    end

    def add_layer(part, staff)
      Layer.new(part.add_voice, staff).tap { |layer| @layers << layer }
    end

    # Data and barlines

    def read_data(row)
      start_flow(row) unless @flow
      line = row.record.line
      tokens = kern_fields(row).map do |track, field, column|
        [track, TokenReader.read(field, line_number: line), column]
      end
      attacked = tokens.any? { |_track, token, _column| token.attack? }
      clock.ensure_music_allowed if attacked
      time = current_time
      events = attacked ? tokens.to_h { |track, token, column| [track, read_token(track, token, time, column, line)] } : {}
      sing(row, events)
    end

    # Answers the event the token attacked, if any.
    def read_token(track, token, time, column, line)
      cursor = @cursors.fetch(track)
      if token.attack?
        if cursor.busy_until > time
          raise ParseError.new("A note in spine #{column} begins before the note before it ends", line_number: line)
        end
        cursor.read(token, time, line)
      elsif token.type == :null && cursor.busy_until <= time
        raise ParseError.new("A null token in spine #{column} falls where no note is sounding", line_number: line)
      end
    end

    # A syllable goes to the note its kern spine attacks on the same row.
    def sing(row, events)
      LyricReader.new(row).syllables.each do |syllable|
        event = events[syllable.track]
        if event.nil? || event.pitches.empty?
          raise ParseError.new(
            %(The syllable "#{syllable.text}" in spine #{syllable.column} has no note under it), line_number: row.record.line
          )
        end
        event.syllables << syllable
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
