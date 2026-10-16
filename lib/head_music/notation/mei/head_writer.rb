module HeadMusic::Notation::MEI
  # The <meiHead>: the title, a <persName> for each credited person, the
  # application that wrote the document, and a <work> for each flow's Work.
  class HeadWriter
    def initialize(flows, title: nil, arranger: nil)
      @flows = flows
      @title = title
      @arranger = arranger
    end

    def element
      Element.new("meiHead", nil, {}, [file_desc_element, encoding_desc_element, work_list_element].compact)
    end

    private

    attr_reader :flows, :arranger

    def title
      @title || flows.first.work&.title || flows.first.name
    end

    def file_desc_element
      Element.new("fileDesc", nil, {}, [title_statement_element, Element.new("pubStmt")])
    end

    def title_statement_element
      people = credits.map { |role, name| Element.new("persName", nil, {"role" => role}, [], name) }
      responsibility = people.any? ? [Element.new("respStmt", nil, {}, people)] : []
      Element.new("titleStmt", nil, {}, [Element.new("title", nil, {}, [], title), *responsibility])
    end

    def credits
      [*flows.flat_map { |flow| flow_credits(flow) }, *Array(arranger).map { |name| ["arranger", name] }].uniq
    end

    def flow_credits(flow)
      work_credits = flow.work&.credits.to_a
      return work_credits.map { |credit| [credit.role.key.to_s, credit.person.full_name] } if work_credits.any?

      flow.composer ? [["composer", flow.composer.to_s]] : []
    end

    def encoding_desc_element
      application = Element.new("application", nil, {"version" => HeadMusic::VERSION}, [Element.new("name", nil, {}, [], "head_music")])
      Element.new("encodingDesc", nil, {}, [Element.new("appInfo", nil, {}, [application])])
    end

    def work_list_element
      works = flows.filter_map(&:work).uniq
      works.any? ? Element.new("workList", nil, {}, works.map { |work| work_element(work) }) : nil
    end

    # The catalog number as an <identifier> before the title, the year in
    # <creation>, and each composer's life as the dates of their <persName>.
    def work_element(work)
      identifier = work.catalog_number && Element.new("identifier", nil, {"type" => "catalog"}, [], work.catalog_number)
      composers = work.credits.for(:composer).map { |credit| Element.new("composer", nil, {}, [person_element(credit.person)]) }
      Element.new("work", nil, {}, [identifier, Element.new("title", nil, {}, [], work.title), *composers, creation_element(work.year)].compact)
    end

    def creation_element(year)
      year && Element.new("creation", nil, {}, [Element.new("date", nil, {"isodate" => iso_year(year)}, [], year.to_s)])
    end

    # A sort name that inverts the full name is written as its parts.
    def person_element(person)
      dates = {"startdate" => iso_year(person.birth_year), "enddate" => iso_year(person.death_year)}
      parts = name_parts(person)
      return Element.new("persName", nil, dates, [], person.full_name) unless parts

      family, given = parts
      Element.new("persName", nil, dates, [Element.new("foreName", nil, {}, [], given), Element.new("famName", nil, {}, [], family)])
    end

    def name_parts(person)
      family, given = person.sort_name.split(", ", 2)
      [family, given] if given && "#{given} #{family}" == person.full_name
    end

    def iso_year(year)
      year && format((year.negative? ? "-%04d" : "%04d"), year.abs)
    end
  end
end
