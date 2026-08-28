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
            # The en_GB landmine: a form present, the one needed missing.
            partial: {one: "Write at least %{number} note."},
            # Plural forms English cannot select from -- what a correct Russian
            # entry looks like to a backend without I18n::Backend::Pluralization.
            uncountable: {few: "Write at least %{number} notes.", many: "Write at least %{number} notes."},
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
      expect(described_class.pluralize("spec_probe.counted", count: 1, number: "one")).to eq "one note"
    end

    # A language the gem has no plural data for should read a little wrong
    # rather than raise at a student. A partial plural hash mid-chain stops the
    # fallback rather than continuing past it, so it lands here too.
    context "when the locale cannot answer" do
      # The wrong plural is the bargain. Dropping the sentence is not: a bare
      # "four notes" says nothing about what to write.
      it "keeps the sentence, reading the form the locale does carry" do
        expect(described_class.pluralize("spec_probe.partial", count: 4, number: "four"))
          .to eq "Write at least four note."
      end

      it "reads any form when the locale offers none English can select" do
        expect(described_class.pluralize("spec_probe.uncountable", count: 4, number: "four"))
          .to eq "Write at least four notes."
      end

      it "records the gap so it is known rather than invisible" do
        described_class.pluralize("spec_probe.partial", count: 4, number: "four")

        expect(described_class.fell_back_to_ruby).to include "spec_probe.partial"
      end
    end

    # The fallback is for a locale that cannot pluralize, not for a template
    # that is wrong. Catching both would hide from verify! the one failure it
    # loads early to find, and hand a student "four notes" where a sentence
    # should be.
    context "when the template itself is broken" do
      it "refuses a plural template it could not fill" do
        expect { described_class.pluralize("spec_probe.miscounted", count: 4, number: "four") }
          .to raise_error(described_class::MissingTemplate, /interpolation/)
      end

      it "refuses a plural key that does not exist" do
        expect { described_class.pluralize("spec_probe.absent", count: 4) }
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
    # Lowercase, where humanize returns "Acht": these land mid-sentence.
    it "speaks the number in the reader's language" do
      expect(described_class.number_word(8, locale: :de)).to eq "acht"
    end

    # humanize raises for a locale it does not ship, and the gem ships two it
    # does not know, so the chain is walked rather than asked directly. Shown
    # with a count no guideline renders, since the ones that are rendered are
    # spelled out above and never reach humanize.
    it "falls down the chain for a locale humanize does not know" do
      expect(described_class.humanize_locale(:it)).to eq :en
      expect(described_class.number_word(7, locale: :it)).to eq "seven"
    end

    # Which is why the counts a sentence actually renders are spelled out. The
    # chain above is the reason Italian would otherwise read "Scrivi four
    # semiminime": humanize has no Italian to fall down to.
    it "prefers the locale's own numeral to what humanize would return" do
      expect(described_class.number_word(4, locale: :it)).to eq "quattro"
      expect(described_class.number_word(1, locale: :de)).to eq "eine"
    end

    it "leaves English to humanize" do
      expect(described_class.number_word(4, locale: :en)).to eq "four"
      expect(described_class.number_word(4, locale: :en_GB)).to eq "four"
    end
  end

  # I18n's Simple backend implements English's one/other and nothing else, so a
  # Russian entry carrying one/few/many renders `other` for counts 2, 3 and 5 --
  # or raises when `other` is absent, which is the seam this uses.
  describe "a locale whose plural rule the backend does not implement" do
    let(:key) { "rhythmic_units.half" }
    let(:scope) { described_class::RUDIMENT_SCOPE }

    before do
      I18n.backend.store_translations(
        :ru, {head_music: {rudiments: {rhythmic_units: {half: {one: "одна", few: "две", many: "пять"}}}}}
      )
      described_class.fell_back_to_ruby.clear
    end

    def form_for(count) = I18n.with_locale(:ru) { described_class.pluralize(key, count: count, scope: scope) }

    it "chooses one for 1 and 21, but not for 11" do
      expect([form_for(1), form_for(21), form_for(101)]).to all eq "одна"
      expect(form_for(11)).to eq "пять"
    end

    it "chooses few for 2 through 4, but not for 12 through 14" do
      expect([form_for(2), form_for(3), form_for(4), form_for(22)]).to all eq "две"
      expect([form_for(12), form_for(13)]).to all eq "пять"
    end

    it "chooses many for 5 and above" do
      expect([form_for(5), form_for(25), form_for(100)]).to all eq "пять"
    end

    # Applying a rule the gem knows is not a fallback. Recorded as one, every
    # Russian sentence would report a plural gap and the guard watching for real
    # ones would have to be loosened until it caught nothing.
    it "does not record a known rule as a fallback" do
      form_for(2)

      expect(described_class.fell_back_to_ruby).to be_empty
    end

    # Under a key of its own: every shipped entry is now complete, so a real one
    # would have to be broken to prove the fallback still works.
    it "still records a genuinely thin entry" do
      I18n.backend.store_translations(:fr, {head_music: {rudiments: {rhythmic_units: {thin: {other: "blanches"}}}}})

      I18n.with_locale(:fr) { described_class.pluralize("rhythmic_units.thin", count: 1, scope: scope) }

      expect(described_class.fell_back_to_ruby).to eq ["rhythmic_units.thin"]
    end
  end

  describe ".verify!" do
    let(:item) { instance_double(HeadMusic::Style::GuideItem, name: "n", instruction: "i", violation_previews: ["v"]) }
    # A guide is a class rather than an instance of one.
    let(:guide) { class_double(HeadMusic::Style::Guides::Base, instruction: "write something", guide_items: [item]) }

    it "asks for every string a guide can produce" do
      expect { described_class.verify!([guide]) }.not_to raise_error

      expect(item).to have_received(:violation_previews)
    end

    # Otherwise this is a decorative call at the bottom of guide.rb.
    it "raises for a guide item whose template is missing" do
      allow(item).to receive(:violation_previews).and_raise(described_class::MissingTemplate)

      expect { described_class.verify!([guide]) }.to raise_error(described_class::MissingTemplate)
    end

    # The Ruby plural fallback is deliberate, but a silent one would hide thin
    # locale data forever. A library has no business printing, so the report is
    # what comes back.
    it "reports the keys that needed the Ruby plural fallback" do
      allow(item).to receive(:violation_previews) do
        [described_class.pluralize("spec_probe.partial", count: 4, number: "four")]
      end

      expect(described_class.verify!([guide])).to eq ["spec_probe.partial"]
    end

    it "reports nothing when every string rendered from the locale" do
      expect(described_class.verify!([guide])).to be_empty
    end

    # The host application's locale must not decide whether the gem loads.
    it "verifies in English whatever locale is current" do
      allow(guide).to receive(:instruction) { I18n.locale }

      I18n.with_locale(:ru) { described_class.verify!([guide]) }

      expect(guide).to have_received(:instruction).at_least(:once)
    end
  end
end
