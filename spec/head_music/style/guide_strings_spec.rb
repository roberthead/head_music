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

# The exact set each locale must carry, not a minimum. A subset test cannot
# catch Russian written with English's forms, because {one, few, many, other} is
# a superset of {one, other} -- and on the Simple backend that hash renders
# `other` for counts 2, 3 and 5 without raising.
LOCALE_PLURAL_FORMS = {en: ENGLISH_PLURAL_KEYS, en_GB: ENGLISH_PLURAL_KEYS, ru: %i[one few many]}.freeze

# The three vocabulary groups a style sentence borrows from. Separate rather
# than one, because the relationship between them is a per-language fact:
# British collapses note_values into rhythmic_units, American needs the noun to
# tell them apart, and French names its rests from an unrelated vocabulary.
VOCABULARY_GROUPS = %w[rhythmic_units note_values rest_values].freeze

# Exempt from the data-level sweep because no pattern can attribute them. Above
# the double whole every language, American included, uses the Latin name, so
# maxima and longa are spelled the same everywhere; semibreve and breve are
# shared between British and Italian. These are the words the story expected
# French noire to be -- measured, noire scores zero hits in the English corpus
# and needs no exemption, while these four cannot be told apart.
SHARED_MENSURAL_UNITS = %w[maxima longa double_whole whole].freeze

# Identifiers with no vocabulary, which is allowed as long as it is declared:
# reaching one raises MissingTemplate by name rather than rendering the wrong
# note value, which is what quadruple_whole did.
#
# Only the 256th remains. No source in any of the seven languages names it, and
# nothing in the gem renders it.
UNTRANSLATED_UNITS = %w[two_hundred_fifty_sixth].freeze

# The note-value words each naming family uses. American stays scoped to
# note|rest: a bare word alternation matches the same strings today, but "half
# step", "whole tone" and "half cadence" are ordinary theory terms waiting to
# false-fire. British needs its word boundary -- an unanchored /minim/ flags
# every "Minimum of ..." string MinimumNotes produces.
NOTE_VOCABULARIES = {
  american: /\b(whole|half|quarter|eighth|sixteenth)[-\s](note|rest)/i,
  british: /\b(semibreve|minim|crotchet|quaver|semiquaver)s?\b/i,
  # Capitalization is the anchor for the compounds -- Viertel is a note value,
  # viertel is not a word -- but ganz and halb are adjectives that stay
  # lowercase in their two-word forms, so those two carry both cases. No /i:
  # case is what does the work here.
  german: /\b([Gg]anze|[Hh]albe|Viertel|Achtel|Sechzehntel|Zweiunddreißigstel|Vierundsechzigstel|Hundertachtundzwanzigstel)(n|note|noten|pause|pausen)?\b/
}.freeze

# Which vocabulary each locale resolves to. de, fr, it and ru read British by
# inheritance, deliberately: they route through en_GB, and no choice of English
# serves all four, so the story that gives them their own note values moves
# these rows rather than reordering the chain. This map is that decision in
# executable form -- edit the fallback chain and the sweep below fails until the
# map moves with it.
LOCALE_NOTE_VOCABULARY = {
  en: :american, en_US: :american, es: :american,
  en_GB: :british, fr: :british, it: :british, ru: :british,
  de: :german
}.freeze

