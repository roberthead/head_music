require "spec_helper"

describe HeadMusic::Style::Template do
  before do
    I18n.backend.store_translations(:en, {
      head_music: {
        style: {
          spec_probe: {
            filled: "Write at least %{minimum} notes.",
            unfilled: "Use %{number} %{unit} notes.",
            counted: {one: "%{number} note", other: "%{number} notes"},
            # Plural forms English cannot select from -- what a correct Russian
            # entry looks like to a backend without I18n::Backend::Pluralization.
            uncountable: {few: "%{number} notes", many: "%{number} notes"},
            miscounted: {one: "%{bogus} note", other: "%{bogus} notes"}
          }
        }
      }
    })
  end

  describe ".render" do
    it "interpolates the values it is given" do
      expect(described_class.render("spec_probe.filled", minimum: "eight")).to eq "Write at least eight notes."
    end

    # I18n returns the raw template when given no values at all, without
    # raising even under raise: true, so a guideline whose values come from
    # class constants rather than config would ship "%{number}" to a student.
    it "refuses a template it could not fill" do
      expect { described_class.render("spec_probe.unfilled") }
        .to raise_error(described_class::MissingTemplate, /interpolation/)
    end

    # A missing key resolves to "Translation missing: ..." rather than raising.
    it "refuses a key that does not exist" do
      expect { described_class.render("spec_probe.absent") }.to raise_error(described_class::MissingTemplate)
    end

    # I18n reads these rather than interpolating them, so a guideline option by
    # one of these names would quietly hijack the lookup.
    it "refuses a value named for a key I18n reserves" do
      expect { described_class.render("spec_probe.filled", minimum: 1, default: "x") }
        .to raise_error(ArgumentError, /default/)
    end
  end

  describe ".pluralize" do
    it "uses the locale's plural forms when it has them" do
      expect(described_class.pluralize("spec_probe.counted", count: 1, singular: "note", number: "one"))
        .to eq "one note"
    end

    # A language the gem has no plural data for should read a little wrong
    # rather than raise at a student. This also covers a partial plural hash
    # mid-chain, which stops the fallback rather than continuing past it.
    context "when the locale cannot answer" do
      it "pluralizes in Ruby" do
        expect(described_class.pluralize("spec_probe.uncountable", count: 1, singular: "melodic interval"))
          .to eq "one melodic interval"
        expect(described_class.pluralize("spec_probe.uncountable", count: 4, singular: "melodic interval"))
          .to eq "four melodic intervals"
      end

      it "records the gap so it is known rather than invisible" do
        described_class.pluralize("spec_probe.uncountable", count: 1, singular: "note")

        expect(described_class.fell_back_to_ruby).to include "spec_probe.uncountable"
      end
    end

    # The fallback is for a locale that cannot pluralize, not for a template
    # that is wrong. Catching both would hide from verify! the one failure it
    # loads early to find, and hand a student "four notes" where a sentence
    # should be.
    context "when the template itself is broken" do
      it "refuses a plural template it could not fill" do
        expect { described_class.pluralize("spec_probe.miscounted", count: 4, singular: "note", number: "four") }
          .to raise_error(described_class::MissingTemplate, /interpolation/)
      end

      it "refuses a plural key that does not exist" do
        expect { described_class.pluralize("spec_probe.absent", count: 4, singular: "note") }
          .to raise_error(described_class::MissingTemplate)
      end
    end
  end

  describe ".resolved_locale" do
    # I18n.exists? consults the fallback chain and so answers true for every
    # locale; this has to say which one actually carries the entry.
    it "names the locale a template will really render in" do
      expect(described_class.resolved_locale("spec_probe.filled", locale: :de)).to eq :en
    end

    it "stays in the reader's own locale when it carries the entry" do
      expect(described_class.resolved_locale("guidelines.no_rests.violations.default", locale: :en_GB)).to eq :en_GB
    end
  end

  describe ".number_word" do
    it "speaks the number in the reader's language" do
      expect(described_class.number_word(8, locale: :de)).to eq "Acht"
    end

    # humanize raises for a locale it does not ship, and the gem ships two it
    # does not know, so the chain is walked rather than asked directly.
    it "falls down the chain for a locale humanize does not know" do
      expect(described_class.humanize_locale(:it)).to eq :en
      expect(described_class.number_word(8, locale: :it)).to eq "eight"
    end
  end

  describe ".verify!" do
    let(:item) { instance_double(HeadMusic::Style::GuideItem, name: "n", instruction: "i", violation_preview: "v") }
    # A guide is a class rather than an instance of one.
    let(:guide) { class_double(HeadMusic::Style::Guides::Base, instruction: "write something", guide_items: [item]) }

    it "asks for every string a guide can produce" do
      expect { described_class.verify!([guide]) }.not_to raise_error

      expect(item).to have_received(:violation_preview)
    end

    # Otherwise this is a decorative call at the bottom of guide.rb.
    it "raises for a guide item whose template is missing" do
      allow(item).to receive(:violation_preview).and_raise(described_class::MissingTemplate)

      expect { described_class.verify!([guide]) }.to raise_error(described_class::MissingTemplate)
    end

    # The host application's locale must not decide whether the gem loads.
    it "verifies in English whatever locale is current" do
      allow(guide).to receive(:instruction) { I18n.locale }

      I18n.with_locale(:ru) { described_class.verify!([guide]) }

      expect(guide).to have_received(:instruction).at_least(:once)
    end
  end
end
