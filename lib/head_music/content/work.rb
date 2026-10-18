# A module for musical content
module HeadMusic::Content; end

# The catalog identity of a composition, independent of any one notated version
# of it. A Flow may cite a Work, or cite none.
HeadMusic::Content::Work = Data.define(:title, :catalog_number, :year, :credits) do
  def self.from_h(hash)
    new(**members.to_h { |member| [member, hash[member.to_s]] })
  end

  def initialize(title:, catalog_number: nil, year: nil, credits: [])
    super(title: title, catalog_number: catalog_number, year: year, credits: HeadMusic::Content::Credits.new(:work, credits))
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
    super.transform_keys(&:to_s).merge("credits" => credits.to_h)
  end
end
