module HeadMusic::Notation::MEI
  # Builds a flow from one Source of a Document.
  class FlowBuilder
    def initialize(source)
      @source = source
    end

    def flow
      @flow ||= HeadMusic::Content::Flow.new
    end
  end
end
