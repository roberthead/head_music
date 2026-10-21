module HeadMusic::Notation::MEI
  # Reads fermata marks into the flow's timeline fermatas: @fermata on a
  # note, chord, chord tone, or rest, and <fermata> at the event its
  # @startid names, in any measure, else at its @tstamp, on each voice its
  # @staff and @layer name, or every voice where it names none. A mark on a
  # tie's later link holds from that link. Marks on grace notes are skipped,
  # and a mark written both ways counts once.
  class FermataReader < MarkReader
    MARKABLE_KINDS = %i[note chord rest m_rest].freeze

    def initialize(anchors)
      super
      @marks = HeadMusic::Notation::FermataMarks.new
      @moments = []
    end

    def event(record)
      return unless MARKABLE_KINDS.include?(record.kind) && !record.grace? && record.voice_event
      return if attribute_of(record, "fermata").to_s.empty?

      @marks.add(record.voice_event, from: anchors.anchor(record).position)
    end

    def control(record)
      start = record.start
      return unless record.element.name == "fermata" && start
      return if start.grace_index

      if start.voice_event
        @marks.add(start.voice_event, from: start.position)
      else
        @moments << [start.position, record.voice ? [record.voice] : record.part&.voices]
      end
    end

    def apply(flow)
      @moments.each { |position, voices| @marks.add_moment(position, voices || flow.voices) }
      @marks.apply(flow)
    end
  end
end

HeadMusic::Notation::MEI::MARK_READERS << HeadMusic::Notation::MEI::FermataReader
