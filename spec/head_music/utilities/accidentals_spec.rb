require "spec_helper"

describe HeadMusic::Utilities::Accidentals do
  describe ".to_unicode" do
    context "with a bare accidental token" do
      {
        "b" => "♭",
        "bb" => "𝄫",
        "#" => "♯",
        "##" => "𝄪",
        "x" => "𝄪"
      }.each do |ascii, unicode|
        specify { expect(described_class.to_unicode(ascii)).to eq unicode }
      end
    end

    context "with a pitch name" do
      {
        "Bb" => "B♭",
        "F#" => "F♯",
        "Bbb" => "B𝄫",
        "Cx" => "C𝄪",
        "C##" => "C𝄪",
        "Ab7" => "A♭7",
        "C" => "C",
        "Bb4" => "B♭4",
        "F#4" => "F♯4"
      }.each do |ascii, unicode|
        specify { expect(described_class.to_unicode(ascii)).to eq unicode }
      end
    end

    context "with a chord symbol" do
      {
        "F#m" => "F♯m",
        "A#m" => "A♯m",
        "Bbm" => "B♭m",
        "Bbm7" => "B♭m7",
        "Ebmaj7" => "E♭maj7",
        "C#maj7" => "C♯maj7",
        "Abmin" => "A♭min",
        "F#dim" => "F♯dim",
        "Ebdim7" => "E♭dim7",
        "Abaug" => "A♭aug",
        "Bbsus4" => "B♭sus4",
        "BbM7" => "B♭M7",
        "Ebmajor" => "E♭major",
        "Gb7sus4" => "G♭7sus4",
        "C7alt" => "C7alt"
      }.each do |ascii, unicode|
        specify { expect(described_class.to_unicode(ascii)).to eq unicode }
      end
    end

    context "with altered chord extensions" do
      {
        "Bbmaj7#11" => "B♭maj7♯11",
        "C7b9" => "C7♭9",
        "C7#9" => "C7♯9",
        "C7b5" => "C7♭5",
        "G7#5b9" => "G7♯5♭9",
        "Db7b9#11" => "D♭7♭9♯11",
        "Ebmaj9#11" => "E♭maj9♯11",
        "Ab13b9" => "A♭13♭9",
        "F#7b13" => "F♯7♭13",
        "Cmaj7#11" => "Cmaj7♯11",
        "C7b6" => "C7♭6",
        "F7#4" => "F7♯4",
        "Bbm7b5" => "B♭m7♭5",
        "C13#11" => "C13♯11"
      }.each do |ascii, unicode|
        specify { expect(described_class.to_unicode(ascii)).to eq unicode }
      end
    end

    context "with a slash chord" do
      specify { expect(described_class.to_unicode("Bb/D")).to eq "B♭/D" }
      specify { expect(described_class.to_unicode("F#m7b5/Eb")).to eq "F♯m7♭5/E♭" }
      specify { expect(described_class.to_unicode("Bbmaj7#11/D")).to eq "B♭maj7♯11/D" }
    end

    context "with english prose" do
      # A capitalized word is the only prose at risk, since the letter-name lookbehind
      # is uppercase-only. Each of these clears the chord-quality allowlist by one
      # letter, which is why the allowlist stays as short as it is.
      %w[
        Above Absence Abbey Abbot Abrupt Ability Abandon Aberrant Abundant
        Absurd Abdomen Abdicate Abstract Absolute Abbreviate
        Bebop Bach Debussy Ebony Ebbing Ebbed Fabric Cabbage Dabble Adagio
        DB Text Exit
      ].each do |word|
        specify { expect(described_class.to_unicode(word)).to eq word }
      end

      it "leaves a lowercase accidental-shaped word alone" do
        expect(described_class.to_unicode("ebb and back")).to eq "ebb and back"
      end

      it "does not read a dominant seventh as a flat degree" do
        expect(described_class.to_unicode("B7")).to eq "B7"
      end

      it "leaves a markdown heading alone" do
        expect(described_class.to_unicode("## Heading")).to eq "## Heading"
      end

      it "converts accidentals embedded in a sentence" do
        expect(described_class.to_unicode("Above the Bbm7 we play Ebmaj7."))
          .to eq "Above the B♭m7 we play E♭maj7."
      end

      it "converts a chord with an altered extension embedded in a sentence" do
        expect(described_class.to_unicode("A Bb7#9 chord resolves nicely."))
          .to eq "A B♭7♯9 chord resolves nicely."
      end
    end

    context "with strings that only look like chord symbols" do
      # These are the reason the extension rule is scoped to a chord token rather than
      # applied globally. A bare digit-flanked rule converts every one of them.
      [
        "1.0b2", "0x1b2f", "0x1B2F", "1b2c3d", "version 3b7", "revision 2b1",
        "Figure 2b", "Chapter 7b", "Deadbeef", "DEADBEEF", "page 3b.",
        # These open with a letter name, so the chord token alone does not rule them
        # out. What does is that 2, 3, and 0 are not degrees a chord can alter.
        "A1b2", "Figure C2b3", "Exhibit A1b2", "E3b0c442", "G1b1", "B2b3"
      ].each do |text|
        specify { expect(described_class.to_unicode(text)).to eq text }
      end
    end

    it "is idempotent" do
      converted = described_class.to_unicode("Bbmaj7#11")
      expect(described_class.to_unicode(converted)).to eq converted
    end

    it "converts a double all-or-nothing rather than leaving a stray sign" do
      expect(described_class.to_unicode("C##")).not_to include "#"
    end

    it "leaves an unrecognized run of accidentals untouched" do
      expect(described_class.to_unicode("Bbbb")).to eq "Bbbb"
    end

    it "accepts a symbol" do
      expect(described_class.to_unicode(:Bb)).to eq "B♭"
    end

    # Both of these are narrower than Spelling.get, and deliberately so: a
    # case-insensitive rule reads the "B" of "B7" as a flat sign, and every lowercase
    # word in a sentence becomes a conversion candidate.
    context "when narrower than the pitch parsers" do
      it "ignores a lowercase pitch name that Spelling would accept" do
        expect(described_class.to_unicode("eb")).to eq "eb"
        expect(HeadMusic::Rudiment::Spelling.get("eb").to_s).to eq "E♭"
      end

      it "reads a bare token as an accidental rather than as a pitch name" do
        expect(described_class.to_unicode("bb")).to eq "𝄫"
        expect(HeadMusic::Rudiment::Spelling.get("bb").to_s).to eq "B♭"
      end
    end

    # Not valid notation in either direction, but the two families are asymmetric:
    # the flat branch's word-boundary guard rejects the whole run, while the sharp
    # branch has no guard and converts a prefix. Residue detection is a caller's job.
    context "with a run of accidentals too long to be valid" do
      specify { expect(described_class.to_unicode("Bbbb")).to eq "Bbbb" }
      specify { expect(described_class.to_unicode("C###")).to eq "C𝄪#" }
    end
  end

  describe ".to_ascii" do
    {
      "B♭" => "Bb",
      "F♯" => "F#",
      "B𝄫" => "Bbb",
      "C𝄪" => "Cx",
      "C" => "C",
      "B♭4" => "Bb4"
    }.each do |unicode, ascii|
      specify { expect(described_class.to_ascii(unicode)).to eq ascii }
    end

    it "emits the double sharp spelling the gem's parsers accept" do
      expect(described_class.to_ascii("C𝄪")).to eq "Cx"
    end

    # Unicode glyphs are unambiguous, so this direction is not letter-anchored.
    # Downstream consumers feed it scale degrees and roman numerals.
    it "converts a flat that is not attached to a letter name" do
      expect(described_class.to_ascii("♭VI")).to eq "bVI"
    end

    it "converts a flat scale degree" do
      expect(described_class.to_ascii("♭7")).to eq "b7"
    end

    it "leaves a natural sign in place rather than dropping information" do
      expect(described_class.to_ascii("C♮")).to eq "C♮"
    end

    it "is idempotent" do
      expect(described_class.to_ascii("Bb")).to eq "Bb"
    end

    it "round-trips a double sharp to the normalized ASCII spelling" do
      expect(described_class.to_ascii(described_class.to_unicode("C##"))).to eq "Cx"
    end
  end

  describe "round-tripping every spelling" do
    let(:ascii_spellings) do
      HeadMusic::Rudiment::LetterName::NAMES.flat_map do |letter_name|
        ["", "b", "bb", "#", "x"].map { |sign| "#{letter_name}#{sign}" }
      end
    end

    it "reparses to the identical spelling" do
      round_tripped = ascii_spellings.map do |ascii|
        HeadMusic::Rudiment::Spelling.get(described_class.to_ascii(described_class.to_unicode(ascii)))
      end

      expect(round_tripped).to eq ascii_spellings.map { |ascii| HeadMusic::Rudiment::Spelling.get(ascii) }
    end
  end

  # The chord-quality allowlist was chosen by measuring candidates against a real word
  # list rather than by intuition, and each entry clears a genuine English word by a
  # single letter — "sus" vs "Absurd", "dim" vs "Abdomen" and "Abdicate". This pins the
  # result of that measurement so that adding an entry to CHORD_QUALITIES cannot
  # quietly start converting prose.
  #
  # The fixture is every capitalized word in a full English word list whose second
  # character could begin an accidental, which is exactly the set the guards protect.
  # It is vendored rather than read from /usr/share/dict/words so that the check is
  # deterministic and actually runs on CI, which has no such file.
  describe "false positives across english prose" do
    let(:at_risk_words) do
      path = File.expand_path("../../support/fixtures/prose_words_at_risk.txt", __dir__)
      File.readlines(path, chomp: true).reject(&:empty?)
    end

    it "leaves all but the genuinely ambiguous words alone" do
      converted = at_risk_words.reject { |word| described_class.to_unicode(word) == word }
      expect(converted).to contain_exactly("Ab", "Abb", "Abmho", "Ax", "Ebb", "Ebbman", "Ex")
    end

    it "covers a meaningful sample rather than a token one" do
      expect(at_risk_words.size).to be > 2000
    end
  end

  # The maps are derived from Alteration rather than hard-coded, so these guard the
  # derivation rather than restating it. In particular #ascii reads the first symbol
  # record, so reordering the double_sharp records in alterations.yml would make
  # to_ascii emit "##" — which Pitch.get accepts but ABC's accidental table does not.
  describe "derived maps" do
    it "keys the ASCII map on the primary spelling of each alteration" do
      expect(described_class.ascii_for["𝄪"]).to eq "x"
    end

    it "includes both ASCII spellings of a double sharp" do
      expect(described_class.unicode_for).to include("x" => "𝄪", "##" => "𝄪")
    end
  end
end
