module HeadMusic::Notation::MEI
  # The <note>, <chord>, <rest>, and <mRest> elements of the items in a layer,
  # and the grace notes before them.
  class EventWriter
    def initialize(plan)
      @plan = plan
    end

    def element(item)
      return Element.new("mRest", item.id) if item.measure_rest
      return Element.new("rest", item.id, Durations.attributes(item.link.rhythmic_value)) if item.rest?

      sounding_element(item.id, item.link.rhythmic_value, plan.note_ids(item)) { |pitch| tie(item, pitch) }
    end

    def grace_elements(item)
      graces = item.graces
      graces.each_with_index.map do |grace, index|
        tied_in = (index.positive? && graces[index - 1].tied?) ? graces[index - 1].pitches : []
        follower = graces[index + 1]&.pitches || item.voice_event.pitches
        id = plan.grace_id(item, index)
        element = sounding_element(id, grace.rhythmic_value, plan.grace_note_ids(grace, id)) do |pitch|
          tie_value(tied_in.include?(pitch), grace.tied? && follower.include?(pitch))
        end
        element.with(attributes: element.attributes.merge("grace" => grace.slashed? ? "acc" : "unacc"))
      end
    end

    # What stands in a layer for a bar the voice places nothing in.
    def empty_bar_element(voice, bar_number)
      Element.new("mRest", plan.event_id(voice, plan.flow.position(bar_number, 1, 0, 0)))
    end

    private

    attr_reader :plan

    def sounding_element(id, rhythmic_value, note_ids, &tie)
      duration = Durations.attributes(rhythmic_value)
      if note_ids.one?
        pitch, note_id = note_ids.first
        return Element.new("note", note_id, pitch_attributes(pitch).merge(duration, "tie" => tie.call(pitch)))
      end

      notes = note_ids.map { |pitch, note_id| Element.new("note", note_id, pitch_attributes(pitch).merge("tie" => tie.call(pitch))) }
      Element.new("chord", id, duration, notes)
    end

    def pitch_attributes(pitch)
      {"pname" => pitch.letter_name.to_s.downcase, "oct" => pitch.register}
    end

    def tie(item, pitch)
      return item.tie unless tied_from_grace?(item, pitch)

      {nil => "t", "i" => "m"}.fetch(item.tie, item.tie)
    end

    def tied_from_grace?(item, pitch)
      last = item.graces.last
      last&.tied? && last.pitches.include?(pitch)
    end

    def tie_value(stop, start)
      return "m" if stop && start
      return "t" if stop

      "i" if start
    end
  end
end
