module HeadMusic::Notation::MEI
  # Reads lyrics as syllables of their notes: <verse>/<syl>, a <syl> straight
  # in its <note>, and @syl, the last two as verse 1, as is a <verse> with no
  # @n. A verse's several <syl>s join with "‿", or a space where an <lb/>
  # parts them. Its last syllable's @wordpos "i" or "m", or @con "d", sets
  # hyphen_after; the other @con values, as extenders, set nothing.
  #
  # A Syllable's verse is an integer, so a part's verse @n values that are
  # not, as MEI's NMTOKEN allows, are ranked after its highest numbered verse
  # in order of first appearance.
  #
  # Lyrics on rests, grace notes, and a tie's later links are skipped, as is
  # an empty one and a second syllable for a verse, the first one winning. A
  # chord tone's syllable is its chord's.
  class LyricReader < MarkReader
    ELISION = "‿"
    HYPHEN_WORD_POSITIONS = %w[i m].freeze
    VERSE_NUMBER = /\A[1-9]\d{0,8}\z/

    Sung = Data.define(:part, :voice_event, :label, :text, :hyphen_after)

    def initialize(anchors)
      super
      @sung = []
    end

    def event(record)
      voice_event = record.voice_event
      return unless record.note? && !record.grace? && !record.continuation? && voice_event && !voice_event.rest?

      element = record.element
      anchors.children_named(element, "verse").each do |verse|
        sing(record.part, voice_event, XmlReading.attribute(verse, "n", element: verse) || "1", syllables_of(verse))
      end
      bare = anchors.children_named(element, "syl")
      sing(record.part, voice_event, "1", bare) if bare.any?
      sing_attribute(record.part, voice_event, element)
    end

    def apply(_flow)
      @sung.group_by(&:part).each_value do |sung|
        verses = verse_numbers(sung.map(&:label).uniq)
        sung.each do |syllable|
          verse = verses.fetch(syllable.label)
          next if syllable.voice_event.syllable(verse)

          syllable.voice_event.sing(syllable.text, verse: verse, hyphen_after: syllable.hyphen_after)
        end
      end
    end

    private

    def verse_numbers(labels)
      numbered, named = labels.partition { |label| label.match?(VERSE_NUMBER) }
      numbers = numbered.to_h { |label| [label, Integer(label, 10)] }
      highest = numbers.values.max || 0
      numbers.merge(named.each_with_index.to_h { |label, index| [label, highest + index + 1] })
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

    def sing(part, voice_event, label, pieces)
      syls = pieces.grep(REXML::Element)
      return if syls.empty?

      text = joined(pieces)
      @sung << Sung.new(part, voice_event, label, text, hyphen_after?(syls.last)) unless text.empty?
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

    def sing_attribute(part, voice_event, element)
      text = XmlReading.attribute(element, "syl", element: element).to_s.gsub(/\s+/, " ")
      @sung << Sung.new(part, voice_event, "1", text, false) unless text.empty?
    end
  end
end

HeadMusic::Notation::MEI::MARK_READERS << HeadMusic::Notation::MEI::LyricReader
