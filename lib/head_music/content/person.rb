# A module for musical content
module HeadMusic::Content; end

# A person who may be credited on a work, project, or publication.
#
# One identity, not one spelling of a name: two spellings of a composer are one
# Person.
HeadMusic::Content::Person = Data.define(:full_name, :sort_name, :birth_year, :death_year) do
  def self.from_h(hash)
    values = hash.transform_keys(&:to_sym)
    new(
      full_name: values[:full_name],
      sort_name: values[:sort_name],
      birth_year: values[:birth_year],
      death_year: values[:death_year]
    )
  end

  # The sort name is resolved here rather than in the reader so that a person
  # given no sort name equals the same person given the obvious one.
  def initialize(full_name:, sort_name: nil, birth_year: nil, death_year: nil)
    validate_years(birth_year, death_year)
    super(
      full_name: full_name.to_s,
      sort_name: (sort_name || full_name).to_s,
      birth_year: birth_year,
      death_year: death_year
    )
  end

  def to_s
    full_name
  end

  def to_h
    {
      "full_name" => full_name,
      "sort_name" => sort_name,
      "birth_year" => birth_year,
      "death_year" => death_year
    }
  end

  private

  def validate_years(birth_year, death_year)
    return unless birth_year && death_year
    return if death_year >= birth_year

    raise ArgumentError, "death year #{death_year} precedes birth year #{birth_year}"
  end
end
