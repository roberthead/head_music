module HeadMusic
  module Style
    class Analysis
      attr_reader :ruleset, :subject, :annotations

      def initialize(ruleset, subject)
        @ruleset = ruleset
        @subject = subject
      end

      def annotations
        @annotations ||= @ruleset.analyze(subject)
      end

      def fitness
        annotations.map(&:fitness).reduce(1, :*)
      end
    end
  end
end
