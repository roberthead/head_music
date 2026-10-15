module HeadMusic::Notation::MEI
  # Reads lyrics as syllables of their notes: <verse>/<syl>, a <syl> straight
  # in its <note>, and @syl, the last two as verse 1, as is a <verse> with no
  # @n. A verse's several <syl>s join with "‿", or a space where an <lb/>
  # parts them. Its last syllable's @wordpos "i" or "m", or @con "d", sets
  # hyphen_after; the other @con values, as extenders, set nothing.
  #
  # Lyrics on rests, grace notes, and a tie's later links are skipped, as is
  # a verse whose @n is no number, an empty one, and a second syllable for
  # a verse, the first one winning. A chord tone's syllable is its chord's.
  class LyricReader < MarkReader
    ELISION = "‿"
    HYPHEN_WORD_POSITIONS = %w[i m].freeze
    VERSE_NUMBER = /\A[1-9]\d{0,8}\z/

    Sung = Data.define(:voice_event, :verse, :text, :hyphen_after)

    def initialize(anchors)
      super
      @sung = []
    end

    def event(record)
      voice_event = record.voice_event
      return unless record.note? && !record.grace? && !record.continuation? && voice_event && !voice_event.rest?

      element = record.element
      anchors.children_named(element, "verse").each { |verse| sing(voice_event, verse_number(verse), syllables_of(verse)) }
      bare = anchors.children_named(element, "syl")
      sing(voice_event, 1, bare) if bare.any?
      sing_attribute(voice_event, element)
    end

    def apply(_flow)
      @sung.each do |sung|
        next if sung.voice_event.syllable(sung.verse)

        sung.voice_event.sing(sung.text, verse: sung.verse, hyphen_after: sung.hyphen_after)
      end
    end

    private

    def verse_number(verse)
      value = XmlReading.attribute(verse, "n", element: verse)
      return 1 if value.nil?

      Integer(value, 10) if value.match?(VERSE_NUMBER)
    end

    # The <syl>s of a verse, with :line_break where an <lb/> stands.
    def syllables_of(verse)
      anchors.children(verse).filter_map do |child|
        case child.name
        when "syl" then child
        when "lb" then :line_break
        end
      end
    end

    def sing(voice_event, verse, pieces)
      syls = pieces.grep(REXML::Element)
      return if verse.nil? || syls.empty?

      text = joined(pieces)
      @sung << Sung.new(voice_event, verse, text, hyphen_after?(syls.last)) unless text.empty?
    end

    def joined(pieces)
      text = +""
      joiner = nil
      pieces.each do |piece|
        next joiner = " " if piece == :line_break

        syllable = anchors.text(piece)
        next if syllable.empty?

        text << joiner.to_s unless text.empty?
        text << syllable
        joiner = ELISION
      end
      text
    end

    def hyphen_after?(syl)
      HYPHEN_WORD_POSITIONS.include?(XmlReading.attribute(syl, "wordpos", element: syl)) ||
        XmlReading.attribute(syl, "con", element: syl) == "d"
    end

    def sing_attribute(voice_event, element)
      text = XmlReading.attribute(element, "syl", element: element).to_s.gsub(/\s+/, " ")
      @sung << Sung.new(voice_event, 1, text, false) unless text.empty?
    end
  end
end

HeadMusic::Notation::MEI::MARK_READERS << HeadMusic::Notation::MEI::LyricReader
