module HeadMusic::Notation::MEI
  # Renders flows as one MEI document, an <mdiv> for each. Every flow is
  # checked and planned before any writing, so #to_s only ever returns a
  # complete document.
  class Writer
    SCHEMA = "https://music-encoding.org/schema/5.1/mei-CMN.rng"
    VERSION = "5.1"

    attr_reader :flows, :title, :arranger, :transposed

    def initialize(flows, title: nil, arranger: nil, transposed: false)
      @flows = flows
      @title = title
      @arranger = arranger
      @transposed = transposed
    end

    def to_s
      flows.each { |flow| Preflight.check!(flow, [title, *Array(arranger)]) }
      plans
      document_lines.join("\n") + "\n"
    end

    private

    def plans
      @plans ||= flows.each_with_index.map do |flow, index|
        RenderPlan.new(flow, transposed: transposed, mdiv_number: index + 1)
      end
    end

    def document_lines
      [
        %(<?xml version="1.0" encoding="UTF-8"?>),
        %(<?xml-model href="#{SCHEMA}" type="application/xml" schematypens="http://relaxng.org/ns/structure/1.0"?>),
        *Markup.lines(mei_element)
      ]
    end

    def mei_element
      Element.new(
        "mei", nil, {"xmlns" => "http://www.music-encoding.org/ns/mei", "meiversion" => VERSION},
        [HeadWriter.new(flows, title: title, arranger: arranger).element, music_element]
      )
    end

    def music_element
      Element.new("music", nil, {}, [Element.new("body", nil, {}, plans.map { |plan| mdiv_element(plan) })])
    end

    def mdiv_element(plan)
      score = Element.new(
        "score", plan.ids.container("score"), {},
        [ScoreDefWriter.new(plan).element, SectionWriter.new(plan).element]
      )
      Element.new("mdiv", plan.ids.mdiv, {"label" => plan.flow.name}, [score])
    end
  end
end
