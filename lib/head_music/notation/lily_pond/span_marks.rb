# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # The slur and phrasing-slur marks of one voice's spans, by the position of
  # the voice event that carries them.
  #
  # LilyPond holds one slur, and one phrasing slur, open at a time, so a span
  # that begins while another of its kind is open is named with \=, as
  # \=1( … \=1), and only then. A span that begins where another ends is not
  # open with it, since the close is written first, unless that note is
  # written in pieces: then the open goes on the first and the close on the
  # last.
  #
  # A span from grace notes opens on the first of them. A slur from them to
  # their main note that needs no name is left to \acciaccatura or
  # \appoggiatura, which imply it, so it writes no marks at all.
  class SpanMarks
    BRACKETS = {slur: %w[( )], phrase: %w[\\( \\)]}.freeze

    def initialize(voice)
      @voice = voice
      @flow = voice.flow
      @opens = Hash.new { |hash, key| hash[key] = [] }
      @grace_opens = Hash.new { |hash, key| hash[key] = [] }
      @closes = Hash.new { |hash, key| hash[key] = [] }
      @implied = Set.new
      named(voice.spans.select(&:curve?)).each { |span, id| add(span, id) }
    end

    def opens_at(position)
      @opens.fetch(key(position), []).join
    end

    def grace_opens_at(position)
      @grace_opens.fetch(key(position), []).join
    end

    def closes_at(position)
      @closes.fetch(key(position), []).join
    end

    # Whether the grace notes before the note event at the position carry a
    # slur to it that their command implies.
    def implied_grace_slur?(position)
      @implied.include?(key(position))
    end

    private

    def add(span, id)
      return @implied << key(span.from) if implied?(span, id)

      opening, closing = BRACKETS.fetch(span.kind)
      name = id && "\\=#{id}"
      (span.from_grace? ? @grace_opens : @opens)[key(span.from)] << "#{name}#{opening}"
      @closes[key(span.to)] << "#{name}#{closing}"
    end

    # One command implies one slur, so the grace notes must share a slash.
    def implied?(span, id)
      return false unless span.from_grace? && span.kind == :slur && span.to == span.from && id.nil?

      @voice.voice_event_at(span.from).grace_notes.map(&:slashed?).uniq.length == 1
    end

    def key(position)
      HeadMusic::Content::Position.new(@flow, position.to_s).to_s
    end

    def named(spans)
      spans.each_with_object([]) do |span, placed|
        open_ids = placed.filter_map { |other, id| id || :plain if other.kind == span.kind && open_at?(other, span) }
        id = open_ids.include?(:plain) ? (1..).find { |candidate| !open_ids.include?(candidate) } : nil
        placed << [span, id]
      end
    end

    # Grace notes come before their main note, so a span ending on that note
    # is still open across them.
    def open_at?(other, span)
      position = span.from
      return other.to >= position if span.from_grace?

      other.to > position || (other.to == position && in_pieces?(other.to))
    end

    def in_pieces?(position)
      voice_event = @voice.voice_event_at(position)
      !voice_event.rest? && HeadMusic::Notation::BarSplitter.segments_of(voice_event).sum { |segment| segment.rhythmic_duration&.values&.length || 1 } > 1
    end
  end
end