describe HeadMusic::Style::Guide do
  let(:guides) { HeadMusic::Style::Guide::ALL }
  let(:items) { guides.flat_map(&:guide_items).uniq }

  # Collected rather than asserted one at a time: 8 locales x (30 guides x 2 +
  # 67 items x 3 templates) is far too many examples, and a list of every
  # broken string is a better failure than the first one.
  def problems_in(locale)
    I18n.with_locale(locale) do
      guides.flat_map { |guide| %i[display_name instruction].filter_map { |m| problem_with(guide, m) } } +
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
    # A blank interpolated value passes every check above: "Use eight
    # %{rhythmic_unit} in each bar" renders "Use eight  in each bar". Anchored
    # because "%{number} crotchets per bar" opens with its interpolation.
    return "#{label} rendered a blank value: #{rendered.inspect}" if rendered.match?(/\s\s|\s[.,;:]|\A\s|\s\z/)

    nil
  end

  I18n.available_locales.each do |locale|
    it "renders every guide and guide item string in #{locale}" do
      expect(problems_in(locale)).to be_empty
    end
  end

  # A canary: meant to fail when a guide or item is added, so the addition
  # gets swept. Update the numbers; do not loosen them.
  it "covers every registry entry" do
    expect(guides.size).to eq 30
    expect(items.size).to eq 67
  end

  # display_name, not name: the name methods return Ruby class names. Shared
  # with the locale-equality examples so that a locale-specific
  # guides.<key>.name is checked into the right file and de inherits it.
  def strings_in(locale)
    I18n.with_locale(locale) do
      guides.flat_map { |guide| [guide.display_name, guide.instruction] } +
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

  # The original bug was mixed language *inside one string*: the sentence fell
  # back to English while the number humanized into German, so a reader got
  # "Write at least Acht notes." -- neither language, the capitalization reading
  # as a typo.
  #
  # Asserted per string rather than by comparing whole locales, because German
  # now carries some of its own: a locale is expected to be a mix of languages
  # across its strings, and is never allowed to be a mix within one.
  it "renders each string wholly in one language" do
    mixed = strings_in(:de).select do |string|
      NOTE_VOCABULARIES.count { |_, pattern| pattern.match?(string) } > 1
    end

    expect(mixed).to be_empty
  end

  # Proves that property can fail, which an absence-assertion cannot.
  it "would catch a sentence built from two languages" do
    frankenstein = "In jedem mittleren Takt vier Viertel statt crotchets verwenden."

    expect(NOTE_VOCABULARIES.count { |_, pattern| pattern.match?(frankenstein) }).to eq 2
  end

  # The executable form of "a British reader gets British note values". Written
  # as ownership rather than as a British-versus-American pair so that a locale
  # gaining its own note words changes a row above, not this example. fetch with
  # no default means a locale added to the gem fails here until someone decides
  # which vocabulary it reads, rather than being swept as American by default.
  it "gives every locale only the note vocabulary it owns" do
    expect(I18n.available_locales.flat_map { |locale| foreign_vocabulary_in(locale) }).to be_empty
  end

  # Enforces the narrowness NOTE_VOCABULARIES explains. The third string is
  # the display name sixteenth-century-style.md adds, spared only by the noun.
  it "spares the theory terms the scoping exists to protect" do
    expect(NOTE_VOCABULARIES.values.flat_map { |pattern| spared_theory_terms.grep(pattern) }).to be_empty
  end

  def spared_theory_terms
    [
      "Approach the half step by contrary motion.",
      "Minimum of eight notes.",
      "Sixteenth Century Cantus Firmus"
    ]
  end

  # The sweep asserts an absence, and a broken pattern reports the same
  # absence. Each locale must actually carry its own family somewhere.
  it "recognizes each locale's own note vocabulary" do
    silent = LOCALE_NOTE_VOCABULARY.reject do |locale, family|
      strings_in(locale).any? { |string| NOTE_VOCABULARIES.fetch(family).match?(string) }
    end

    expect(silent.keys).to be_empty
  end

  # A guide name with a note value would pass unless names are in the swept
  # list. They were not: the sweep read instructions only.
  it "sweeps the guide names a reader sees, not only the instructions" do
    names = I18n.with_locale(:en_GB) { guides.map(&:display_name) }

    expect(names - strings_in(:en_GB)).to be_empty
  end

  # A guide with no name entry renders its humanized key in every locale, so
  # whole_note_species reads "Whole Note Species" to a British student too.
  # The remedy is a guides.<key>.name in en.yml with an en_GB override.
  it "would catch an American note value in a guide name" do
    expect(foreign_vocabulary_among(["Whole Note Species"], :en_GB)).not_to be_empty
  end

  def foreign_vocabulary_in(locale) = foreign_vocabulary_among(strings_in(locale), locale)

  def foreign_vocabulary_among(strings, locale)
    foreign = NOTE_VOCABULARIES.except(LOCALE_NOTE_VOCABULARY.fetch(locale))
    strings.flat_map do |string|
      foreign.filter_map { |family, pattern| "#{locale}: #{family} in #{string.inspect}" if pattern.match?(string) }
    end
  end

  # The prose scan above catches a foreign word hard-coded into a *sentence* --
  # the way en_GB writes "quavers" into allow_fifth_species_rhythmic_values.
  # It cannot catch a locale whose vocabulary hash carries the wrong family,
  # because that word only reaches prose through the four unit/count pairs
  # note_count_per_bar renders. Six of the ten units and both of the other two
  # groups never appear in a sentence at all.
  #
  # So the vocabulary is checked as data, against the family the locale owns.
  #
  describe "the vocabulary as data" do
    def vocabulary_values(locale)
      tree = I18n.backend.send(:translations).fetch(locale).dig(:head_music, :rudiments) || {}
      VOCABULARY_GROUPS.flat_map do |group|
        (tree[group.to_sym] || {}).reject { |unit, _| SHARED_MENSURAL_UNITS.include?(unit.to_s) }
          .flat_map { |unit, value| Array(value.is_a?(Hash) ? value.values : value).map { |v| [group, unit, v] } }
      end
    end

    # Read from the backend for the locale itself, not the chain: a locale that
    # carries no vocabulary of its own has nothing to be wrong about here, and
    # is covered by the prose sweep instead.
    def foreign_vocabulary_data_in(locale)
      own = LOCALE_NOTE_VOCABULARY.fetch(locale)
      NOTE_VOCABULARIES.except(own).flat_map do |family, pattern|
        vocabulary_values(locale).filter_map do |group, unit, value|
          "#{locale}.#{group}.#{unit} = #{value.inspect} matches #{family}" if pattern.match?(value)
        end
      end
    end

    it "gives every locale only words from the family it owns" do
      offenders = LOCALE_NOTE_VOCABULARY.keys.select { |locale| I18n.backend.send(:translations).key?(locale) }
        .flat_map { |locale| foreign_vocabulary_data_in(locale) }

      expect(offenders).to be_empty
    end

    # Proves it fires. A British crotchet filed under American English is the
    # exact leak the prose sweep cannot see, because no sentence renders it.
    it "would catch a locale carrying another family's word" do
      I18n.backend.store_translations(:en, {head_music: {rudiments: {rest_values: {sixteenth: "semiquaver rest"}}}})

      expect(foreign_vocabulary_data_in(:en)).to include(/rest_values.sixteenth/)
    ensure
      I18n.backend.reload!
      I18n.backend.send(:init_translations)
    end

    # The exemption has to be narrow enough to still be worth having.
    it "exempts only the units no pattern can attribute" do
      expect(SHARED_MENSURAL_UNITS).not_to include("half", "quarter", "eighth")
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

  # The one guard the prose sweep cannot be: the American pattern needs its
  # note|rest noun, and the British sentence drops that noun by design, so a
  # unit with no British name renders as a bare "eighth" that no pattern can
  # flag without also flagging "half step". Scoped to rhythmic_units because
  # en_GB deliberately overrides only some keys; here a missing key is a leak.
  it "gives every English rhythmic unit a British name" do
    expect(vocabulary_keys(english_template_keys)).not_to be_empty
    expect(unnamed_vocabulary(english: english_template_keys,
      british: british_template_keys)).to be_empty
  end

  # Proves the diff fires, which an absence-assertion cannot. Inline rather
  # than injected into the real list, so a real gap cannot report itself
  # twice; the guideline key is unmatched on purpose, showing the scoping.
  it "would catch a rhythmic unit added to English alone" do
    english = ["rhythmic_units.whole", "rest_values.eighth", "guidelines.no_rests.name"]
    british = ["rhythmic_units.whole"]

    expect(unnamed_vocabulary(english: english, british: british)).to eq ["rest_values.eighth"]
  end

  # Read from the files rather than the backend, which merges en_GB into en.
  def template_keys(locale)
    tree = YAML.load_file(File.expand_path("../../../lib/head_music/locales/#{locale}.yml", __dir__))
      .fetch(locale.to_s)
    leaf_paths(localized_string_tree(tree, "")).map { |path| without_plural_form(path).join(".") }.uniq
  end

  # Two namespaces: the sentences under style, and the vocabulary they borrow
  # under rudiments, where the words belong to the rudiment rather than to the
  # guideline naming it. Rejoined under the key shape the sentences address them
  # by, so every guard below reads the same whether the vocabulary sits beside
  # the guidelines or beneath rudiments.
  def localized_string_tree(tree, key = :"")
    style = tree.dig(key_for("head_music", key), key_for("style", key)) || {}
    VOCABULARY_GROUPS.reduce(style) do |merged, group|
      found = tree.dig(key_for("head_music", key), key_for("rudiments", key), key_for(group, key))
      (found.nil? || found.empty?) ? merged : merged.merge(key_for(group, key) => found)
    end
  end

  # The file is string-keyed and the backend is symbol-keyed; both are walked.
  def key_for(name, sample) = sample.is_a?(Symbol) ? name.to_sym : name

  def british_string_tree
    localized_string_tree(I18n.backend.send(:translations).fetch(:en_GB))
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

  def vocabulary_keys(keys) = keys.grep(/\A(#{VOCABULARY_GROUPS.join("|")})\./)

  # Keywords: swapped positional arguments would invert the direction and
  # stay green over a real gap.
  def unnamed_vocabulary(english:, british:)
    vocabulary_keys(english) - vocabulary_keys(british)
  end

  # The English a reader sees today, captured before the vocabulary moved and
  # frozen. Nothing else pins en_GB's names and instructions, so without this a
  # refactor of the rendering path could rewrite British prose and stay green.
  #
  # Regenerate deliberately -- never to make a red suite green -- with:
  #   bundle exec rake style:snapshot_english
  describe "the English strings" do
    let(:snapshot) do
      YAML.load_file(File.expand_path("../../fixtures/style/english_strings.yml", __dir__))
    end

    %w[en en_GB].each do |locale|
      it "renders #{locale} exactly as it did before the vocabulary moved" do
        expect(strings_in(locale.to_sym)).to eq snapshot.fetch(locale)
      end
    end
  end

  # quadruple_whole did not merely fail to resolve -- RhythmicUnit::PATTERN is a
  # Regexp.union and the key contains "whole", so RhythmicValue.get returned the
  # whole note at duration 1.0 while the sentence said "quadruple whole note". A
  # key that is not an identifier is a wrong analysis, not a missing string.
  #
  describe "the vocabulary keys" do
    let(:identifiers) { HeadMusic::Rudiment::RhythmicUnit.all.map { |unit| unit.name.tr(" -", "__") } }
    let(:keys) { VOCABULARY_GROUPS.flat_map { |group| english_tree.fetch(group, {}).keys }.uniq }

    def english_tree
      YAML.load_file(File.expand_path("../../../lib/head_music/locales/en.yml", __dir__))
        .dig("en", "head_music", "rudiments")
    end

    it "names a real rhythmic unit with every one of them" do
      expect(keys - identifiers).to be_empty
    end

    it "translates every identifier it does not declare untranslated" do
      expect(identifiers - keys - UNTRANSLATED_UNITS).to be_empty
    end

    # Proves the guard above would have caught quadruple_whole, which resolved
    # to the whole note rather than raising.
    it "would catch a key that is not an identifier" do
      expect(%w[longa quadruple_whole] - identifiers).to eq ["quadruple_whole"]
    end
  end

  # %{number} is not confined to note_count_per_bar: MinimumNotes renders eight,
  # the cantus firmus range renders eight to fourteen, and one guideline renders
  # thirty-two. A locale that spells its own numerals must cover every count the
  # registry reaches, or a guideline silently drops an English word into its
  # sentence -- exactly the failure the locale pin exists to prevent.
  describe "the spelled-out numerals" do
    let(:counts) do
      rendered = []
      HeadMusic::Style::Template.singleton_class.prepend(Module.new do
        define_method(:number_word) do |number, locale: I18n.locale|
          rendered << number
          super(number, locale: locale)
        end
      end)
      I18n.with_locale(:en) { problems_in(:en) }
      rendered.uniq.sort
    end

    def locales_spelling_their_own
      I18n.available_locales.select do |locale|
        I18n.exists?("head_music.number_words", locale, fallback: false)
      end
    end

    it "covers every count the registry renders, in every locale that spells any" do
      missing = locales_spelling_their_own.flat_map do |locale|
        counts.reject { |count| I18n.exists?("head_music.number_words.#{count}", locale, fallback: false) }
          .map { |count| "#{locale}.#{count}" }
      end

      expect(missing).to be_empty
    end

    it "reaches counts beyond the four that note_count_per_bar renders" do
      expect(counts).to include(8)
    end
  end

  # es does not route through en_GB and en_US resolves past it, so both read
  # American. Pinned so that a chain edit that changes what they read fails here
  # rather than reaching a reader.
  it "leaves the locales that do not resolve through en_GB reading American" do
    expect(strings_in(:en_US)).to eq strings_in(:en)
    expect(strings_in(:es)).to eq strings_in(:en)
  end

  # What each reader actually resolves to, said out loud. The day the chain
  # changes, this fails instead of the pronunciation quietly changing.
  #
  # Split when German gained its own sentences: a locale now resolves per key,
  # to itself where it carries the entry and through en_GB where it does not.
  it "resolves a locale to itself for the entries it carries" do
    resolved = HeadMusic::Style::Template.resolved_locale(
      "guidelines.note_count_per_bar.instruction", locale: :de
    )

    expect(resolved).to eq :de
  end

  it "still routes the locales with no entry of their own through en_GB" do
    resolved = %i[fr it ru].map do |locale|
      HeadMusic::Style::Template.resolved_locale("guidelines.note_count_per_bar.instruction", locale: locale)
    end

    expect(resolved).to all eq :en_GB
  end

  # German carries 32 of the 224 style leaves, so most of what a German reader
  # sees is still English -- and which English depends on whether en_GB happens
  # to override that entry. Pinned rather than left implicit: shipping a locale
  # that is 15% translated is a decision, and so is the day it changes.
  it "still falls through German for the entries it does not carry" do
    template = HeadMusic::Style::Template

    expect(template.resolved_locale("guidelines.no_rests.instruction", locale: :de)).to eq :en_GB
    expect(template.resolved_locale("guidelines.singable_intervals.instruction", locale: :de)).to eq :en
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
  # Exact set, not a subset: Russian's {one, few, many} and English's
  # {one, other} are each wrong for the other locale, and a subset test passes
  # a superset silently.
  def wrong_plurals_in(tree, forms, path = [])
    return [] unless tree.is_a?(Hash)

    keys = tree.keys.map(&:to_sym)
    here = ((keys & PLURAL_KEYS).any? && keys.sort != forms.sort) ? [path.join(".")] : []
    here + tree.flat_map { |key, value| wrong_plurals_in(value, forms, path + [key]) }
  end

  it "gives every pluralized en_GB entry a complete set of forms" do
    expect(wrong_plurals_in(british_string_tree, LOCALE_PLURAL_FORMS.fetch(:en_GB))).to be_empty
  end

  # Proves the detector fires, which the guard above cannot: it asserts an
  # absence, and an absence is what a walk over the wrong tree also reports.
  it "would catch a British entry that carried only one form" do
    incomplete = {guidelines: {note_count_per_bar: {name: {other: "%{number} crotchets per bar"}}}}

    expect(wrong_plurals_in(incomplete, ENGLISH_PLURAL_KEYS)).to eq ["guidelines.note_count_per_bar.name"]
  end

  # The trap the old subset test could not see. {one, few, many, other} contains
  # English's pair, so a subset check passes it -- while the Simple backend
  # renders `other` for counts 2, 3 and 5 and raises nothing.
  it "would catch a Russian entry written with English's forms" do
    english_shaped = {rhythmic_units: {half: {one: "половинная", other: "половинные"}}}
    over_supplied = {rhythmic_units: {half: {one: "a", few: "b", many: "c", other: "d"}}}
    russian = LOCALE_PLURAL_FORMS.fetch(:ru)

    expect(wrong_plurals_in(english_shaped, russian)).to eq ["rhythmic_units.half"]
    expect(wrong_plurals_in(over_supplied, russian)).to eq ["rhythmic_units.half"]
  end

  # And that the tree it walks is there and well formed -- an empty tree
  # passes the guard above exactly as it passed before any British plural data
  # existed. Says every unit rather than naming today's three, so adding
  # quaver does not fail like a regression.
  it "walks the British plural entries it is guarding" do
    units = british_string_tree.fetch(:rhythmic_units)

    expect(units).not_to be_empty
    expect(units.values).to all be_a(Hash)
    expect(units.values.map(&:keys)).to all match_array LOCALE_PLURAL_FORMS.fetch(:en_GB)
  end

  # What the load-time check found, kept rather than discarded, so thin locale
  # data is answerable at runtime instead of being noticed by a reader.
  it "loads with no plural gap to work around" do
    expect(described_class::PLURAL_GAPS).to be_empty
  end

  # The Ruby fallback exists so a language with no plural data reads a little
  # wrong instead of raising. Reaching it for a guideline means an entry is
  # missing, which the fallback would otherwise hide forever.
  it "needs the Ruby plural fallback for no guideline in any language" do
    already_recorded = HeadMusic::Style::Template.fell_back_to_ruby.dup

    I18n.available_locales.each { |locale| problems_in(locale) }

    expect(HeadMusic::Style::Template.fell_back_to_ruby - already_recorded).to be_empty
  end
end
