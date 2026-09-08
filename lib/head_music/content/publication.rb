# A module for musical content
module HeadMusic::Content; end

# A published edition: the book, treatise, or score a flow may cite as its
# source. Hand-rolled rather than a Data.define because CantusFirmus::Source
# subclasses it to add a catalog key.
class HeadMusic::Content::Publication
  FIELDS = %i[title edition year publisher abbreviation notes].freeze

  attr_reader(*FIELDS)
  attr_reader :credits

  def self.from_h(hash)
    values = hash.transform_keys(&:to_s)
    new(
      title: values["title"],
      edition: values["edition"],
      year: values["year"],
      publisher: values["publisher"],
      abbreviation: values["abbreviation"],
      notes: values["notes"],
      credits: HeadMusic::Content::Credits.from_h(values["credits"], level: :publication)
    )
  end

  def initialize(title:, edition: nil, year: nil, publisher: nil, abbreviation: nil, notes: nil, credits: [])
    @title = title
    @edition = edition
    @year = year
    @publisher = publisher
    @abbreviation = abbreviation
    @notes = notes
    @credits = ensure_credits(credits)
    freeze
  end

  def authors
    credits.names(:author)
  end

  def to_s
    title.to_s
  end

  def to_h
    {
      "title" => title,
      "edition" => edition,
      "year" => year,
      "publisher" => publisher,
      "abbreviation" => abbreviation,
      "notes" => notes,
      "credits" => credits.to_h
    }
  end

  # Compared on the publication's own fields, so that a source restored from a
  # document as a plain Publication still equals the catalog entry it names.
  def ==(other)
    other.is_a?(HeadMusic::Content::Publication) && values == other.values
  end
  alias_method :eql?, :==

  def hash
    [HeadMusic::Content::Publication, values].hash
  end

  protected

  def values
    FIELDS.map { |field| public_send(field) } + [credits]
  end

  private

  def ensure_credits(credits)
    return credits if credits.is_a?(HeadMusic::Content::Credits) && credits.level == :publication

    HeadMusic::Content::Credits.new(:publication, credits)
  end
end
