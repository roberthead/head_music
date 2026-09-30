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
  class SpanMarks
    BRACKETS = {slur: %w[( )], phrase: %w[\\( \\)]}.freeze

    def initialize(voice)
      @voice = voice
      @flow = voice.flow
      @opens = Hash.new { |hash, key| hash[key] = [] }
      @closes = Hash.new { |hash, key| hash[key] = [] }
      named(voice.spans).each do |span, id|
        opening, closing = BRACKETS.fetch(span.kind)
        name = id && "\\=#{id}"
        @opens[span.from.to_s] << "#{name}#{opening}"
        @closes[span.to.to_s] << "#{name}#{closing}"
      end
    end

    def opens_at(position)
      @opens.fetch(key(position), []).join
    end

    def closes_at(position)
      @closes.fetch(key(position), []).join
    end

    private

    def key(position)
      HeadMusic::Content::Position.new(@flow, position.to_s).to_s
    end

    def named(spans)
      spans.each_with_object([]) do |span, placed|
        open_ids = placed.filter_map { |other, id| id || :plain if other.kind == span.kind && open_at?(other, span.from) }
        id = open_ids.include?(:plain) ? (1..).find { |candidate| !open_ids.include?(candidate) } : nil
        placed << [span, id]
      end
    end

    def open_at?(span, position)
      span.to > position || (span.to == position && in_pieces?(span.to))
    end

    def in_pieces?(position)
      voice_event = @voice.voice_event_at(position)
      !voice_event.rest? && HeadMusic::Notation::BarSplitter.segments_of(voice_event).sum { |segment| segment.rhythmic_value&.tied_chain&.length || 1 } > 1
    end
  end
end
