# Module for guides
module HeadMusic::Style::Guides; end

# Base class for style guides: declares guidelines in three tiers and assesses
# a voice against them.
#
# Tier is the list an item is declared in rather than a property of the item,
# because the cores are shared objects -- ContourMelody treats as background
# exactly what DiatonicMelody teaches, and one frozen item cannot carry both.
class HeadMusic::Style::Guides::Base
  TIERS = %i[gate primary secondary].freeze

  class << self
    # Preconditions: is this voice assessable at all?
    def gate_items(*entries, except: nil) = tier_items(:gate, entries, except)

    # What this guide is about.
    def primary_items(*entries, except: nil) = tier_items(:primary, entries, except)

    # Background craft this guide inherits rather than teaches.
    def secondary_items(*entries, except: nil) = tier_items(:secondary, entries, except)

    def guide_items
      @guide_items ||= TIERS.flat_map { |tier| items_by_tier[tier] }.freeze
    end

    # A guide whose lists depend on configuration overrides this with a keyword
    # signature, so an unconfigured use raises rather than grading a voice
    # against nothing at a plausible 1.0.
    def items_by_tier
      @items_by_tier ||= normalize(declarations)
    end

    def assess(voice)
      HeadMusic::Style::GuideAssessment.new(self, voice)
    end

    # The material GuideAssessment grades, stopping at a failed gate.
    def assess_items(voice)
      HeadMusic::Style::Guides::Assessment.assess_items(voice, items_by_tier)
    end

    # Rejected here rather than at the first assessment, where Ruby's bare
    # "wrong number of arguments" would name neither the guide nor the option.
    def with(**options)
      if options.any? && method(:items_by_tier).parameters.empty?
        raise ArgumentError, "#{name} takes no configuration, so it cannot be given: #{options.keys.join(", ")}"
      end

      HeadMusic::Style::Guides::Configured.new(self, options)
    end

    def key
      HeadMusic::Utilities::Case.to_snake_case(name.split("::").last)
    end

    # An open enum: :melody or :harmony today, declared on the marker bases.
    def category
      nil
    end

    def composite?
      false
    end

    # The guide-side twin of GuideAssessment#assessments: one category, so a
    # registry sweep can ask every entry the same question.
    def categories
      [category].compact
    end

    def display_name
      HeadMusic::Style::Guide.display_name_for(key)
    end

    def instruction
      HeadMusic::Style::Guide.instruction_for(key)
    end

    protected

    def normalize(tiers)
      resolved = TIERS.to_h { |tier| [tier, wrap_list(tiers[tier])] }.freeze
      # ArgumentError, not NotImplementedError: the latter is a ScriptError and
      # so escapes an ordinary rescue.
      if resolved.values.all?(&:empty?)
        raise ArgumentError, "#{name} declares no guide items"
      end

      # A guide that is all background has no subject, and grading it 1.0 in
      # silence is the "nothing to find fault in" confusion.
      #
      # A gate-only guide is caught by the same check, deliberately and with no
      # exemption: a guide that only decides whether a voice is assessable has
      # nothing to grade it against, and an exemption would leave two spellings
      # of "this guide teaches nothing" -- one that raises and one that quietly
      # returns 1.0.
      #
      # The declared items are named because the class name is not enough: the
      # six contour guides are one class configured six ways.
      if resolved[:primary].empty?
        raise ArgumentError,
          "#{name} declares no primary guide items, so it teaches nothing: " \
          "#{resolved.reject { |_tier, items| items.empty? }.transform_values { |items| items.map(&:inspect) }.inspect}"
      end

      reject_duplicates(resolved)
      resolved
    end

    private

    def tier_items(tier, entries, except)
      return items_by_tier[tier] if entries.empty? && except.nil?

      declarations[tier] = [*declarations[tier], *wrap_list(entries, except)]
      nil
    end

    # Never inherited: a subclass that omits a list gets an empty one.
    def declarations
      @declarations ||= {}
    end

    # except: applies to the entries of the call carrying it, not the tier:
    # DiatonicMelody drops a core item and then declares its own configured one.
    def wrap_list(entries, excluded = nil)
      items = Array(entries).compact.map { |entry| HeadMusic::Style::GuideItem.wrap(entry) }
      return items.freeze if excluded.nil?

      items.reject { |item| Array(excluded).include?(item.guideline) }.freeze
    end

    # MinimumNotes as a gate and again as a stylistic minimum asks two
    # questions; the same configuration in two tiers is double-counting.
    def reject_duplicates(resolved)
      duplicated = resolved.values.flatten.tally.select { |_item, count| count > 1 }.keys
      return if duplicated.empty?

      raise ArgumentError,
        "#{name} declares the same guideline and configuration in more than one tier: " \
        "#{duplicated.map(&:inspect).join(", ")}"
    end
  end
end
