module HeadMusic::Notation::MEI
  # MEI's ties, as the tie starts and stops TieFolding folds: @tie on a
  # note or its chord, i starting a tie, m continuing it, and t ending it,
  # and <tie> control events by @startid and @endid or by @tstamp and
  # @tstamp2. A tie by beats ties the pitches the events there share.
  #
  # A tie whose ends are in different voices, or one that nothing ends, is
  # dropped, and its notes keep their written values; <lv> is never read.
  #
  # A tie's later note takes its chain's alteration where it writes none,
  # as a tie carries an accidental across the barline, so each note's tie
  # is known as the measure is spelled.
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

        start, finish = %w[startid endid].map { |name| named(control, name, where) }
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

    def named(control, name, where)
      reference = attribute(control, name, **where, element: control)
      reference && @index.named(reference, **where, element: control)
    end

    def tie_by_attribute(pending)
      case pending.tie
      when "i" then start(pending, pending.sound)
      when "m"
        start(pending, pending.sound)
        stop(pending, pending.sound)
      when "t" then stop(pending, pending.sound)
      end
    end

    def tie_control(control, measure)
      where = {measure: measure.number, element: control}
      starts = end_notes(control, "startid", measure, where) { tstamp_notes(control, measure, where) }
      stops = end_notes(control, "endid", measure, where) { tstamp2_notes(control, measure, where) }
      pairs(starts, stops).each do |from, to|
        next unless from.track&.equal?(to.track)

        start(from, from.sound)
        stop(to, to.sound)
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
    def end_notes(control, name, measure, where)
      reference = attribute(control, name, **where)
      return yield unless reference

      element = @index.resolve(reference, **where)
      element && notes_of(element)
    end

    def tstamp_notes(control, measure, where)
      beat = Tstamp.start(control, measure, **where)
      beat && notes_at(control, measure.index, beat, where)
    end

    def tstamp2_notes(control, measure, where)
      index, beat = Tstamp.finish(control, @score.measures, measure.index, **where)
      index && notes_at(control, index, beat, where)
    end

    def notes_at(control, index, beat, where)
      staff = AttributeValues.read(control, "staff", **where)
      return unless staff

      meter = @score.measures[index].meter
      onsets = onset_index.at(index, Tstamp.offset(beat, meter), meter.bottom_number, staff: staff, layer: AttributeValues.read(control, "layer", **where))
      onsets.flat_map(&:pending).select { |pending| pending.kind == :note && pending.sound }
    end

    def notes_of(element)
      pending = pending_by_element[element]
      return [] unless pending

      (pending.kind == :chord) ? chord_tones[pending] : [pending].select(&:sound)
    end

    def start(pending, sound)
      if pending.grace
        pending.grace.tie_starts |= [sound.to_s]
      elsif pending.event
        pending.event.tie_starts |= [sound.to_s]
      end
    end

    def stop(pending, sound)
      pending.event.tie_stops |= [sound.to_s] if pending.event && !pending.grace
    end

    def onset_index
      @onset_index ||= OnsetIndex.new(@score.readings)
    end

    def pending_by_element
      @pending_by_element ||= @score.pending.to_h { |pending| [pending.element, pending] }.compare_by_identity
    end

    def chord_tones
      @chord_tones ||= begin
        chord = nil
        @score.pending.each_with_object({}.compare_by_identity) do |pending, tones|
          if pending.kind == :chord
            chord = tones[pending] = []
          elsif pending.chord_member
            chord << pending
          end
        end
      end
    end
  end
end
