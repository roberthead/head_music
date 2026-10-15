module HeadMusic::Notation::MEI
  # The <meiHead>: the title, a <persName> for each credited person, and the
  # application that wrote the document.
  class HeadWriter
    def initialize(flows, title: nil, arranger: nil)
      @flows = flows
      @title = title
      @arranger = arranger
    end

    def element
      Element.new("meiHead", nil, {}, [file_desc_element, encoding_desc_element])
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
  end
end
