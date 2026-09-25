# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # Builds the Work a kern file cites from its reference records: the title
  # (!!!OTL, or failing that !!!OTL@@xx), the catalog number (!!!SCT), the
  # year (the first year in !!!ODT), and a composer credit for each
  # !!!COM.
  #
  # A Work requires a title, so a file with composers but no title cites no
  # work, and its composers become the flow's composer string instead.
  class CitationReader
    YEAR = /\d{4}/
    # Kern marks approximate and bounded dates (~1700, ?1700, <1700, >1700)
    # before the year, which is still the year.
    DATE_YEAR = /\A[~?<>]*(\d{4})/

    def initialize(document)
      @document = document
    end

    def work
      title = @document.title
      return unless title

      people.reduce(
        HeadMusic::Content::Work.new(title: title, catalog_number: @document.catalog_number, year: year)
      ) { |work, person| work.with_credit(person, :composer) }
    end

    # The composer string for a flow that cites no work, joined as
    # Work#composer joins the names of a work's composers.
    def composer
      names = people.map(&:full_name)
      names.join(", ") unless names.empty?
    end

    private

    def year
      @document.date&.[](YEAR)&.to_i
    end

    def people
      @people ||= begin
        records = @document.composers
        records.map { |record| person(record, (records.length == 1) ? lifespan : []) }
      end
    end

    # "Bach, Johann Sebastian" is a sort name; the full name puts the given
    # names first. A name without a comma is taken as both.
    def person(record, years)
      last, given = record.split(",", 2).map(&:strip)
      full_name = given.to_s.empty? ? record : "#{given} #{last}"
      birth_year, death_year = years
      HeadMusic::Content::Person.new(full_name: full_name, sort_name: record, birth_year: birth_year, death_year: death_year)
    end

    # The birth and death years of !!!CDT (1685/02/21/-1750/07/28/), or
    # none when they cannot be read, since Person validates its years and a
    # bad date should not sink the music.
    def lifespan
      sides = @document.composer_dates.to_s.split("-", 2)
      birth_year, death_year = sides.map { |side| side.strip[DATE_YEAR, 1]&.to_i }
      return [] unless sides.length == 2 && birth_year && death_year && death_year >= birth_year

      [birth_year, death_year]
    end
  end
end
