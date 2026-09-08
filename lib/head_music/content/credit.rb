# A module for musical content
module HeadMusic::Content; end

# One person credited in one role. Level-agnostic: the Credits collection that
# holds it is what constrains which roles are admissible.
HeadMusic::Content::Credit = Data.define(:person, :role) do
  def self.from_h(hash)
    new(person: hash["person"], role: hash["role"])
  end

  def initialize(person:, role:)
    super(person: ensure_person(person), role: HeadMusic::Content::Role.get(role))
  end

  def to_s
    "#{person} (#{role})"
  end

  def to_h
    {"role" => role.key.to_s, "person" => person.to_h}
  end

  private

  def ensure_person(person)
    return person if person.is_a?(HeadMusic::Content::Person)
    return HeadMusic::Content::Person.from_h(person) if person.is_a?(Hash)

    HeadMusic::Content::Person.new(full_name: person.to_s)
  end
end
