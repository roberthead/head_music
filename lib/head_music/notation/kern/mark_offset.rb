# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # Where a dynamic or hairpin mark falls in its bar, as a fraction of a
  # whole note. A mark at a rounded tuplet onset is written at the onset's
  # exact time, so that it shares the note's row.
  module MarkOffset
    module_function

    def in_bar(position, voices = position.flow.voices)
      voice_event = voices.lazy.filter_map { |voice| voice.voice_event_at(position) }.first
      return HeadMusic::Notation::BarSplitter.offset_in_bar(position) unless voice_event

      HeadMusic::Notation::BarSplitter.onset_in_bar(voice_event)
    end
  end
end
