module HeadMusic::Notation::MEI
  # The numbers MEI gives a flow's parts, voices, and staves: parts and staves
  # through the score from 1, and each voice by its place in its part.
  class StaffNumbering
    Entry = Data.define(:number, :part, :part_number, :staff, :index_in_part)

    attr_reader :flow

    def initialize(flow)
      @flow = flow
    end

    def entries
      @entries ||= flow.parts.flat_map { |part| part_entries(part) }
        .each_with_index.map { |entry, index| entry.with(number: index + 1) }
    end

    def entries_of(part)
      entries.select { |entry| entry.part.equal?(part) }
    end

    # The staff a voice is written on in a bar.
    def entry(voice, bar_number)
      staff = voice.staff_at(bar_number)
      entries_of(voice.part).find { |entry| entry.staff.equal?(staff) }
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

    private

    def part_entries(part)
      part.staff_system.staves.each_with_index.map do |staff, index|
        Entry.new(number: nil, part: part, part_number: part_number(part), staff: staff, index_in_part: index)
      end
    end

    def part_numbers
      @part_numbers ||= numbered(flow.parts)
    end

    def voice_numbers
      @voice_numbers ||= flow.parts.map { |part| numbered(part.voices) }.reduce({}.compare_by_identity, :merge!)
    end

    def numbered(list)
      list.each_with_index.to_h { |item, index| [item, index + 1] }.compare_by_identity
    end
  end
end
