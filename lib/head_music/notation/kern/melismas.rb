# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # A voice's held notes, marked once every event is placed: those a lone
  # "_" or "|" marks, in order, then those after an extended or hyphenated
  # syllable, which hold up to the next sung note or rest. A held mark with
  # nothing before it to hold is dropped.
  class Melismas
    def initialize
      @sung = []
    end

    def add(note_event, syllables)
      @sung << [note_event, syllables] unless syllables.empty?
    end

    def apply
      @sung.each do |note_event, syllables|
        syllables.select(&:held?).each { |syllable| hold(note_event, syllable.verse) }
      end
      @sung.each do |note_event, syllables|
        syllables.select { |syllable| syllable.extended || syllable.hyphen_after }.each do |syllable|
          HeadMusic::Notation::MelismaFill.fill(note_event, syllable.verse)
        end
      end
    end

    private

    def hold(note_event, verse)
      note_event.extend_syllable(verse: verse)
    rescue ArgumentError
      nil
    end
  end
end
