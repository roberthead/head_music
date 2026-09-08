# A module for musical content
module HeadMusic::Content; end

# The catalog identity of a composition, independent of any one notated version
# of it. A Flow may cite a Work, or cite none.
HeadMusic::Content::Work = Data.define(:title, :catalog_number, :year, :credits) do
  def self.from_h(hash)
    new(
      title: hash["title"],
      catalog_number: hash["catalog_number"],
      year: hash["year"],
      credits: HeadMusic::Content::Credits.from_h(hash["credits"], level: :work)
    )
  end

  def initialize(title:, catalog_number: nil, year: nil, credits: [])
    super(title: title, catalog_number: catalog_number, year: year, credits: ensure_credits(credits))
  end

  # Joined with a comma rather than translated: the string lands in ABC,
  # LilyPond, and MusicXML header fields, which have no locale.
  def composer
    names = credits.names(:composer)
    names.join(", ") unless names.empty?
  end

  def with_credit(person, role)
    with(credits: credits.add(person, role))
  end

  def to_s
    [title, catalog_number].compact.join(", ")
  end

  def to_h
    {
      "title" => title,
      "catalog_number" => catalog_number,
      "year" => year,
      "credits" => credits.to_h
    }
  end

  private

  def ensure_credits(credits)
    return credits if credits.is_a?(HeadMusic::Content::Credits) && credits.level == :work

    HeadMusic::Content::Credits.new(:work, credits)
  end
end
