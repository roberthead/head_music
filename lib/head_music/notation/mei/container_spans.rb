module HeadMusic::Notation::MEI
  # The <tupletSpan> and <beamSpan> control events for the containers a
  # layer cannot hold.
  class ContainerSpans
    def initialize(plan)
      @layer_containers = plan.source(LayerContainers)
    end

    def controls
      @layer_containers.spans
    end
  end
end

HeadMusic::Notation::MEI::MeasureWriter.control_sources << HeadMusic::Notation::MEI::ContainerSpans
