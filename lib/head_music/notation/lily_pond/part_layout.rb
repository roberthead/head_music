# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # The parts, staves, and voices of a flow that a document's streams go to.
  # A stream outside a staff group is a voice, and a part, of its own. A
  # staff group is one part, whose staff system holds the group's staves in
  # order.
  class PartLayout
    def initialize(flow, document)
      @flow = flow
      @document = document
      @voices_by_stream = {}.compare_by_identity
      @parts_by_group = {}.compare_by_identity
      @staves_by_group_staff = {}.compare_by_identity
      @staves_by_name = {}.compare_by_identity
    end

    # A silent staff keeps its place in the system without a voice, since
    # that is how the writer renders a staff nobody is written on.
    def voice_for(stream)
      group_staff = stream.group_staff
      return ungrouped_voice(stream) unless group_staff

      part = part_for(group_staff.group)
      return if stream.silent? && stream.role.nil?

      voice = part.add_voice(role: stream.role)
      staff = staves_by_group_staff[group_staff]
      voice.assign_staff(HeadMusic::Time::MusicalPosition::DEFAULT_FIRST_BAR, staff) unless staff.equal?(part.staff_system.first_staff)
      voice
    end

    def staff_named(part, name)
      staves_by_name.fetch(part, {})[name]
    end

    # A staff outside a group may hold several voices, each read as a part of
    # its own, so its dynamics go to each of them.
    def dynamics_parts(target)
      return [parts_by_group[target]].compact if target.is_a?(Document::Group)

      target.filter_map { |stream| voices_by_stream[stream]&.part }
    end

    private

    attr_reader :flow, :document, :voices_by_stream, :parts_by_group, :staves_by_group_staff, :staves_by_name

    def ungrouped_voice(stream)
      voices_by_stream[stream] = flow.add_voice(role: stream.role)
    end

    def part_for(group)
      parts_by_group[group] ||= begin
        staves = group.staves.map { |group_staff| staves_by_group_staff[group_staff] = HeadMusic::Content::Staff.new(clef: clef_key(group_staff)) }
        part = flow.add_part(staff_system: HeadMusic::Content::StaffSystem.new(staves: staves, bracket: group.bracket))
        staves_by_name[part] = group.staves.zip(staves).reverse.to_h { |group_staff, staff| [group_staff.name, staff] }
        part
      end
    end

    # The clef a staff's first voice opens with, where the writer puts it.
    def clef_key(group_staff)
      name = document.streams.select { |stream| stream.group_staff.equal?(group_staff) }.filter_map(&:opening_clef).first
      name && clef_keys[name]
    end

    def clef_keys
      @clef_keys ||= VoiceWriter::CLEF_NAMES.to_h { |key, name| [name.delete('"'), key] }
    end
  end
end
