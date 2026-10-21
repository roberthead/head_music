module HeadMusic::Notation::MEI
  # A <fermata> for each voice event sounding where a timeline fermata
  # begins, in every voice, rests included, at the written piece of it that
  # sounds there, on that piece's staff.
  class FermataControls
    # A carrier's onset may be rounded from its exact one by up to half a
    # subtick.
    TOLERANCE = Rational(1, HeadMusic::Rudiment::Rhythm::SUBTICKS_PER_WHOLE)

    def initialize(plan)
      @plan = plan
    end

    def controls
      HeadMusic::Notation::FermataMarks.carriers(plan.flow).map { |voice_event, fermata| control(voice_event, fermata.from) }
    end

    private

    attr_reader :plan

    def control(voice_event, from)
      item = piece_at(voice_event, from)
      bar_number = item.segment.bar_number
      attributes = {"startid" => "##{item.id}", "staff" => plan.staff_number(voice_event.voice, bar_number)}
      BarElement.new(bar_number, Element.new("fermata", plan.ids.item_container("fermata", item.id), attributes))
    end

    def piece_at(voice_event, from)
      target = [from.bar_number, HeadMusic::Notation::BarSplitter.offset_in_bar(from) + TOLERANCE]
      plan.items_of(voice_event).select { |item| (item.link.onset <=> target) <= 0 }.last ||
        plan.items_of(voice_event).first
    end
  end

  MeasureWriter.control_sources << FermataControls
end
