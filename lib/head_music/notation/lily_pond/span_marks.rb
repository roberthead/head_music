# A namespace for LilyPond-notation rendering helpers
module HeadMusic::Notation::LilyPond
  # The slur and phrasing-slur marks of one voice's spans, by the position of
  # the voice event that carries them.
  #
  # LilyPond holds one slur, and one phrasing slur, open at a time, so a span
  # that begins while another of its kind is open is named with \=, as
  # \=1( … \=1), and only then. A span that begins where another ends is not
  # open with it, since the close is written first.
  class SpanMarks
    BRACKETS = {slur: %w[( )], phrase: %w[\\( \\)]}.freeze

    def initialize(voice)
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
        open_ids = placed.filter_map { |other, id| id || :plain if other.kind == span.kind && other.to > span.from }
        id = open_ids.include?(:plain) ? (1..).find { |candidate| !open_ids.include?(candidate) } : nil
        placed << [span, id]
      end
    end
  end
end
