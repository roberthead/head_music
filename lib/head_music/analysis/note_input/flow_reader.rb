class HeadMusic::Analysis::NoteInput
  # Reads a flow's pitched sounds as unspelled notes, in written order rather
  # than performance order, so a repeat is not counted twice. Bars are laid end
  # to end as MIDI export lays them: a pickup sounds from its first note. Each
  # note's voice is [part index, voice index] and its address the path to its
  # sound in flow.to_h, such as
  # ["parts", 0, "voices", 1, "voice_events", 7, "sounds", 0], or, for a
  # grace note, [..., "voice_events", 7, "grace_notes", 0, "sounds", 0].
  class FlowReader
    Entry = Data.define(:voice_event, :path, :voice, :bar_number, :offset)

    attr_reader :flow

    def initialize(flow)
      @flow = flow
    end

    def note_input
      @notes = []
      @addresses = []
      entries.each { |entry| read(entry) }
      HeadMusic::Analysis::NoteInput.new(@notes, bar_starts, flow: flow, addresses: @addresses)
    end

    private

    def read(entry)
      voice_event = entry.voice_event
      onset = bar_starts.fetch(entry.bar_number) + entry.offset - window_from(entry.bar_number)
      voice_event.grace_notes.each_with_index do |grace_note, index|
        add_sounds(grace_note.sounds, [*entry.path, "grace_notes", index], entry.voice, onset, 0)
      end
      add_sounds(voice_event.sounds, entry.path, entry.voice, onset, voice_event.rhythmic_value.fraction)
    end

    def add_sounds(sounds, path, voice, onset, duration)
      sounds.each_with_index do |sound, index|
        next unless sound.pitched?

        @notes << UnspelledNote.new(number: sound.midi_note_number, onset: onset, duration: duration, voice: voice)
        @addresses << [*path, "sounds", index].freeze
      end
    end

    def entries
      @entries ||= flow.parts.each_with_index.flat_map do |part, part_index|
        part.voices.each_with_index.flat_map do |voice, voice_index|
          voice_entries(voice, ["parts", part_index, "voices", voice_index, "voice_events"], [part_index, voice_index].freeze)
        end
      end
    end

    def voice_entries(voice, prefix, label)
      voice.voice_events.each_with_index.map do |voice_event, index|
        bar_number, offset = HeadMusic::Notation::BarSplitter.exact_start(voice_event)
        Entry.new(voice_event, [*prefix, index], label, bar_number, offset)
      end
    end

    def bar_starts
      @bar_starts ||= begin
        start = 0r
        (flow.earliest_bar_number..flow.last_sounding_bar_number).to_h do |bar_number|
          [bar_number, start].tap { start += bar_length(bar_number) - window_from(bar_number) }
        end
      end
    end

    def bar_length(bar_number)
      HeadMusic::MIDI::PerformanceTimeline.bar_length(flow, bar_number)
    end

    def window_from(bar_number)
      return 0 if bar_number >= 1

      @windows ||= {}
      @windows[bar_number] ||= first_note_offset(bar_number) || bar_length(bar_number)
    end

    def first_note_offset(bar_number)
      entries.filter_map do |entry|
        entry.offset if entry.bar_number == bar_number && entry.voice_event.sounded?
      end.min
    end
  end
end
