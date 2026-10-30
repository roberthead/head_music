module HeadMusic::Notation::MEI
  # The pieces each voice is written as, bar by bar: every link of every tied
  # chain the bar splitter leaves, with its MEI @tie, graces, and id.
  class WrittenItems
    # One written piece of a voice event in a bar: a link of the segment's
    # tied chain. Tie is the MEI @tie across the whole written chain, and
    # graces are the voice event's, on its first piece only. A measure rest
    # stands for the whole segment.
    Item = Data.define(:segment, :link_index, :link, :tie, :graces, :id, :measure_rest) do
      def voice_event
        segment.voice_event
      end

      def rest?
        voice_event.rest?
      end

      # Whether the grace note before piece +index+ ties a pitch into it. The
      # graces are pieces 0 on, and the item itself is the piece after them.
      def tied_from_grace?(index, pitch)
        index.positive? && graces[index - 1].tied_pitches.include?(pitch)
      end

      # Whether a pitch of piece +index+ continues a tie, from a grace note
      # or, for the item itself, from the link before it.
      def tied_into?(index, pitch)
        (index == graces.length) ? %w[m t].include?(note_tie(pitch)) : tied_from_grace?(index, pitch)
      end

      # The @tie of a pitch of the item itself, which a tie from its last
      # grace note continues into.
      def note_tie(pitch)
        return tie unless tied_from_grace?(graces.length, pitch)

        {nil => "t", "i" => "m"}.fetch(tie, tie)
      end
    end

    def self.segment_length(segment)
      segment.fraction || segment.voice_event.rhythmic_duration.fraction
    end

    attr_reader :plan

    def initialize(plan)
      @plan = plan
      @items_by_voice = plan.flow.voices.to_h { |voice| [voice, voice_items(voice)] }.compare_by_identity
    end

    def items(voice, bar_number)
      @items_by_voice[voice].fetch(bar_number, [])
    end

    def items_of(voice_event)
      items_by_voice_event.fetch(voice_event)
    end

    private

    def items_by_voice_event
      @items_by_voice_event ||= @items_by_voice.values.flat_map { |by_bar| by_bar.values.flatten(1) }
        .group_by(&:voice_event).compare_by_identity
    end

    def voice_items(voice)
      links = HeadMusic::Notation::WrittenLinks.for(plan.segments_by_bar(voice).values.flatten(1), error_class: RenderError)
      links.chunk_while { |link, following| link.segment.voice_event.equal?(following.segment.voice_event) }
        .flat_map { |chain| chain_items(voice, chain) }
        .group_by { |item| item.segment.bar_number }
    end

    def chain_items(voice, chain)
      chain.each_with_index.filter_map do |link, index|
        measure_rest = measure_rest?(link.segment)
        item(voice, link, tie(link.segment.voice_event, index, chain.length), measure_rest) unless measure_rest && link.index.positive?
      end
    end

    def item(voice, link, tie, measure_rest)
      graces = graces(link)
      [link.rhythmic_value, *graces.map(&:rhythmic_value)].each { |value| Durations.dur(value) }
      Item.new(
        segment: link.segment, link_index: link.index, link: link, tie: tie, graces: graces,
        id: plan.ids.link(plan.event_id(voice, segment_position(link.segment)), link.index),
        measure_rest: measure_rest
      )
    end

    def graces(link)
      (link.segment.elapsed.zero? && link.index.zero?) ? link.segment.voice_event.grace_notes : []
    end

    def tie(voice_event, index, length)
      return nil if voice_event.rest? || length == 1
      return "i" if index.zero?

      (index == length - 1) ? "t" : "m"
    end

    def measure_rest?(segment)
      voice_event = segment.voice_event
      voice_event.rest? && !voice_event.rhythmic_duration.tuplet? &&
        self.class.segment_length(segment) == plan.bar_length(segment.bar_number)
    end

    def segment_position(segment)
      return segment.voice_event.position if segment.elapsed.zero?

      plan.flow.position(segment.bar_number, 1, 0, 0)
    end
  end
end
