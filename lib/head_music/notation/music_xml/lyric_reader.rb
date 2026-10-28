require_relative "mark_reader"

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # Reads lyrics, as syllables of their note events.
  #
  # A lyric's number is its verse, and one with no number is verse 1. A
  # Syllable's verse is an integer, so when any number in a part is not, the
  # part's verses are ranked in order of first appearance instead. Lyrics on
  # rests, grace notes, and a tie's later links are skipped, as is a second
  # syllable for a verse.
  #
  # A lyric holding only an <extend>, of type continue, stop, or none, marks
  # a held note of the melisma before it. A syllable whose line has no such marks
  # after it, from a bare <extend/> or one of type start, or a hyphenated
  # syllable, holds the notes after it as MelismaFill places them. A held
  # note with nothing before it to hold is skipped.
  class LyricReader < MarkReader
    ELISION = "‿"
    SYLLABIC_HYPHENS = %w[begin middle].freeze

    Sung = Struct.new(:part, :voice_event, :label, :text, :hyphen_after, :extend)

    def initialize
      @sung = []
    end

    def note(record)
      voice_event = record.voice_event
      return if record.grace? || record.continuation? || voice_event.nil? || voice_event.rest?

      XmlReading.children(record.element, "lyric").each do |lyric|
        text = lyric_text(lyric)
        extend = XmlReading.children(lyric, "extend").first
        next if text.empty? && extend.nil?

        label = XmlReading.attribute(lyric, "number") || "1"
        @sung << Sung.new(record.part, voice_event, label, text, hyphen_after?(lyric), extend_type(extend))
      end
    end

    def apply(_flow)
      @sung.group_by(&:part).each_value do |sung|
        verses = verse_numbers(sung.map(&:label).uniq)
        held, sung = sung.partition { |syllable| syllable.text.empty? }
        sung.each { |syllable| sing(syllable, verses.fetch(syllable.label)) }
        held.sort_by { |syllable| syllable.voice_event.position }.each { |syllable| hold(syllable, verses.fetch(syllable.label)) }
        sung.each { |syllable| fill(syllable, verses.fetch(syllable.label)) }
      end
    end

    private

    # An <elision> joins the text on either side of it, as in "di‿a".
    def lyric_text(lyric)
      pieces = []
      lyric.each_element do |child|
        case child.name
        when "text" then pieces << XmlReading.text(child).to_s
        when "elision" then pieces << elision_text(child) if pieces.any?
        end
      end
      pieces.join
    end

    def elision_text(elision)
      text = XmlReading.text(elision)
      (text.nil? || text.empty?) ? ELISION : text
    end

    # With an elision the last <syllabic> tells whether the word goes on.
    def hyphen_after?(lyric)
      SYLLABIC_HYPHENS.include?(XmlReading.text(XmlReading.children(lyric, "syllabic").last))
    end

    def extend_type(extend)
      return unless extend

      XmlReading.attribute(extend, "type") || "bare"
    end

    def verse_numbers(labels)
      if labels.all? { |label| label.match?(/\A[1-9]\d*\z/) }
        labels.to_h { |label| [label, Integer(label, 10)] }
      else
        labels.each_with_index.to_h { |label, index| [label, index + 1] }
      end
    end

    def hold(syllable, verse)
      return if syllable.extend == "start"

      syllable.voice_event.extend_syllable(verse: verse)
    rescue ArgumentError
      nil
    end

    def fill(syllable, verse)
      return unless syllable.hyphen_after || syllable.extend
      return unless syllable.voice_event.syllable(verse)&.text == syllable.text
      # A word's line ends where its continue and stop marks say.
      return if !syllable.hyphen_after && syllable.voice_event.melisma_continues_after?(verse)

      HeadMusic::Notation::MelismaFill.fill(syllable.voice_event, verse)
    end

    def sing(syllable, verse)
      note_event = syllable.voice_event
      return if note_event.syllable(verse)

      note_event.sing(syllable.text, verse: verse, hyphen_after: syllable.hyphen_after)
    rescue ArgumentError
      nil
    end
  end
end
