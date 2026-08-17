# Module for guides
module HeadMusic::Style::Guides; end

# Base class for style guides. A guide declares its guidelines in three tiers
# and assesses a voice against them, producing one guideline instance per item.
#
# Tier is the list an item is declared in rather than a property of the item,
# because the shared cores are shared objects: SpeciesMelody::MELODIC_CORE is
# splatted into six guides, and ContourMelody treats as background exactly what
# DiatonicMelody teaches. One frozen item cannot carry both standings.
class HeadMusic::Style::Guides::Base
  TIERS = %i[gate primary secondary].freeze

  class << self
    # Preconditions: is this voice assessable by this guide at all?
    def gate_items(*entries, except: nil) = tier_items(:gate, entries, except)

    # What this guide is about.
    def primary_items(*entries, except: nil) = tier_items(:primary, entries, except)

    # Background craft this guide inherits rather than teaches.
    def secondary_items(*entries, except: nil) = tier_items(:secondary, entries, except)

    # The three lists in tier order, for consumers that want everything.
    def guide_items
      @guide_items ||= TIERS.flat_map { |tier| items_by_tier[tier] }.freeze
    end

    # The one reader. A guide whose lists depend on configuration overrides
    # this with a keyword signature, so an unconfigured use raises here rather
    # than grading a voice against nothing at a plausible 1.0 -- the same
    # defense the old .ruleset indirection provided against Ruby resolving a
    # ::RULESET constant up the ancestor chain.
    def items_by_tier
      @items_by_tier ||= normalize(declarations)
    end

    def analyze(voice)
      guide_items.map { |item| item.new(voice) }
    end

    # Pairs this guide with configuration: ContourMelody.with(contour: :arch).
    #
    # A guide gains configuration by declaring keywords on .items_by_tier, so a
    # guide taking none accepts none. Saying that here, at configuration time,
    # is the same choice ContourMelody makes in normalizing its contour in
    # .with: the alternative is Ruby's bare "wrong number of arguments" at the
    # first assessment, naming neither the guide nor the option.
    def with(**options)
      if options.any? && method(:items_by_tier).parameters.empty?
        raise ArgumentError, "#{name} takes no configuration, so it cannot be given: #{options.keys.join(", ")}"
      end

      HeadMusic::Style::Guides::Configured.new(self, options)
    end

    def key
      HeadMusic::Utilities::Case.to_snake_case(name.split("::").last)
    end

    # An open enum owned by the gem: :melody or :harmony today, with room for
    # :rhythm or :form later. Declared on the semantic marker base classes.
    def category
      nil
    end

    def display_name
      HeadMusic::Style::Guide.display_name_for(key)
    end

    protected

    # Coerces bare guideline classes and freezes. Shared by the macro path and
    # by a configured guide's override, so both get the same coercion and the
    # same checks.
    def normalize(tiers)
      resolved = TIERS.to_h { |tier| [tier, wrap_list(tiers[tier])] }.freeze
      if resolved.values.all?(&:empty?)
        raise NotImplementedError, "#{name} declares no guide items"
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

    # Per class on the singleton, never inherited: a subclass that omits a list
    # gets an empty list rather than silently inheriting its ancestor's.
    def declarations
      @declarations ||= {}
    end

    # except: is applied to the entries of the call that carried it, not to the
    # tier as a whole. DiatonicMelody drops SingableIntervals from the splatted
    # core and then declares its own configured one; a tier-wide filter would
    # remove that too.
    def wrap_list(entries, excluded = nil)
      items = Array(entries).compact.map { |entry| HeadMusic::Style::GuideItem.wrap(entry) }
      return items.freeze if excluded.nil?

      items.reject { |item| Array(excluded).include?(item.guideline) }.freeze
    end

    # A guideline may appear in two tiers -- MinimumNotes as a low gate and
    # again as a stylistic minimum asks two different questions. The same
    # guideline with the same configuration in two tiers is double-counting.
    def reject_duplicates(resolved)
      duplicated = resolved.values.flatten.tally.select { |_item, count| count > 1 }.keys
      return if duplicated.empty?

      raise ArgumentError,
        "#{name} declares the same guideline and configuration in more than one tier: " \
        "#{duplicated.map(&:name).join(", ")}"
    end
  end
end
