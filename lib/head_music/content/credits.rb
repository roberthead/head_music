# A module for musical content
module HeadMusic::Content; end

# The credits attaching at one level — work, project, or publication — and the
# single place the level constraint is enforced.
class HeadMusic::Content::Credits
  include Enumerable

  LEVELS = HeadMusic::Content::Role::LEVELS

  def self.from_h(array, level:)
    new(level, Array(array))
  end

  attr_reader :level, :credits

  def initialize(level, credits = [])
    @level = level&.to_sym
    raise ArgumentError, "unknown credit level: #{level.inspect}" unless LEVELS.include?(@level)

    @credits = Array(credits).map { |credit| ensure_credit(credit) }.freeze
    freeze
  end

  def each(&)
    credits.each(&)
  end

  def add(person, role)
    self.class.new(level, credits + [HeadMusic::Content::Credit.new(person: person, role: role)])
  end

  def for(role)
    wanted = HeadMusic::Content::Role.get(role)
    credits.select { |credit| credit.role == wanted }
  end

  def names(role)
    self.for(role).map { |credit| credit.person.full_name }
  end

  def empty?
    credits.empty?
  end

  def size
    credits.size
  end

  def to_h
    credits.map(&:to_h)
  end

  def ==(other)
    other.is_a?(self.class) && level == other.level && credits == other.credits
  end
  alias_method :eql?, :==

  def hash
    [self.class, level, credits].hash
  end

  private

  def ensure_credit(credit)
    credit = HeadMusic::Content::Credit.from_h(credit) if credit.is_a?(Hash)
    validate_level(credit)
    credit
  end

  def validate_level(credit)
    return if credit.role.level == level

    raise ArgumentError, "#{credit.role.key} is a #{credit.role.level} role, not a #{level} role"
  end
end
