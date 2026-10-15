module HeadMusic::Notation::MEI
  # What the MEI writers need of a flow, computed before any writing: the
  # staves, the written pieces of every voice in every bar, and their ids.
  class RenderPlan < HeadMusic::Notation::RenderPlan
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
    end

    # A staff of the score, numbered through the score from 1.
    StaffEntry = Data.define(:number, :part, :part_number, :staff, :index_in_part)

    # The scale types a tonal context can have that MEI's data.MODE names.
    MODES = %w[major minor ionian dorian phrygian lydian mixolydian aeolian locrian].freeze

    attr_reader :mdiv_number

    def initialize(flow, transposed: false, mdiv_number: 1)
      @mdiv_number = mdiv_number
      super(flow, transposed: transposed)
    end

    def ids
      @ids ||= Ids.new(mdiv_number)
    end

    def staff_entries
      @staff_entries ||= flow.parts.each_with_index.flat_map do |part, part_index|
        part.staff_system.staves.each_with_index.map do |staff, index|
          [part, part_index + 1, staff, index]
        end
      end.each_with_index.map do |(part, part_number, staff, index), number|
        StaffEntry.new(number + 1, part, part_number, staff, index)
      end
    end

    def staff_entries_of(part)
      staff_entries.select { |entry| entry.part.equal?(part) }
    end

    # The staff a voice is written on in a bar.
    def staff_entry(voice, bar_number)
      staff = voice.staff_at(bar_number)
      staff_entries_of(voice.part).find { |entry| entry.staff.equal?(staff) }
    end

    def staff_number(voice, bar_number)
      staff_entry(voice, bar_number).number
    end

    def top_staff_number(part)
      staff_entries_of(part).first.number
    end

    def part_number(part)
      part_numbers.fetch(part)
    end

    def voice_number(voice)
      voice_numbers.fetch(voice)
    end

    # The voices of the staff's part written on it in the bar. Each is the
    # layer numbered by its place in the part, on whichever staff it is.
    def layer_voices(entry, bar_number)
      entry.part.voices.select { |voice| voice.staff_at(bar_number).equal?(entry.staff) }
    end

    def items(voice, bar_number)
      items_by_voice[voice].fetch(bar_number, [])
    end

    # Every piece a voice event is written as, in order, across bars.
    def items_of(voice_event)
      items_by_voice_event.fetch(voice_event)
    end

    # The one instance of an extension class for this plan, so that a class
    # registered with several hooks computes once.
    def source(source_class)
      @sources ||= {}.compare_by_identity
      @sources[source_class] ||= source_class.new(self)
    end

    def event_id(voice, position)
      ids.event(part_number(voice.part), voice_number(voice), position)
    end

    # The pitches of an item low to high, each with the id of its note.
    def note_ids(item)
      pitches = item.voice_event.pitches.sort
      return [[pitches.first, item.id]] if pitches.one?

      pitches.each_with_index.map { |pitch, index| [pitch, ids.chord_member(item.id, index)] }
    end

    def grace_id(item, index)
      ids.grace(item.id, index)
    end

    def grace_note_ids(grace, grace_id)
      pitches = grace.pitches.sort
      return [[pitches.first, grace_id]] if pitches.one?

      pitches.each_with_index.map { |pitch, index| [pitch, ids.chord_member(grace_id, index)] }
    end

    def bar_length(bar_number)
      meter = effective_meter(bar_number)
      Rational(meter.top_number, meter.bottom_number)
    end

    # The final bar, where the music ends before the meter does.
    def underfull?(bar_number)
      return false unless bar_number == bar_numbers.last

      flow.voices.map { |voice| written_length(voice, bar_number) }.max < bar_length(bar_number)
    end

    # The key signature event a part is written in at a bar: the sounding one,
    # or in a transposed plan the part's instrument's written key.
    def written_key_event(part, bar_number)
      event = effective_key_event(bar_number)
      transposition = transposition_at(part, bar_number)
      transposition ? transposition.key_signature_event(event) : event
    end

    # The @key.mode of the sounding key at the opening, or nil where its tonal
    # context is unknown or not one MEI names.
    def first_measure_key_mode
      key_mode(effective_key_event(bar_numbers.first))
    end

    # The @key.mode of the sounding key change at a bar, if there is one.
    def key_mode_change(bar_number)
      event = flow.key_signature_changes[bar_number]
      event && key_mode(event)
    end

    def midi_bpm(tempo)
      Decimals.format(Rational(tempo.beats_per_minute.to_s) * tempo.beat_value.fraction * 4)
    end

    def written_length(voice, bar_number)
      segments_by_bar(voice).fetch(bar_number, []).sum { |segment| segment_length(segment) }
    end

    private

    def precompute_eager_data
      super
      items_by_voice
      extension_classes.each { |source_class| source(source_class) }
    end

    def extension_classes
      [
        *EventWriter.attribute_sources, *EventWriter.child_sources,
        *MeasureWriter.attribute_sources, *MeasureWriter.control_sources,
        *SectionWriter.pre_measure_sources, SectionWriter.bar_group,
        *ScoreDefWriter.staff_def_attribute_sources
      ].compact
    end

    def key_value(event)
      signature = event.signature
      return "0" if signature.zero?

      signature.positive? ? "#{signature}s" : "#{-signature}f"
    end

    def key_mode(event)
      mode = event.tonal_context&.scale_type&.name.to_s
      mode if MODES.include?(mode)
    end

    def part_numbers
      @part_numbers ||= flow.parts.each_with_index.to_h { |part, index| [part, index + 1] }.compare_by_identity
    end

    def voice_numbers
      @voice_numbers ||= flow.parts.each_with_object({}.compare_by_identity) do |part, numbers|
        part.voices.each_with_index { |voice, index| numbers[voice] = index + 1 }
      end
    end

    def items_by_voice
      @items_by_voice ||= flow.voices.each_with_object({}.compare_by_identity) do |voice, items|
        items[voice] = build_items(voice).group_by { |item| item.segment.bar_number }
      end
    end

    def items_by_voice_event
      @items_by_voice_event ||= items_by_voice.values.flat_map { |by_bar| by_bar.values.flatten(1) }
        .group_by(&:voice_event).compare_by_identity
    end

    def build_items(voice)
      segments = segments_by_bar(voice).values.flatten(1)
      links = HeadMusic::Notation::WrittenLinks.for(segments, error_class: RenderError)
      links.chunk_while { |link, following| link.segment.voice_event.equal?(following.segment.voice_event) }
        .flat_map { |chain| chain_items(voice, chain) }
    end

    def chain_items(voice, chain)
      chain.each_with_index.filter_map do |link, index|
        measure_rest = measure_rest?(link.segment)
        next if measure_rest && link.index.positive?

        graces = (link.segment.elapsed.zero? && link.index.zero?) ? link.segment.voice_event.grace_notes : []
        [link.rhythmic_value, *graces.map(&:rhythmic_value)].each { |value| Durations.dur(value) }
        Item.new(
          segment: link.segment, link_index: link.index, link: link,
          tie: tie(link.segment.voice_event, index, chain.length), graces: graces,
          id: ids.link(event_id(voice, segment_position(link.segment)), link.index),
          measure_rest: measure_rest
        )
      end
    end

    def tie(voice_event, index, length)
      return nil if voice_event.rest? || length == 1
      return "i" if index.zero?

      (index == length - 1) ? "t" : "m"
    end

    def measure_rest?(segment)
      segment.voice_event.rest? && !segment.voice_event.rhythmic_value.tuplet? &&
        segment_length(segment) == bar_length(segment.bar_number)
    end

    def segment_length(segment)
      segment.fraction || segment.voice_event.rhythmic_value.fraction
    end

    def segment_position(segment)
      return segment.voice_event.position if segment.elapsed.zero?

      flow.position(segment.bar_number, 1, 0, 0)
    end
  end
end
