require "spec_helper"

# The companion to guide_item_strings_spec, which pins the exact English. This
# asserts the properties that must hold for every string in every language: it
# renders, it is a string, and no interpolation survives into it.
#
# A guideline added without an entry, a template whose values the guideline
# stopped passing, or a locale that stops resolving fails here rather than in
# front of a student.
PLURAL_KEYS = %i[zero one two few many other].freeze
ENGLISH_PLURAL_KEYS = %i[one other].freeze

# The note-value words each naming family uses. American stays scoped to
# note|rest: a bare word alternation matches the same strings today, but "half
# step", "whole tone" and "half cadence" are ordinary theory terms waiting to
# false-fire. British needs its word boundary -- an unanchored /minim/ flags
# every "Minimum of ..." string MinimumNotes produces.
NOTE_VOCABULARIES = {
  american: /\b(whole|half|quarter|eighth|sixteenth)[-\s](note|rest)/i,
  british: /\b(semibreve|minim|crotchet|quaver|semiquaver)s?\b/i
}.freeze

# Which vocabulary each locale resolves to. de, fr, it and ru read British by
# inheritance, deliberately: they route through en_GB, and no choice of English
# serves all four, so the story that gives them their own note values moves
# these rows rather than reordering the chain. This map is that decision in
# executable form -- edit the fallback chain and the sweep below fails until the
# map moves with it.
LOCALE_NOTE_VOCABULARY = {
  en: :american, en_US: :american, es: :american,
  en_GB: :british, de: :british, fr: :british, it: :british, ru: :british
}.freeze

