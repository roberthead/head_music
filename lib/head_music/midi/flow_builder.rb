module HeadMusic::MIDI
  # The walking skeleton of the import, which runs every stage in order:
  # bars, quantizing, voices, spelling, values, instruments, and lyrics.
  # It applies no timeline beyond the opening meter.
  class FlowBuilder
    attr_reader :sequence, :budget, :key, :grid

    def initialize(sequence, budget, key: nil, grid: :auto)
      @sequence = sequence
      @budget = budget
      @key = key
      @grid = grid
    end

    def flow
      raise ParseError, "MIDI file contains no notes" if budget.note_count.zero?

      @layout = BarLayout.new(budget.time_signatures, division: sequence.division, end_tick: budget.end_tick)
      @quantizer = Quantizer.new(@layout, sequence.notes, division: sequence.division, grid: grid)
      voices = separate
      Budget.check_voice_bars!(voices.sum { |_part_key, part_voices| part_voices.length }, @layout.bars.length)
      build(voices, spell(voices))
    end

    private

    # Parts by track, then channel.
    def separate
      @quantizer.notes.group_by(&:part_key).sort_by { |part_key, _notes| [part_key.track, part_key.channel] }.map do |part_key, notes|
        [part_key, VoiceSeparator.new(notes, percussion: part_key.percussion?).voices]
      end
    end

    # Pitches for each pitched chord's keys, labeled by part and voice.
    def spell(voices)
      chords = []
      unspelled = []
      voices.each_with_index do |(part_key, part_voices), part_index|
        next if part_key.percussion?

        part_voices.each_with_index do |chords_of_voice, voice_index|
          chords_of_voice.each do |chord|
            chords << chord
            chord.keys.each do |number|
              unspelled << HeadMusic::Analysis::UnspelledNote.new(number: number, onset: chord.onset, duration: chord.duration, voice: [part_index, voice_index])
            end
          end
        end
      end
      pitches = HeadMusic::Analysis::PitchSpeller.new(HeadMusic::Analysis::NoteInput.new(unspelled, @layout.bar_starts), key: key || :infer).pitches
      chords.each_with_object({}.compare_by_identity) { |chord, spelled| spelled[chord] = pitches.shift(chord.keys.length) }
    end

    def build(voices, pitches)
      flow = HeadMusic::Content::Flow.new(name: sequence.name, meter: @layout.bars.first.meter)
      values = NoteValues.new(@layout)
      events_by_part = voices.to_h do |part_key, part_voices|
        part = flow.add_part(instrument: instrument(part_key))
        [part_key, part_voices.map { |chords| place(part.add_voice, chords, values) { |chord| sounds(part_key, chord, pitches) } }]
      end
      LyricAttacher.new(lyrics, events_by_part).attach
      flow
    end

    def place(voice, chords, values)
      position = voice.flow.position(@layout.first_number, 1, 0)
      time = @layout.bars.first.start
      onsets = {}
      chords.each do |chord|
        position = place_rests(voice, position, values.rests(time, chord.onset))
        onsets[chord.onset] = voice.place(position, values.value(chord.onset, chord.release), yield(chord))
        position = onsets[chord.onset].next_position
        time = chord.release
      end
      place_rests(voice, position, values.rests(time, @layout.end_time))
      onsets
    end

    def place_rests(voice, position, rests)
      rests.reduce(position) { |at, (_time, value)| voice.place(at, value).next_position }
    end

    def sounds(part_key, chord, pitches)
      return pitches.fetch(chord) unless part_key.percussion?

      chord.keys.map { |key| InstrumentMap.sound(key) }
    end

    # The program in force on the part's channel at its first note.
    def instrument(part_key)
      return if part_key.percussion?

      first_on = sequence.tracks[part_key.track].notes.find { |note| note.channel == part_key.channel }.on
      change = program_changes.fetch(part_key.channel, []).take_while { |event| event.tick <= first_on }.last
      return unless change

      InstrumentMap.instrument(change.program, hint: sequence.tracks[part_key.track].name)
    end

    def program_changes
      @program_changes ||= sequence.merged_events.grep(ProgramChange).group_by(&:channel)
    end

    def lyrics
      sequence.indexed_events.filter_map do |track_index, event|
        next unless event.is_a?(Text) && event.kind == :lyric

        [PartKey.new(track: track_index, channel: nil), @quantizer.snap(event.tick), event.text]
      end
    end
  end
end
