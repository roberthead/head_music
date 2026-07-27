# A namespace for utilities classes and modules
module HeadMusic::Utilities; end

# Util for converting accidentals in a string between ASCII spellings and canonical
# unicode glyphs.
#
# Safe to run over prose. Conversion happens only inside a candidate chord token — an
# uppercase letter name that does not continue a longer word or number — so "Above",
# "Bebop", "1.0b2", and "0x1B2F" are untouched while "Bb", "Ab7", "Bbm", and
# "Bbmaj7#11" convert.
#
# Deliberately narrower than the gem's parsers in two ways, both of which follow from
# being safe over prose:
#
# 1. Case-sensitive. Spelling and Pitch accept a lowercase letter name; this does not,
#    because a case-insensitive rule reads the "B" of "B7" as a flat sign and every
#    lowercase word in a sentence becomes a candidate. So to_unicode("eb") is "eb"
#    while Spelling.get("eb") is "E♭".
# 2. A bare accidental token is read as an accidental, not as a pitch name. to_unicode
#    ("bb") is "𝄫" — the double-flat sign — while Spelling.get("bb") is "B♭". Callers
#    holding a pitch name that may be lowercase should parse it with Spelling first.
#
# The maps are derived from Alteration lazily rather than at load time. Eager
# derivation is not an option anywhere in the load sequence: Alteration.all
# instantiates Notation::MusicalSymbol, which is not required until much later in
# head_music.rb.
class HeadMusic::Utilities::Accidentals
  # Chord qualities that may follow a flat without a word boundary, so that "Bbm" and
  # "Ebmaj7" convert while "Above" does not. "m" subsumes "maj", "min", and "m7";
  # uppercase forms like "BbM7" already clear the (?![a-z]) guard unaided.
  #
  # Measured against /usr/share/dict/words: this list costs exactly two false
  # positives ("Abmho", "Ebbman") across 235,976 capitalized words. Each entry clears
  # a real word by one letter — "sus" vs "Absurd", "dim" vs "Abdomen" and "Abdicate" —
  # so any addition here needs re-measuring rather than eyeballing.
  CHORD_QUALITIES = %w[m dim aug sus].freeze

  # The scale degrees a chord extension can alter. Requiring the altered degree to be
  # one of these is what separates "C7b9" from "Figure C2b3": both are an accidental
  # flanked by digits inside a token that opens with a letter name, and only the
  # degree tells them apart.
  EXTENSION_DEGREES = %w[13 11 9 6 5 4].freeze

  # A candidate chord symbol. One quantifier over a character class, so there is no
  # nesting and no ReDoS surface. This is what scopes the altered-extension rule
  # below: "1.0b2" and "0x1B2F" never open a token, so they can never reach it.
  CHORD_TOKEN = /(?<![A-Za-z0-9])[A-G][A-Za-z0-9#]*/

  # "Bb" => "B♭", "C##" => "C𝄪", "Cx" => "C𝄪", "Bbmaj7#11" => "B♭maj7♯11".
  # Idempotent, and all-or-nothing per accidental: a double never half-converts.
  def self.to_unicode(text)
    string = text.to_s
    return unicode_for.fetch(string) if unicode_for.key?(string)

    string.gsub(CHORD_TOKEN) do |token|
      token.gsub(ascii_matcher) { |match| unicode_for.fetch(match) }
    end
  end

  # "B♭" => "Bb", "C𝄪" => "Cx". Emits the spellings the gem's own parsers accept,
  # so "x" rather than "##" for a double sharp.
  #
  # Deliberately not letter-anchored: unicode glyphs are unambiguous, and consumers
  # feed this scale degrees and roman numerals ("♭7", "♭VI") that have no letter name.
  # A natural sign is left as "♮" — mapping it to "" would turn the valid spelling
  # "C♮" into the different spelling "C". Idempotent.
  def self.to_ascii(text)
    text.to_s.gsub(unicode_matcher) { |match| ascii_for.fetch(match) }
  end

  def self.unicode_for
    @unicode_for ||=
      altering_alterations.flat_map(&:musical_symbols)
        .reject { |symbol| symbol.ascii.to_s.empty? }
        .to_h { |symbol| [symbol.ascii, symbol.unicode] }
  end

  # One entry per alteration, keyed on its primary #ascii, so "##" is never emitted.
  def self.ascii_for
    @ascii_for ||= altering_alterations.to_h { |alteration| [alteration.unicode, alteration.ascii] }
  end

  # Applied only inside a CHORD_TOKEN. No /i flag — case-insensitivity would read the
  # "B" of "B7" as a flat sign.
  #
  # Two anchor contexts. The first is the pitch name's own accidental, anchored to the
  # letter name, with a per-family guard: "#" cannot occur in an English word at all,
  # "b" can but is rescued by CHORD_QUALITIES, and "x" takes the bare guard because an
  # allowlist there would buy "Cxm7" and cost "Axminster" and "Exmoor". The second is
  # an altered extension ("7#11", "7b9"), which has no letter to anchor to and is
  # instead flanked by digits. Being inside a CHORD_TOKEN is not sufficient on its own
  # — "Figure C2b3" would qualify — so the altered degree must also be a real chord
  # extension.
  def self.ascii_matcher
    @ascii_matcher ||=
      /(?<=[A-G])(?:#{sharp_branch}|#{flat_branch}|#{double_sharp_branch})|#{extension_branch}/
  end

  def self.unicode_matcher
    @unicode_matcher ||= Regexp.union(ascii_for.keys)
  end
  private_class_method :ascii_matcher, :unicode_matcher

  def self.sharp_branch
    longest_first(spellings_matching(/#/))
  end

  def self.flat_branch
    "(?:#{longest_first(spellings_matching(/b/))})(?:(?![a-z])|(?=#{longest_first(CHORD_QUALITIES)}))"
  end

  def self.double_sharp_branch
    "(?:#{longest_first(spellings_matching(/x/))})(?![a-z])"
  end

  def self.extension_branch
    "(?<=\\d)(?:#{longest_first(spellings_matching(/[#b]/))})(?=(?:#{longest_first(EXTENSION_DEGREES)})(?![0-9]))"
  end

  def self.spellings_matching(pattern)
    unicode_for.keys.grep(pattern)
  end

  # Regexp.union alternates in array order rather than by longest match, so every
  # two-character spelling must precede its one-character prefix or a double
  # half-converts.
  def self.longest_first(spellings)
    Regexp.union(spellings.sort_by { |spelling| -spelling.length }).source
  end

  def self.altering_alterations
    HeadMusic::Rudiment::Alteration.all.reject(&:natural?)
  end

  private_class_method :sharp_branch, :flat_branch, :double_sharp_branch,
    :extension_branch, :spellings_matching, :longest_first, :altering_alterations
end
