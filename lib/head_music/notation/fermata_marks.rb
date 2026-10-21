# A module for visual music notation
module HeadMusic::Notation
  # Turns the fermata marks a reader finds on voice events into the flow's
  # timeline fermatas, and answers the voice events a writer marks for them.
  #
  # Marks whose sounding intervals overlap form one fermata, from the latest
  # of their starts to the earliest of their ends: the span in which every
  # marked event sounds together. A voice with no mark there is not consulted.
  # A mark holds to the end of its event, or to the next mark on the event,
  # so a tied note can carry one fermata per link.
  class FermataMarks
    Mark = Data.define(:from, :to)

    # The voice events sounding where each fermata begins, in every voice,
    # rests included, each with the fermatas it carries in order. A long
    # note can carry more than one, each beginning on a later link.
    def self.carriers(flow)
      flow.fermatas.each_with_object({}.compare_by_identity) do |fermata, carriers|
        flow.voices.each do |voice|
          voice_event = voice.voice_event_sounding_at(fermata.from)
          next unless voice_event && voice_event.position <= fermata.from

          (carriers[voice_event] ||= []) << fermata
        end
      end
    end

    def initialize
      @starts = {}.compare_by_identity
    end

    # A mark on a voice event, held from the start of the tied link it is
    # written on.
    def add(voice_event, from: voice_event.position)
      (@starts[voice_event] ||= []) << from
    end

    # A mark anchored to a moment rather than an event: one on each event of
    # the voices sounding there, from that moment.
    def add_moment(position, voices)
      voices.each do |voice|
        voice_event = voice.voice_event_sounding_at(position)
        add(voice_event, from: position) if voice_event && voice_event.position <= position
      end
    end

    # A fermata the timeline refuses, such as one overlapping another, is
    # dropped.
    def apply(flow)
      fermatas.each do |from, to|
        flow.add_fermata(from, to: to)
      rescue ArgumentError
        nil
      end
    end

    private

    def marks
      @starts.flat_map do |voice_event, starts|
        starts = starts.uniq(&:to_a).sort_by(&:to_a)
        starts.zip(starts.drop(1)).map { |from, following| Mark.new(from, following || voice_event.next_position) }
      end
    end

    def fermatas
      sorted = marks.uniq { |mark| [mark.from.to_a, mark.to.to_a] }.sort_by { |mark| [mark.from.to_a, mark.to.to_a] }
      sorted.each_with_object([]) do |mark, spans|
        latest = spans.last
        if latest && mark.from < latest[1]
          spans[-1] = [mark.from, [latest[1], mark.to].min]
        else
          spans << [mark.from, mark.to]
        end
      end
    end
  end
end
