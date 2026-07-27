# A namespace for utilities classes and modules
module HeadMusic::Utilities; end

# Util for converting an object to a consistent hash key
class HeadMusic::Utilities::HashKey
  def self.for(identifier)
    @hash_keys ||= {}
    @hash_keys[identifier] ||= new(identifier).to_sym
  end

  attr_reader :original

  def initialize(identifier)
    @original = identifier
  end

  def to_sym
    normalized_string.to_sym
  end

  private

  def normalized_string
    @normalized_string ||=
      HeadMusic::Utilities::Case.to_snake_case(transliterated_string)
  end

  def transliterated_string
    I18n.transliterate(desymbolized_string)
  end

  # Doubles come before singles: the single-sharp rule would otherwise consume the
  # first character of an ASCII "##" and leave a stray "#" behind. ASCII "b" is
  # deliberately absent — mapping it would mangle every key containing the letter,
  # such as :blues_major_pentatonic and :bass_clarinet.
  def desymbolized_string
    original.to_s
      .gsub("𝄫", "_double_flat")
      .gsub("𝄪", "_double_sharp")
      .gsub("##", "_double_sharp")
      .gsub("♭", "_flat")
      .gsub("♮", "_natural")
      .gsub("♯", "_sharp")
      .gsub("#", "_sharp")
  end
end
