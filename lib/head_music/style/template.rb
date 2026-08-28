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
  # Note values are rudiment vocabulary that the sentences borrow. Reachable
  # through the same seam so they get the plural fallback and the unfilled-
  # interpolation guard the style strings get.
  RUDIMENT_SCOPE = "head_music.rudiments"
  NUMBER_WORDS_SCOPE = "head_music.number_words"
  # I18n's Simple backend implements English's rule and no other, so a locale
  # whose forms differ raises rather than choosing. Kept here as a seam rather
  # than by including I18n::Backend::Pluralization, which would switch
  # pluralization on for the host application's locales too.
  PLURAL_RULES = {
    ru: ->(count) {
      tens = count % 100
      units = count % 10
      if units == 1 && tens != 11 then :one
      elsif (2..4).cover?(units) && !(12..14).cover?(tens) then :few
      else :many
      end
    }
  }.freeze
  INTERPOLATION = /%\{/
  # count selects a plural form, so a value by that name never reaches the template.
  FORBIDDEN_VALUE_KEYS = (I18n::RESERVED_KEYS + [:count]).freeze

  class MissingTemplate < StandardError; end

  module_function

  # scope is safe as a keyword rather than a value: I18n reserves the name, so
  # no template could ever have interpolated %{scope} anyway. Declaring it binds
  # a caller's scope: to the parameter, which is why guard_value_keys! never
  # sees it.
  def render(key, scope: SCOPE, **values)
    guard_value_keys!(values)
    rendered = I18n.t(key, scope: scope, raise: true, **values)
    raise MissingTemplate, "#{key} did not render to a string" unless rendered.is_a?(String)
    raise MissingTemplate, "#{key} left an interpolation unfilled: #{rendered}" if INTERPOLATION.match?(rendered)

    rendered
  rescue I18n::MissingTranslationData, I18n::MissingInterpolationArgument => e
    raise MissingTemplate, "#{key}: #{e.message}"
  end

  def exists?(key, scope: SCOPE)
    I18n.exists?("#{scope}.#{key}")
  end

  # A locale that spells its own numerals wins. humanize ships no Italian at
  # all, and where it does ship a locale the form is wrong for this sentence:
  # capitalized mid-sentence for German, masculine where the note values being
  # counted are feminine.
  def number_word(number, locale: I18n.locale)
    spelled_number(number, locale) || number.humanize(locale: humanize_locale(locale))
  end

  # fallback: false so a locale without its own numerals falls through to
  # humanize, rather than reading English's word as though it were its own.
  def spelled_number(number, locale)
    I18n.t(number.to_s, scope: NUMBER_WORDS_SCOPE, locale: locale, fallback: false, default: nil)
  end

  def humanize_locale(locale)
    I18n.fallbacks[locale].detect { |candidate| humanize_knows?(candidate) } || :en
  end

  # fallback: false because I18n.exists? consults the chain and so answers true
  # for every locale, which is no answer at all.
  def resolved_locale(key, locale: I18n.locale, scope: SCOPE)
    chain = I18n.fallbacks[locale]
    chain.detect { |candidate| I18n.exists?("#{scope}.#{key}", candidate, fallback: false) } || locale
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
  def pluralize(key, count:, scope: SCOPE, **values)
    render(key, count: count, scope: scope, **values)
  rescue I18n::InvalidPluralizationData => error
    known = known_plural_form(error.entry, count)
    return render("#{key}.#{known}", count: count, scope: scope, **values) if known

    form = ruby_plural_form(error.entry, count)
    raise MissingTemplate, "#{key} has no plural form to fall back to" if form.nil?

    fell_back_to_ruby << key unless fell_back_to_ruby.include?(key)
    render("#{key}.#{form}", count: count, scope: scope, **values)
  end

  # Applying a rule the gem knows is not a fallback, so it is not recorded as
  # one -- otherwise every Russian sentence would report a plural gap and the
  # guard that watches for real ones would have to be loosened.
  def known_plural_form(entry, count)
    form = PLURAL_RULES[I18n.locale]&.call(count)
    form if form && entry.key?(form)
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

  # Renders every template the registry can produce -- including the violation
  # branches an analysis chooses between -- at load, so a missing or unfillable
  # one fails on require rather than in front of a student. In English
  # deliberately: a host application's locale must not decide whether the gem
  # loads. Returns the keys that needed the Ruby plural fallback.
  def verify!(entries)
    fell_back_to_ruby.clear
    I18n.with_locale(:en) do
      entries.each do |guide|
        guide.instruction
        guide.guide_items.each do |item|
          item.name
          item.instruction
          item.violation_previews
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
