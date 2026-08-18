module HeadMusic::Style; end

class HeadMusic::Style::Guideline
  # How a guideline says what it wants: the locale keys it addresses and the
  # sentences rendered from them. Extended rather than included, because the
  # wording belongs to the rule -- the class -- and not to one analysis.
  module Wording
    # Addressed in the locale files by the snake_case of the class name, so a new
    # guideline needs no declaration.
    def template_key
      @template_key ||= HeadMusic::Utilities::Case.to_snake_case(name.split("::").last)
    end

    def name_key = "guidelines.#{template_key}.name"

    def instruction_key = "guidelines.#{template_key}.instruction"

    # Takes the configuration: a guide may name a different template.
    def violation_key(_config = {}) = "guidelines.#{template_key}.violations.default"

    # Where a locale has nothing to say, the class name read as a sentence beats
    # nothing.
    #
    # The first letter is upcased here rather than in the data because a name can
    # lead with an interpolation -- "%{contour} contour" -- whose value has to
    # stay lowercase for the violation sentence that embeds it mid-sentence.
    def render_name(config)
      rendered =
        if HeadMusic::Style::Template.exists?(name_key)
          render_template(name_key, config)
        else
          template_key.tr("_", " ")
        end
      rendered.sub(/\A./) { |letter| letter.upcase }
    end

    # Violations are already phrased imperatively, so a guideline with nothing
    # more specific to say instructs with the sentence it would complain with.
    def render_instruction(config)
      return render_violation(config) unless HeadMusic::Style::Template.exists?(instruction_key)

      render_template(instruction_key, config)
    end

    def render_violation(config)
      render_template(violation_key(config), config)
    end

    # Every key an analysis can choose between, not only the one a bare config
    # names. Load-time verification renders all of them: a branch reached by one
    # kind of failure is otherwise unrendered until a student causes it.
    def violation_keys(config = {})
      [violation_key(config)]
    end

    def render_violations(config)
      violation_keys(config).map { |key| render_template(key, config) }
    end

    # Takes the configuration rather than finished values, so template_values --
    # where numbers humanize -- runs inside the locale the sentence renders in.
    def render_template(key, config, extra_values = {})
      HeadMusic::Style::Template.in_locale_of(key) do
        values = template_values(config).merge(extra_values)
        if values.key?(:count)
          HeadMusic::Style::Template.pluralize(key, **values)
        else
          HeadMusic::Style::Template.render(key, **values)
        end
      end
    end

    # Not the config itself: seven items declare none and read their values from
    # class constants, and I18n returns a template untouched when given no values.
    def template_values(config)
      config.except(:violation_key)
    end
  end
end