describe HeadMusic::Style::Guide do
  let(:guides) { HeadMusic::Style::Guide::ALL }
  let(:items) { guides.flat_map(&:guide_items).uniq }

  # Collected rather than asserted one at a time: 8 locales x (23 guides + 67
  # items x 3 templates) is far too many examples, and a list of every broken
  # string is a better failure than the first one.
  def problems_in(locale)
    I18n.with_locale(locale) do
      guides.filter_map { |guide| problem_with(guide, :instruction) } +
        items.flat_map { |item| %i[name instruction].filter_map { |m| problem_with(item, m) } } +
        items.flat_map { |item| violation_problems_with(item) }
    end
  end

  # Every branch, not only the default: the sentence a guideline picks during
  # analysis has to survive each locale too.
  def violation_problems_with(item)
    item.violation_previews.each_with_index.filter_map do |rendered, index|
      fault_in(rendered, "#{item.inspect}#violation_previews[#{index}]")
    end
  rescue => error
    ["#{item.inspect}#violation_previews: #{error.class}: #{error.message}"]
  end

  def problem_with(subject, method)
    fault_in(subject.public_send(method), "#{subject.inspect}##{method}")
  rescue => error
    "#{subject.inspect}##{method}: #{error.class}: #{error.message}"
  end

  def fault_in(rendered, label)
    return "#{label} is not a string" unless rendered.is_a?(String)
    return "#{label} is empty" if rendered.empty?
    return "#{label} left an interpolation: #{rendered}" if rendered.include?("%{")

    nil
  end

  I18n.available_locales.each do |locale|
    it "renders every guide and guide item string in #{locale}" do
      expect(problems_in(locale)).to be_empty
    end
  end

  it "covers every registry entry" do
    expect(guides.size).to eq 23
    expect(items.size).to eq 67
  end

  def strings_in(locale)
    I18n.with_locale(locale) do
      guides.map(&:instruction) +
        items.flat_map { |item| [item.name, item.instruction] + item.violation_previews }
    end
  end

  # The dissonant-climax sentence shipped unverified: ConsonantClimax picks it
  # during analysis, and nothing that runs at load ever named it. A guideline
  # that grows a second violation branch has to declare it here, or it stays
  # unrendered until a student causes exactly that failure.
  it "sweeps every violation entry its guidelines declare" do
    expect(declared_violation_keys - swept_violation_keys).to be_empty
  end

  # Declaring the keys is half of it. A renderer that dropped all but the first
  # would leave the same branch unrendered at load and the guard above green.
  it "renders every key it declares" do
    short = items.reject { |item| item.violation_previews.size == item.guideline.violation_keys(item.config).size }

    expect(short).to be_empty
  end

  # Read from the file rather than the backend, which merges en_GB overrides of
  # these same keys back in.
  def declared_violation_keys
    english = YAML.load_file(File.expand_path("../../../lib/head_music/locales/en.yml", __dir__))
    registry_keys = items.map { |item| item.guideline.template_key }.uniq
    entries = english.dig("en", "head_music", "style", "guidelines").slice(*registry_keys)
    entries.flat_map do |key, entry|
      (entry["violations"] || {}).keys.map { |form| "guidelines.#{key}.violations.#{form}" }
    end
  end

  def swept_violation_keys
    items.flat_map { |item| item.guideline.violation_keys(item.config) }.uniq
  end

  # No locale but en and en_GB carries a style entry, so a German reader's
  # strings must be exactly the ones they fall back through. They were not: the
  # sentence fell back to English while the number humanized into German, so a
  # reader got "Write at least Acht notes." -- neither language, and the
  # capitalization reads as a typo.
  it "renders a fallback string wholly in the language it fell back to" do
    expect(strings_in(:de)).to eq strings_in(:en_GB)
  end

  # The executable form of "a British reader gets British note values". Written
  # as ownership rather than as a British-versus-American pair so that a locale
  # gaining its own note words changes a row above, not this example. fetch with
  # no default means a locale added to the gem fails here until someone decides
  # which vocabulary it reads, rather than being swept as American by default.
  it "gives every locale only the note vocabulary it owns" do
    expect(I18n.available_locales.flat_map { |locale| foreign_vocabulary_in(locale) }).to be_empty
  end

  def foreign_vocabulary_in(locale)
    foreign = NOTE_VOCABULARIES.except(LOCALE_NOTE_VOCABULARY.fetch(locale))
    strings_in(locale).flat_map do |string|
      foreign.filter_map { |family, pattern| "#{locale}: #{family} in #{string.inspect}" if pattern.match?(string) }
    end
  end

  # The one pair worth pinning verbatim: the singular/plural boundary and the
  # noun-drop at once. British names the value with a noun, so the "note" the
  # American sentence needs is dropped rather than translated -- which is what a
  # find-and-replace over the vocabulary gets wrong, in both directions.
  describe "the British note_count_per_bar sentences" do
    def british_violation(guideline)
      I18n.with_locale(:en_GB) { guideline.with.violation_preview }
    end

    it "drops the noun in the plural" do
      expect(british_violation(HeadMusic::Style::Guidelines::FourPerBar)).to eq "Use four crotchets in each middle bar."
    end

    it "drops the noun in the singular" do
      expect(british_violation(HeadMusic::Style::Guidelines::OnePerBar)).to eq "Use one semibreve in each middle bar."
    end
  end

  # A key in en_GB with no en counterpart raises for es and en readers, who
  # never resolve through it, and leaks British terms to en_US.
  #
  # Compared as template keys rather than leaves, because whether an entry is
  # pluralized is a per-locale decision and the two locales disagree in both
  # directions here: English pluralizes note_count_per_bar's sentences where
  # British flattens them, and British pluralizes rhythmic_units where English
  # is scalar. Neither is a new key.
  it "overrides English keys rather than introducing new ones" do
    expect(british_template_keys - english_template_keys).to be_empty
  end

  # Read from the files rather than the backend, which merges en_GB into en.
  def template_keys(locale)
    tree = YAML.load_file(File.expand_path("../../../lib/head_music/locales/#{locale}.yml", __dir__))
      .dig(locale.to_s, "head_music", "style") || {}
    leaf_paths(tree).map { |path| without_plural_form(path).join(".") }.uniq
  end

  def without_plural_form(path)
    PLURAL_KEYS.include?(path.last.to_sym) ? path[0..-2] : path
  end

  def leaf_paths(tree, path = [])
    return [path] unless tree.is_a?(Hash)

    tree.flat_map { |key, value| leaf_paths(value, path + [key]) }
  end

  def british_template_keys = @british_template_keys ||= template_keys(:en_GB)

  def english_template_keys = @english_template_keys ||= template_keys(:en)

  # es does not route through en_GB and en_US resolves past it, so both read
  # American. Pinned so that a chain edit that changes what they read fails here
  # rather than reaching a reader.
  it "leaves the locales that do not resolve through en_GB reading American" do
    expect(strings_in(:en_US)).to eq strings_in(:en)
    expect(strings_in(:es)).to eq strings_in(:en)
  end

  # What a German reader actually resolves to, said out loud. The day the chain
  # changes, this fails instead of the pronunciation quietly changing.
  it "resolves the mid-chain locales through en_GB" do
    resolved = %i[de fr it ru].map do |locale|
      HeadMusic::Style::Template.resolved_locale("guidelines.note_count_per_bar.instruction", locale: locale)
    end

    expect(resolved).to all eq :en_GB
  end

  # The path a student actually reads is the assessment, not the preview.
  # Rendering it through Template directly gave it neither the item's
  # interpolations nor the plural fallback the preview had.
  describe "the assessment's message" do
    let(:item) { HeadMusic::Style::Guidelines::MinimumNotes.with(8) }

    # Built directly: the wording is the subject here, not the finding, and a
    # voice would only be scenery.
    let(:assessment) do
      HeadMusic::Style::GuideItemAssessment.new(
        voice: nil, guide_item: item, tier: :primary, marks: [], fitness: 0.5,
        violation_key: item.guideline.violation_key(item.config)
      )
    end

    it "renders through the same seam as the item's preview" do
      expect(assessment.message).to eq item.violation_preview
      expect(assessment.message).to eq "Write at least eight notes."
    end

    it "follows the same language as every other string" do
      expect(I18n.with_locale(:de) { assessment.message }).to eq I18n.with_locale(:en_GB) { assessment.message }
    end
  end

  # de, fr, it and ru all resolve through en_GB before reaching en. I18n stops
  # at a plural hash that is present but incomplete rather than continuing past
  # it, so a British entry with only `other:` would raise for those four
  # languages and not for British readers -- who would never see it.
  def partial_plurals_in(tree, path = [])
    return [] unless tree.is_a?(Hash)

    keys = tree.keys.map(&:to_sym)
    here = if (keys & PLURAL_KEYS).any? && (keys & ENGLISH_PLURAL_KEYS).size < ENGLISH_PLURAL_KEYS.size
      [path.join(".")]
    else
      []
    end
    here + tree.flat_map { |key, value| partial_plurals_in(value, path + [key]) }
  end

  it "gives every pluralized en_GB entry a complete set of forms" do
    british = I18n.backend.send(:translations).fetch(:en_GB).dig(:head_music, :style) || {}

    expect(partial_plurals_in(british)).to be_empty
  end

  # Proves the detector fires, which the guard above cannot: it asserts an
  # absence, and an absence is what a walk over the wrong tree also reports.
  it "would catch a British entry that carried only one form" do
    incomplete = {guidelines: {note_count_per_bar: {name: {other: "%{number} crotchets per bar"}}}}

    expect(partial_plurals_in(incomplete)).to eq ["guidelines.note_count_per_bar.name"]
  end

  # And proves it fires at the real tree. The vocabulary entries are the only
  # pluralized British data, so a typo that dropped rhythmic_units entirely
  # would leave the guard above green over nothing -- passing for the reason it
  # passed before there was any British plural data at all.
  it "walks the British plural entries it is guarding" do
    british = I18n.backend.send(:translations).fetch(:en_GB).dig(:head_music, :style) || {}
    pluralized = british.fetch(:rhythmic_units).select { |_unit, forms| forms.is_a?(Hash) }

    expect(pluralized.keys).to match_array %i[whole half quarter]
    expect(pluralized.values.map(&:keys)).to all match_array ENGLISH_PLURAL_KEYS
  end

  # The Ruby fallback exists so a language with no plural data reads a little
  # wrong instead of raising. Reaching it for a guideline means an entry is
  # missing, which the fallback would otherwise hide forever.
  # What the load-time check found, kept rather than discarded, so thin locale
  # data is answerable at runtime instead of being noticed by a reader.
  it "loads with no plural gap to work around" do
    expect(described_class::PLURAL_GAPS).to be_empty
  end

  it "needs the Ruby plural fallback for no guideline in any language" do
    already_recorded = HeadMusic::Style::Template.fell_back_to_ruby.dup

    I18n.available_locales.each { |locale| problems_in(locale) }

    expect(HeadMusic::Style::Template.fell_back_to_ruby - already_recorded).to be_empty
  end
end
