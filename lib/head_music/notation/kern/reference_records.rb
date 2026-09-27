# A namespace for **kern rendering helpers
module HeadMusic::Notation::Kern
  # The !!! reference records that open a kern file: its composers and
  # their dates, its title, catalog number, and year.
  class ReferenceRecords
    def self.lines(flow)
      new(flow).lines
    end

    def initialize(flow)
      @flow = flow
    end

    def lines
      [
        *composer_names.map { |name| "!!!COM: #{name}" },
        composer_dates && "!!!CDT: #{composer_dates}",
        title && "!!!OTL: #{title}",
        work&.catalog_number && "!!!SCT: #{work.catalog_number}",
        work&.year && "!!!ODT: #{work.year}"
      ].compact
    end

    private

    attr_reader :flow

    def work
      flow.work
    end

    # The default name is left out, since the reader gives it back to a file
    # with no title, and a title would cite a work the flow never had.
    def title
      flow.name unless work.nil? && flow.name == HeadMusic::Content::Flow::DEFAULT_NAME
    end

    def composers
      work ? work.credits.for(:composer).map(&:person) : []
    end

    # A file with composers and no title is read into one composer string,
    # so the string is written back a name to a record.
    def composer_names
      return composers.map(&:sort_name) if work

      flow.composer.to_s.split(",").map(&:strip).reject(&:empty?)
    end

    def composer_dates
      return unless composers.length == 1

      person = composers.first
      "#{person.birth_year}/-#{person.death_year}/" if person.birth_year && person.death_year
    end
  end
end
