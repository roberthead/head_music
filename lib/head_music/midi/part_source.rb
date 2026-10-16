module HeadMusic::MIDI
  # The parts a sequence makes, by track and then channel: one for each
  # track and channel with notes, so format 0 splits by channel, and in
  # format 1 one of rests for each later track that names a part or sets a
  # program but plays nothing, as MIDI Export writes an empty part.
  class PartSource
    DRUM_KIT = "drum_kit"

    # One part's notes, quantized, with the reader's notes they came from,
    # its track, and the program changes on its channel.
    class Part
      attr_reader :key, :notes

      def initialize(key, notes, sources, track, programs, layout)
        @key = key
        @notes = notes
        @sources = sources
        @track = track
        @programs = programs
        @layout = layout
      end

      def percussion?
        key.percussion?
      end

      # A track name that only repeats the instrument's name, as MIDI
      # Export writes one for a part with no player, names no player. Case
      # counts, so "Soprano" still names the singer of a soprano part.
      def player
        name = track_name
        return if name.nil? || name.strip.empty? || name == instrument&.name.to_s

        HeadMusic::Content::Player.new(name: name)
      end

      def instrument
        @instrument ||= percussion? ? percussion_instrument : instrument_for(opening_program)
      end

      # {bar number => instrument} for each later program change, from the
      # bar of the part's next note on. A program no catalog instrument has
      # keeps the instrument in force.
      def instrument_changes
        return {} if percussion?

        current = instrument
        programs_by_bar.drop(1).each_with_object({}) do |(bar_number, program), changes|
          following = instrument_for(program)
          next if following.nil? || following == current

          changes[bar_number] = following
          current = following
        end
      end

      def sound(key)
        sounds[key] ||= InstrumentMap.sound(key, hint: hint)
      end

      private

      def track_name
        @track.events.find { |event| event.is_a?(Text) && event.kind == :track_name }&.text
      end

      def instrument_name
        @track.events.find { |event| event.is_a?(Text) && event.kind == :instrument_name }&.text
      end

      def hint
        [instrument_name, track_name].compact.first
      end

      def sounds
        @sounds ||= {}
      end

      def instrument_for(program)
        return unless program

        names = [instrument_name, track_name].compact
        matching = names.find { |name| HeadMusic::Instruments::Instrument.get(name)&.gm_program == program }
        InstrumentMap.instrument(program, hint: matching || names.first)
      end

      # A part of rests takes its first program; any other, the program in
      # force at its first note.
      def opening_program
        notes.empty? ? @programs.first&.program : programs_by_bar.first.last
      end

      # The hint when it names an unpitched instrument, else the one
      # instrument every sound shares, else a drum kit.
      def percussion_instrument
        hinted = hint && HeadMusic::Instruments::Instrument.get(hint)
        return hinted if hinted && !hinted.pitched?

        shared = notes.map { |note| sound(note.key).instrument }.uniq
        (shared.one? && shared.first) || HeadMusic::Instruments::Instrument.get(DRUM_KIT)
      end

      # [bar number, program] at the first note, and wherever a note on
      # finds a program in force other than the one before, the last in a
      # bar winning.
      def programs_by_bar
        @programs_by_bar ||= begin
          index = -1
          previous = :none
          @sources.zip(notes).each_with_object({}) do |(source, note), by_bar|
            index += 1 while index + 1 < @programs.length && @programs[index + 1].tick <= source.on
            program = @programs[index]&.program if index >= 0
            next if program == previous

            by_bar[@layout.bar_at(note.onset).number] = program
            previous = program
          end.to_a
        end
      end
    end

    # [track, index] for each track of format 1 after the first that names
    # a part or sets a program but plays nothing.
    def self.silent_tracks(sequence)
      return [] unless sequence.format == 1

      sequence.tracks.each_with_index.drop(1).select { |track, _index| track.notes.empty? && (track.name || track.program_changes.any?) }
    end

    attr_reader :sequence, :quantizer

    # +notes+ are the reader's notes the quantizer was given, in its order.
    def initialize(sequence, notes, quantizer)
      @sequence = sequence
      @source_notes = notes
      @quantizer = quantizer
    end

    def parts
      @parts ||= (sounding_parts + silent_parts).sort_by { |part| [part.key.track, part.key.channel || -1] }.freeze
    end

    private

    def sounding_parts
      @source_notes.zip(quantizer.notes).group_by { |source, _note| PartKey.for(source) }.map do |key, pairs|
        part(key, pairs.map(&:last), pairs.map(&:first))
      end
    end

    def silent_parts
      self.class.silent_tracks(sequence).map do |track, index|
        programs = track.program_changes
        part(PartKey.new(track: index, channel: programs.first&.channel), [], [], programs)
      end
    end

    # A part with no notes takes its own track's programs; any other, its
    # channel's, from whichever track sets them.
    def part(key, notes, sources, programs = programs_by_channel.fetch(key.channel, []))
      programs = [] if key.percussion?
      Part.new(key, notes, sources, sequence.tracks[key.track], programs, quantizer.layout)
    end

    def programs_by_channel
      @programs_by_channel ||= sequence.merged_events.grep(ProgramChange).group_by(&:channel)
    end
  end
end
