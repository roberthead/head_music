# A namespace for utilities classes and modules
module HeadMusic::Utilities; end

# Util for converting an object to a consistent hash key
class HeadMusic::Utilities::HashKey
  # Keyed on the identifier as given, so a symbol and its string spelling occupy
  # separate entries for the same result. Never evicted: the gem's identifiers come
  # from finite catalogs, so the vocabulary is bounded. A caller generating
  # identifiers dynamically would grow this without limit.
  def self.for(identifier)
    @hash_keys ||= {}
    @hash_keys[identifier] ||=
      HeadMusic::Utilities::Case.to_snake_case(
        I18n.transliterate(desymbolized_string(identifier))
      ).to_sym
  end

  # Accidentals become word suffixes, so that "C♯" and "C sharp" reach the same key.
  #
  # ASCII spellings are normalized to their unicode glyphs first rather than mapped
  # here. Mapping ASCII "b" directly is what a naive implementation gets wrong — it
  # turns :bass_clarinet into :b_flatass_clarinet — and avoiding that by handling
  # ASCII "#" but not ASCII "b" left the two sides asymmetric, with "C#" keying to
  # :c_sharp while "Bb" keyed to :bb. Accidentals.to_unicode is prose-safe, so it
  # closes that gap without the mangling.
  #
  # The two ASCII sharp rules that follow are a fallback, not a second inventory. They
  # catch a "#" that Accidentals.to_unicode leaves alone because it is not attached to
  # a letter name, and they are safe to apply bare because "#" cannot occur in a word —
  # which is exactly why the corresponding ASCII flat rules must not exist here.
  # Doubles first: the single rule would otherwise consume the first "#" of a "##".
  def self.desymbolized_string(identifier)
    normalized = HeadMusic::Utilities::Accidentals.to_unicode(identifier)
    word_suffixes
      .reduce(normalized) { |string, (glyph, suffix)| string.gsub(glyph, suffix) }
      .gsub("##", "_double_sharp")
      .gsub("#", "_sharp")
  end
  private_class_method :desymbolized_string

  # Derived from Alteration so that alterations.yml stays the only place the glyph
  # inventory lives. Each alteration's identifier is already the word form a key wants
  # (:double_sharp -> "_double_sharp"). Every unicode glyph is a single character, so
  # unlike the ASCII spellings they need no longest-first ordering.
  #
  # Resolved lazily, and it must stay that way: Alteration includes Named, whose
  # .get_by_name calls back into HashKey. Nothing on Alteration's initialization path
  # reaches that method today, which is what keeps the cycle from closing — so if
  # Named ever starts building a hash key while constructing an object, this memo
  # would recurse through a half-built Alteration.all.
  def self.word_suffixes
    @word_suffixes ||=
      HeadMusic::Rudiment::Alteration.all.to_h { |alteration| [alteration.unicode, "_#{alteration.identifier}"] }
  end
  private_class_method :word_suffixes
end
