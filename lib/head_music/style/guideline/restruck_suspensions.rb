module HeadMusic::Style; end

class HeadMusic::Style::Guideline
  # For a guideline that excuses a suspension's shape, configured with
  # `restruck_suspensions: true` to excuse one struck again as well as one
  # held, and to say so.
  module RestruckSuspensions
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def restruck_violation_key = "guidelines.#{template_key}.violations.with_restruck_suspensions"

      def violation_key(config = {})
        config[:restruck_suspensions] ? restruck_violation_key : super
      end

      # Both, whichever the configuration names, so load-time verification
      # renders the restruck sentence though the registry may hold only one.
      def violation_keys(config = {})
        [*super({}), restruck_violation_key].uniq
      end

      def render_instruction(config)
        return super unless config[:restruck_suspensions]

        render_template("guidelines.#{template_key}.instruction_with_restruck_suspensions", config)
      end
    end

    private

    def restruck_suspensions?
      options.fetch(:restruck_suspensions, false)
    end
  end
end
