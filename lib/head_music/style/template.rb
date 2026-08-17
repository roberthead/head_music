# A module for style analysis and guidelines.
module HeadMusic::Style; end

# Renders the customer-facing strings a guide and its items produce.
#
# Everything here exists because I18n fails quietly in ways that would ship a
# raw template to a student with a green suite:
#
#   I18n.t(key, raise: true)      # no interpolation values -> "%{minimum}" intact, no raise
#   I18n.t(key, count: "one")     # a word where a number belongs -> silently plural
#   I18n.t(key, default: "x")     # a reserved key as a value -> hijacks the lookup
#   I18n.t("missing.key")         # -> "Translation missing: ..." rather than an error
#
# So every render passes raise: true AND is checked for a surviving %{}, and no
# value may be named for a reserved key.
module HeadMusic::Style::Template
  SCOPE = "head_music.style"
  INTERPOLATION = /%\{/
  # count is I18n's plural selector as well as a value, so a template value by
  # that name would silently choose a plural form instead of interpolating.
  FORBIDDEN_VALUE_KEYS = (I18n::RESERVED_KEYS + [:count]).freeze

  class MissingTemplate < StandardError; end

  module_function

  # values may carry :count, which selects a plural form and interpolates.
  def render(key, **values)
    guard_value_keys!(values)
    rendered = I18n.t(key, scope: SCOPE, raise: true, **values)
    raise MissingTemplate, "#{key} did not render to a string" unless rendered.is_a?(String)
    raise MissingTemplate, "#{key} left an interpolation unfilled: #{rendered}" if INTERPOLATION.match?(rendered)

    rendered
  rescue I18n::MissingTranslationData, I18n::MissingInterpolationArgument => e
    raise MissingTemplate, "#{key}: #{e.message}"
  end

  # Whether a locale has anything at all under this key. Needed because the
  # Ruby plural fallback would otherwise answer for a key that does not exist,
  # hiding the absence from a caller that wants to fall back differently.
  def exists?(key)
    I18n.exists?("#{SCOPE}.#{key}")
  end

  # The spoken form of a number, in the reader's language where the humanize gem
  # knows it. It raises for a locale it does not ship, and the gem ships two it
  # does not know, so resolve down the fallback chain rather than asking for
  # I18n.locale directly.
  def number_word(number, locale: I18n.locale)
    number.humanize(locale: humanize_locale(locale))
  end

  def humanize_locale(locale)
    I18n.fallbacks[locale].detect { |candidate| humanize_knows?(candidate) } || :en
  end

  # The locale a template will actually render in: the first in the reader's
  # fallback chain that carries the entry itself. I18n.exists? consults the
  # chain by default and so answers true for every locale, which is no answer
  # at all -- hence fallback: false.
  def resolved_locale(key, locale: I18n.locale)
    chain = I18n.fallbacks[locale]
    chain.detect { |candidate| I18n.exists?("#{SCOPE}.#{key}", candidate, fallback: false) } || locale
  end

  # Builds a template's values and renders it in one locale, so the sentence and
  # the words interpolated into it are in the same language. Without this a
  # German reader gets "Write at least Acht notes.": the sentence falls back to
  # English while the number humanizes into German.
  def in_locale_of(key, &block)
    I18n.with_locale(resolved_locale(key), &block)
  end

  def humanize_knows?(locale)
    1.humanize(locale: locale)
    true
  rescue
    false
  end

  # Plural forms come from the locale where it has them, and from Ruby where it
  # does not. A language the gem has no plural data for should read a little
  # wrong, not raise in a student's face -- and a partial plural hash stops the
  # fallback chain rather than continuing past it, so this catches that too.
  #
  # Deliberately narrow. InvalidPluralizationData means the locale cannot answer,
  # which is the case Ruby is here to cover. Rescuing MissingTemplate as well
  # would also swallow an unfilled interpolation -- the one failure verify!
  # exists to catch -- and hand a student a bare noun phrase where the sentence
  # should be, on a green suite.
  def pluralize(key, count:, singular:, **values)
    render(key, count: count, **values)
  rescue I18n::InvalidPluralizationData
    fell_back_to_ruby << key
    "#{number_word(count)} #{(count == 1) ? singular : singular.pluralize}"
  end

  # Reported by the load-time check, so a missing plural is a known gap rather
  # than an invisible one.
  def fell_back_to_ruby
    @fell_back_to_ruby ||= []
  end

  # Renders every string the registry can produce, at load, so a guideline
  # whose template is missing or whose interpolation is unfilled fails on
  # require rather than in front of a student. Runs in English deliberately: a
  # host application's locale must not decide whether the gem loads.
  def verify!(entries)
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
    warn_about_ruby_plurals
  end

  # The Ruby plural fallback is deliberate, but a silent one would hide a
  # missing translation forever.
  def warn_about_ruby_plurals
    return if fell_back_to_ruby.empty?

    fell_back_to_ruby.uniq
  end

  def guard_value_keys!(values)
    clashing = values.keys & FORBIDDEN_VALUE_KEYS
    return if clashing.empty? || clashing == [:count]

    raise ArgumentError, "#{clashing.join(", ")} would be read by I18n rather than interpolated"
  end
end
