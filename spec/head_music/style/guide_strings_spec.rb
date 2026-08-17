require "spec_helper"

# The companion to guide_item_strings_spec, which pins the exact English. This
# asserts the properties that must hold for every string in every language: it
# renders, it is a string, and no interpolation survives into it.
#
# A guideline added without an entry, a template whose values the guideline
# stopped passing, or a locale that stops resolving fails here rather than in
# front of a student.
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

  # The Ruby fallback exists so a language with no plural data reads a little
  # wrong instead of raising. Reaching it for a guideline means an entry is
  # missing, which the fallback would otherwise hide forever.
  it "needs the Ruby plural fallback for no guideline in any language" do
    already_recorded = HeadMusic::Style::Template.fell_back_to_ruby.dup

    I18n.available_locales.each { |locale| problems_in(locale) }

    expect(HeadMusic::Style::Template.fell_back_to_ruby - already_recorded).to be_empty
  end
end
