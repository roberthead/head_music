# A module for musical instruments and their properties
module HeadMusic::Instruments; end

# Finds an instrument's catalog record by key, localized name, or alias.
# Wraps the instruments.yml data (a Hash of name_key => record) so an
# Instrument need not know how a raw record is located, only how to build
# itself from one.
class HeadMusic::Instruments::InstrumentCatalog
  include HeadMusic::Instruments::CatalogLookup

  def initialize(records)
    @records = records
  end

  # The record matching a name given as a key, a localized (translated) name,
  # or an alias, with its own name_key merged in; nil when nothing matches.
  def record_for(name)
    record_for_key(HeadMusic::Utilities::HashKey.for(name)) ||
      record_for_key(key_for_name(name)) ||
      record_for_alias(name)
  end

  private

  attr_reader :records

  # CatalogLookup hook: the hash its #key_for_name searches by translation.
  def catalog
    records
  end

  def record_for_key(key)
    records.each do |name_key, data|
      return data.merge("name_key" => name_key) if name_key.to_s == key.to_s
    end
    nil
  end

  def record_for_alias(name)
    normalized_name = HeadMusic::Utilities::HashKey.for(name).to_s
    records.each do |name_key, data|
      data["alias_name_keys"]&.each do |alias_key|
        return data.merge("name_key" => name_key) if HeadMusic::Utilities::HashKey.for(alias_key).to_s == normalized_name
      end
    end
    nil
  end
end
