# A namespace for utilities classes and modules
module HeadMusic::Utilities; end

# Util for converting an object to a particular case
class HeadMusic::Utilities::Case
  def self.to_snake_case(text)
    text.to_s
      .gsub("::", "/")
      .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
      .tr("-", "_")
      .tr(" ", "_")
      .gsub(/[^\w\/]+/, "_")
      .squeeze("_")
      .gsub(/^_|_$/, "")
      .downcase
  end

  def self.to_kebab_case(text)
    to_snake_case(text).tr("_", "-")
  end

  def self.to_camel_case(text)
    str = to_snake_case(text)
    str.split("_").map.with_index { |word, index| index.zero? ? word : word.capitalize }.join
  end
end
