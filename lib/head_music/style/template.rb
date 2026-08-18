# A module for style analysis and guidelines.
module HeadMusic::Style; end

# Renders the customer-facing strings a guide and its items produce.
#
# I18n fails quietly in four ways, each of which ships a raw template to a
# student on a green suite:
#
#   I18n.t(key, raise: true)      # no values -> "%{minimum}" intact, no raise
#   I18n.t(key, count: "one")     # a word where a number belongs -> silently plural
#   I18n.t(key, default: "x")     # a reserved key as a value -> hijacks the lookup
#   I18n.t("missing.key")         # -> "Translation missing: ..." rather than an error
module HeadMusic::Style::Template
  SCOPE = "head_music.style"
  INTERPOLATION = /%\{/
  # count selects a plural form, so a value by that name never reaches the template.
  FORBIDDEN_VALUE_KEYS = (I18n::RESERVED_KEYS + [:count]).freeze

  class MissingTemplate < StandardError; end

  module_function

  def render(key, **values)
    guard_value_keys!(values)
    rendered = I18n.t(key, scope: SCOPE, raise: true, **values)
    raise MissingTemplate, "#{key} did not render to a string" unless rendered.is_a?(String)
    raise MissingTemplate, "#{key} left an interpolation unfilled: #{rendered}" if INTERPOLATION.match?(rendered)

    rendered
  rescue I18n::MissingTranslationData, I18n::MissingInterpolationArgument => e
    raise MissingTemplate, "#{key}: #{e.message}"
  end

  def exists?(key)
    I18n.exists?("#{SCOPE}.#{key}")
  end

  # humanize raises for a locale it does not ship, and the gem ships two it does
  # not know, so the chain is walked rather than asked directly.
  def number_word(number, locale: I18n.locale)
    number.humanize(locale: humanize_locale(locale))
  end

  def humanize_locale(locale)
    I18n.fallbacks[locale].detect { |candidate| humanize_knows?(candidate) } || :en
  end

  # fallback: false because I18n.exists? consults the chain and so answers true
  # for every locale, which is no answer at all.
  def resolved_locale(key, locale: I18n.locale)
    chain = I18n.fallbacks[locale]
    chain.detect { |candidate| I18n.exists?("#{SCOPE}.#{key}", candidate, fallback: false) } || locale
  end

  # Values are built in the locale the sentence renders in. Otherwise a German
  # reader gets "Write at least Acht notes.": the sentence falls back to English
  # while the number humanizes into German.
  def in_locale_of(key, &block)
    I18n.with_locale(resolved_locale(key), &block)
  end

  def humanize_knows?(locale)
    1.humanize(locale: locale)
    true
  rescue
    false
  end

  # A locale with no plural data should read a little wrong rather than raise at
  # a student. Narrow deliberately: rescuing MissingTemplate too would swallow
  # an unfilled interpolation, which is the failure verify! exists to catch.
  def pluralize(key, count:, **values)
    render(key, count: count, **values)
  rescue I18n::InvalidPluralizationData => error
    form = ruby_plural_form(error.entry, count)
    raise MissingTemplate, "#{key} has no plural form to fall back to" if form.nil?

    fell_back_to_ruby << key unless fell_back_to_ruby.include?(key)
    render("#{key}.#{form}", count: count, **values)
  end

  # English's rule first, then whatever the entry carries. Reading the singular
  # for a plural count keeps the sentence, which a noun phrase would not.
  def ruby_plural_form(entry, count)
    preferred = (count == 1) ? :one : :other
    ([preferred, :other, :one] & entry.keys).first || entry.keys.first
  end

  def fell_back_to_ruby
    @fell_back_to_ruby ||= []
  end

  # Renders every string the registry can produce, at load, so a missing or
  # unfillable template fails on require rather than in front of a student. In
  # English deliberately: a host application's locale must not decide whether
  # the gem loads. Returns the keys that needed the Ruby plural fallback.
  def verify!(entries)
    fell_back_to_ruby.clear
    I18n.with_locale(:en) do
      entries.each do |guide|
        guide.instruction
        guide.guide_items.each do |item|
          item.name
          item.instruction
          item.violation_preview
        end
      end
    end
    fell_back_to_ruby.dup
  end

  def guard_value_keys!(values)
    clashing = values.keys & FORBIDDEN_VALUE_KEYS
    return if clashing.empty? || clashing == [:count]

    raise ArgumentError, "#{clashing.join(", ")} would be read by I18n rather than interpolated"
  end
end
