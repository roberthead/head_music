# A module for musical content
module HeadMusic::Content; end

# An ordered set of staves joined by a brace or a bracket: a piano's two, a
# harp's two, an organ's three, or the single staff most parts use.
class HeadMusic::Content::StaffSystem
  BRACKETS = %i[brace bracket none].freeze

  attr_reader :staves, :bracket

  def initialize(staves: nil, bracket: :none)
    raise ArgumentError, "bracket must be one of: #{BRACKETS.join(", ")}" unless BRACKETS.include?(bracket)

    @staves = Array(staves)
    @staves = [HeadMusic::Content::Staff.new] if @staves.empty?
    @bracket = bracket
  end

  # The one-staff system a part falls back to when nothing has said otherwise.
  def self.single_staff(clef: nil)
    new(staves: [HeadMusic::Content::Staff.new(clef: clef)])
  end

  # A grand staff, treble over bass, as a piano or harp uses.
  def self.grand_staff
    new(staves: [HeadMusic::Content::Staff.new(clef: :treble_clef), HeadMusic::Content::Staff.new(clef: :bass_clef)],
      bracket: :brace)
  end

  def first_staff
    staves.first
  end

  def include?(staff)
    staves.any? { |candidate| candidate.equal?(staff) }
  end

  def length
    staves.length
  end

  def to_s
    "#{length}-staff #{bracket}"
  end

  def to_h
    {"bracket" => bracket.to_s, "staves" => staves.map(&:to_h)}
  end
end
