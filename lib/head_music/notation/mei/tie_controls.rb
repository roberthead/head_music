module HeadMusic::Notation::MEI
  # MEI's ties, as the tie starts and stops TieFolding folds: @tie on a
  # note or its chord, i starting a tie, m continuing it, and t ending it,
  # and <tie> control events by @startid and @endid or by @tstamp and
  # @tstamp2. A tie by beats ties the pitches the events there share.
  #
  # A tie whose ends are in different voices, or one that nothing ends, is
  # dropped, and its notes keep their written values; <lv> is never read.
  #
  # A tie's later note at its chain's letter and octave takes the chain's
  # alteration, as a tie carries an accidental across the barline, so each
  # note's tie is known as the measure is spelled.
  class TieControls
    include XmlReading

    def initialize(index)
      @index = index
      @starts_by_end = {}.compare_by_identity
      @alterations = {}.compare_by_identity
      @open = {}
    end

    # Where a note is in its tie, by its own @tie or its chord's.
    def self.marker(note, entry, **where)
      AttributeValues.read(note, "tie", **where, element: note) ||
        (entry.kind == :chord && AttributeValues.read(entry.element, "tie", **where, element: entry.element)) || nil
    end

    # Notes, before a measure is spelled, each <tie> by ids among its
    # controls.
    def note_controls(controls, where)
      controls.each do |control|
        next unless control.name == "tie"

        start, finish = %w[startid endid].map { |name| @index.named_by(control, name, **where, element: control) }
        next unless start && finish

        @starts_by_end[finish] = start
        @alterations[start] = nil
      end
    end

    # The alteration a tie carries into a note, or nil.
    def carried(note, spelling, marker, stream)
      return @alterations[@starts_by_end[note]] if @starts_by_end.key?(note)

      @open[[*stream, spelling.letter, spelling.octave]] if %w[m t].include?(marker)
    end

    def remember(note, spelling, marker, stream, alteration)
      @alterations[note] = alteration if @alterations.key?(note)
      place = [*stream, spelling.letter, spelling.octave]
      case marker
      when "i", "m" then @open[place] = alteration
      when "t" then @open.delete(place)
      end
    end

    # Sets every tie's starts and stops on the tracks, once the voices are
    # assigned.
    def apply(score)
      @score = score
      score.pending.each { |pending| tie_by_attribute(pending) if pending.kind == :note && pending.track }
      score.measures.each do |measure|
        measure.controls.each { |control| tie_control(control, measure) if control.name == "tie" }
      end
    end

    private

    def tie_by_attribute(pending)
      tie = pending.tie
      start(pending) if %w[i m].include?(tie)
      stop(pending) if %w[m t].include?(tie)
    end

    def tie_control(control, measure)
      where = {measure: measure.number, element: control}
      starts = end_notes(control, "startid", where) { notes_at(control, Tstamp.start_at(control, measure, **where), where) }
      stops = end_notes(control, "endid", where) { notes_at(control, Tstamp.finish(control, @score.measures, measure.index, **where), where) }
      pairs(starts, stops).each do |from, to|
        next unless from.track&.equal?(to.track)

        start(from)
        stop(to)
      end
    end

    # A single note to a single note ties whatever they sound, so that a tie
    # between different pitches raises when it is folded; otherwise the
    # pitches the ends share are tied.
    def pairs(starts, stops)
      return [] if starts.nil? || stops.nil?
      return [[starts.first, stops.first]] if starts.one? && stops.one?

      starts.filter_map do |from|
        to = stops.find { |candidate| candidate.sound.to_s == from.sound.to_s }
        [from, to] if to
      end
    end

    # The notes an end names by id, nil where it is skipped, or else those
    # its beat finds.
    def end_notes(control, name, where)
      reference = attribute(control, name, **where)
      return yield unless reference

      element = @index.resolve(reference, **where)
      element && notes_of(element)
    end

    # +measure_beat+ is a measure's index and a beat there, as Tstamp answers.
    def notes_at(control, measure_beat, where)
      return unless measure_beat

      staff = AttributeValues.read(control, "staff", **where)
      return unless staff

      index, beat = measure_beat
      meter = @score.measures[index].meter
      onsets = onset_index.at(index, Tstamp.offset(beat, meter), meter.bottom_number, staff: staff, layer: AttributeValues.read(control, "layer", **where))
      onsets.flat_map(&:pending).select { |pending| pending.kind == :note && pending.sound }
    end

    def notes_of(element)
      pending = pending_by_element[element]
      return [] unless pending

      (pending.kind == :chord) ? chord_tones[pending] : [pending].select(&:sound)
    end

    def start(pending)
      tied = pending.grace || pending.event
      tied.tie_starts |= [pending.sound.to_s] if tied
    end

    def stop(pending)
      event = pending.event
      event.tie_stops |= [pending.sound.to_s] if event && !pending.grace
    end

    def onset_index
      @onset_index ||= OnsetIndex.new(@score.readings)
    end

    def pending_by_element
      @pending_by_element ||= @score.pending_by_element
    end

    def chord_tones
      @chord_tones ||= @score.pending.chunk_while { |_, following| following.chord_member }
        .each_with_object({}.compare_by_identity) { |(first, *tones), by_chord| by_chord[first] = tones if first.kind == :chord }
    end
  end
end
