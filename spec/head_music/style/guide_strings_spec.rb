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

describe HeadMusic::Style::Guide do
  let(:guides) { HeadMusic::Style::Guide::ALL }
  let(:items) { guides.flat_map(&:guide_items).uniq }

  # Collected rather than asserted one at a time: 8 locales x (23 guides + 67
  # items x 3 templates) is far too many examples, and a list of every broken
  # string is a better failure than the first one.
  def problems_in(locale)
    I18n.with_locale(locale) do
      guides.filter_map { |guide| problem_with(guide, :instruction) } +
        items.flat_map { |item| %i[name instruction violation_preview].filter_map { |m| problem_with(item, m) } }
    end
  end

  def problem_with(subject, method)
    rendered = subject.public_send(method)
    return "#{subject.inspect}##{method} is not a string" unless rendered.is_a?(String)
    return "#{subject.inspect}##{method} is empty" if rendered.empty?
    return "#{subject.inspect}##{method} left an interpolation: #{rendered}" if rendered.include?("%{")

    nil
  rescue => error
    "#{subject.inspect}##{method}: #{error.class}: #{error.message}"
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

  # There are no pluralized British entries yet, so the guard above would pass
  # on an empty tree. This is what it is guarding against.
  it "would catch a British entry that carried only one form" do
    incomplete = {guidelines: {note_count_per_bar: {name: {other: "%{number} crotchets per bar"}}}}

    expect(partial_plurals_in(incomplete)).to eq ["guidelines.note_count_per_bar.name"]
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
