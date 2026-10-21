# A module for visual music notation
module HeadMusic::Notation
  # Turns the tempo marks a reader finds into the flow's tempo changes, tempo
  # ramps, and "a tempo" points, by one vocabulary and one rule for every
  # format.
  #
  # A tempo mark at a downbeat changes the tempo, unless it restates the one
  # in force. A ramp word starts a ramp that ends at the next tempo mark,
  # "a tempo", fermata, or ramp word, or else at the end of the music; a
  # tempo mark ending it is its target. An "a tempo" word restores the tempo
  # before the latest ramp. A format that writes where a ramp ends, as
  # MusicXML's <dashes> do, ends it there. Anything else in the middle of a
  # bar is dropped.
  class TempoMarkReading
    MODIFIER = /(?:(?:poco a poco|un poco|poco|molto)\s+)?/i
    RAMP_WORD = /\A#{MODIFIER}(?:ritardando|ritard|rit|rallentando|rall|accelerando|accel|stringendo)(?![[:alnum:]])/i
    A_TEMPO_WORD = /\Aa tempo(?![[:alnum:]])/i
    TEMPO_PRIMO_WORD = /\A(?:tempo primo|tempo i)(?![[:alnum:]])/i

    # At one position, a tempo ends a ramp before an "a tempo", a fermata, or
    # a written end does, and a ramp starts last.
    RANKS = {tempo: 0, a_tempo: 1, tempo_primo: 1, fermata: 1, ramp_end: 1, ramp: 2}.freeze

    Step = Data.define(:position, :kind, :value)

    # :ramp, :a_tempo, :tempo_primo, or nil for text that is none of them.
    def self.word(text)
      text = text.to_s.strip
      if RAMP_WORD.match?(text)
        :ramp
      elsif A_TEMPO_WORD.match?(text)
        :a_tempo
      elsif TEMPO_PRIMO_WORD.match?(text)
        :tempo_primo
      end
    end

    def initialize
      @steps = []
    end

    # A tempo is what a format writes in its tempo construct; text is free
    # text, such as an annotation, read only for its ramp and "a tempo" words.
    # A tempo of words alone that are ramp or "a tempo" words reads as those.
    def add(position, tempo = nil, text = nil)
      tempo_word = self.class.word(tempo.text) if tempo && !tempo.metronome_mark?
      @steps << Step.new(position, :tempo, tempo) if tempo && !tempo_word
      words = text || (tempo.text if tempo_word)
      kind = self.class.word(words)
      @steps << Step.new(position, kind, words.strip) if kind
    end

    def add_ramp_end(position)
      @steps << Step.new(position, :ramp_end, nil)
    end

    def apply(flow)
      @flow = flow
      @ramp = nil
      steps.each { |step| send(:"read_#{step.kind}", step.position, step.value) }
      close_ramp(flow.final_barline_position)
    end

    private

    attr_reader :flow

    def steps
      fermatas = flow.fermatas.map { |fermata| Step.new(fermata.from, :fermata, nil) }
      (@steps.map { |step| step.with(position: HeadMusic::Content::Position.for_flow(flow, step.position)) } + fermatas)
        .each_with_index.sort_by { |step, index| [step.position.to_a, RANKS.fetch(step.kind), index] }.map(&:first)
    end

    def read_tempo(position, tempo)
      close_ramp(position, tempo)
      return unless downbeat?(position)

      bar_number = position.bar_number
      refusable { flow.change_tempo(bar_number, tempo) } unless flow.tempo_at(bar_number) == tempo
    end

    # "Tempo I" returns to the opening tempo. Since a tempo changes only at a
    # downbeat, in the middle of a bar it reads as "a tempo", which agrees
    # whenever the ramp before it left the opening tempo.
    def read_tempo_primo(position, text)
      return read_a_tempo(position, text) unless downbeat?(position)

      opening = flow.tempo_at(flow.earliest_bar_number)
      read_tempo(position, HeadMusic::Rudiment::Tempo.new(opening.beat_value, opening.beats_per_minute, text: text, metronome_mark: opening.metronome_mark?))
    end

    def read_a_tempo(position, text)
      close_ramp(position)
      refusable { flow.add_a_tempo(position, text: text) }
    end

    def read_fermata(position, _value)
      close_ramp(position)
    end

    def read_ramp_end(position, _value)
      close_ramp(position)
    end

    def read_ramp(position, text)
      close_ramp(position)
      @ramp = [position, text]
    end

    def downbeat?(position)
      position.to_a.drop(1) == [HeadMusic::Content::Flow::Timeline::DOWNBEAT, 0, 0]
    end

    def close_ramp(position, to_tempo = nil)
      return unless @ramp

      from, text = @ramp
      @ramp = nil
      refusable { flow.add_tempo_ramp(from: from, to: position, to_tempo: to_tempo, text: text) }
    end

    # A mark the timeline refuses, such as a ramp that ends where it begins,
    # is dropped.
    def refusable
      yield
    rescue ArgumentError
      nil
    end
  end
end
