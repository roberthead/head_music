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
      desymbolized_string.downcase.gsub(/\W+/, "_")
  end

  def desymbolized_string
    transliterated_string
      .gsub("𝄫", "_double_flat")
      .gsub("♭", "_flat")
      .gsub("♮", "_natural")
      .gsub("♯", "_sharp")
      .gsub("#", "_sharp")
      .gsub("𝄪", "_double_sharp")
  end

  def transliterated_string
    I18n.transliterate(original.to_s)
  end
end
