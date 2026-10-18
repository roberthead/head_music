module HeadMusic::Notation::MEI
  # Reads beam breaks where <beam>, <beamSpan @plist>, and @beam i/m/t
  # differ from the default grouping. Between two beamable notes of a voice
  # that follow one another in a bar, the writer breaks the beam where the
  # later note falls on a beam group's start, so a note gets
  # beam_break_before only where it shares a beam with the note before it
  # against that, or shares none along it. A beam's secondary levels are
  # left to the default.
  class BeamReader < MarkReader
    include HeadMusic::Notation::BeamReading

    Pair = Data.define(:previous, :record)

    def initialize(anchors)
      super
      @previous = {}.compare_by_identity
      @chains = {}.compare_by_identity
      @beams = {}.compare_by_identity
      @pairs = []
    end

    def event(record)
      return if record.grace? || record.chord_member? || record.voice_event.nil?

      previous = @previous[record.voice]
      @previous[record.voice] = record
      read_beams(record)
      @pairs << Pair.new(previous, record) if !record.continuation? && beamed_pair?(previous, record)
    end

    def control(record)
      return unless record.element.name == "beamSpan" && record.plist.length > 1

      record.plist.each { |anchor| beams_of(member_element(anchor.record)) << record.element }
    end

    def apply(_flow)
      @pairs.each do |pair|
        joined = joined?(pair.previous, pair.record)
        pair.record.voice_event.beam_break_before = !joined if joined == group_start?(pair.record)
      end
    end

    private

    def read_beams(record)
      beam = anchors.containers(record).find { |container| container.name == "beam" }
      beams_of(record.element) << beam if beam
      chains = (@chains[record.voice] ||= {})
      link_tokens(record, "beam").each do |type, number|
        chains[number] = Object.new if type == "i" || !chains.key?(number)
        beams_of(record.element) << chains[number]
        chains.delete(number) if type == "t"
      end
    end

    # A chord tone that a @plist names stands for its chord.
    def member_element(record)
      element = record.element
      (record.chord_member? && element.parent.is_a?(REXML::Element) && element.parent.name == "chord") ? element.parent : element
    end

    def beams_of(element)
      @beams[element] ||= []
    end

    def joined?(previous, record)
      later = @beams.fetch(record.element, [])
      @beams.fetch(previous.element, []).any? { |beam| later.any? { |other| other.equal?(beam) } }
    end

    def beamable?(record)
      dur = attribute_of(record, "dur")
      !record.voice_event.rest? && BeamContainers::LEVELS_BY_DUR.key?(dur)
    end
  end
end

HeadMusic::Notation::MEI::MARK_READERS << HeadMusic::Notation::MEI::BeamReader
