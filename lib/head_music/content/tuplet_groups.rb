# A module for musical content
module HeadMusic::Content; end

# The tuplet groups of a voice, kept in order. Groups may touch but not
# overlap, since a group within a group would be a nested tuplet. Every
# lookup is a binary search, as a voice may hold thousands.
class HeadMusic::Content::TupletGroups
  include Enumerable

  delegate :each, :empty?, :length, to: :@groups

  def initialize
    @groups = []
  end

  def add(group)
    index = @groups.bsearch_index { |existing| existing >= group } || @groups.length
    # Groups already held never overlap, so only the neighbors can.
    neighbors = [(@groups[index - 1] if index.positive?), @groups[index]].compact
    overlapped = neighbors.find { |existing| existing.overlaps?(group) }
    raise ArgumentError, "nested tuplets are not supported: the #{group} overlaps the #{overlapped}" if overlapped

    @groups.insert(index, group)
    group
  end

  # The group covering a position, from its start up to its end.
  def at(position)
    group = @groups.bsearch { |existing| existing.to > position }
    group if group&.covers?(position)
  end

  def to_a
    @groups.dup
  end
end
