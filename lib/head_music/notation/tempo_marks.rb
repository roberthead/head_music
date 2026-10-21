# A module for visual music notation
module HeadMusic::Notation
  # The tempo marks a writer writes for a flow, after its opening tempo, in
  # time order: each tempo change, each ramp's start and end, and each
  # "a tempo". At one position a ramp ends, then an "a tempo" restores, then
  # the tempo changes, then a ramp starts, as the timeline resolves them.
  class TempoMarks
    include Enumerable

    RANKS = {ramp_end: 0, a_tempo: 1, tempo: 2, ramp_start: 3}.freeze

    # +tempo+ is the tempo to write: a change's, or a ramp's target, nil
    # where none was written. +text+ is the words to write at an "a tempo" or
    # a ramp's start, where a ramp with none is written "rit." or "accel.".
    Mark = Data.define(:kind, :position, :tempo, :text)

    def initialize(flow)
      @flow = flow
      @marks = (tempo_changes + ramp_marks + a_tempo_marks).each_with_index
        .sort_by { |mark, index| [mark.position.to_a, RANKS.fetch(mark.kind), index] }.map(&:first)
    end

    def opening
      @flow.timeline.opening_tempo
    end

    def each(&)
      @marks.each(&)
    end

    # The ramps a reader of tempo marks would not read back as they are: one
    # whose text is not a ramp word, one with a fermata beginning inside it,
    # which would end it there, and one with no target that ends where
    # nothing else would end it.
    def unreadable_ramps
      @flow.tempo_ramps.select do |ramp|
        (ramp.text && TempoMarkReading.word(ramp.text) != :ramp) ||
          fermata_starts.any? { |start| (ramp.from.to_a <=> start).negative? && (start <=> ramp.to.to_a).negative? } ||
          (ramp.to_tempo.nil? && !ending_moments.include?(ramp.to.to_a))
      end
    end

    private

    # A change a ramp's target already writes is not written again.
    def tempo_changes
      targets = @flow.tempo_ramps.to_h { |ramp| [ramp.to.to_a, ramp.to_tempo] }
      @flow.tempo_changes.filter_map do |bar_number, tempo|
        position = @flow.position(bar_number, HeadMusic::Content::Flow::Timeline::DOWNBEAT, 0)
        Mark.new(:tempo, position, tempo, tempo.text) unless targets[position.to_a] == tempo
      end
    end

    def ramp_marks
      @flow.tempo_ramps.flat_map do |ramp|
        [
          Mark.new(:ramp_start, ramp.from, nil, ramp.text || default_text(ramp)),
          Mark.new(:ramp_end, ramp.to, ramp.to_tempo, nil)
        ]
      end
    end

    def a_tempo_marks
      @flow.a_tempos.map { |a_tempo| Mark.new(:a_tempo, a_tempo.position, nil, a_tempo.text) }
    end

    def default_text(ramp)
      target = conductor.tempo_ramps.find { |resolved| resolved.from.to_a == ramp.from.to_a }.to_tempo
      (whole_notes_per_minute(target) > whole_notes_per_minute(conductor.tempo_at(ramp.from))) ? "accel." : "rit."
    end

    def whole_notes_per_minute(tempo)
      tempo.beats_per_minute * tempo.beat_value.fraction
    end

    def conductor
      @conductor ||= @flow.conductor
    end

    def fermata_starts
      @fermata_starts ||= @flow.fermatas.map { |fermata| fermata.from.to_a }
    end

    # Where a reader would end a ramp with no target.
    def ending_moments
      @ending_moments ||= [
        *@flow.tempo_changes.keys.map { |bar_number| [bar_number, HeadMusic::Content::Flow::Timeline::DOWNBEAT, 0, 0] },
        *@flow.a_tempos.map { |a_tempo| a_tempo.position.to_a },
        *@flow.tempo_ramps.map { |ramp| ramp.from.to_a },
        *fermata_starts,
        @flow.final_barline_position.to_a
      ]
    end
  end
end
