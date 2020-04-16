# frozen_string_literal: true

# A scale degree is a number indicating the ordinality of the spelling in the key signature.
# TODO: Rewrite to accept a tonal_center and a scale type.
class HeadMusic::Solmization
  include HeadMusic::Named

  DEFAULT_SOLMIZATION = 'solfège'

  RECORDS = YAML.load_file(File.expand_path('solmizations.yml', __dir__)).freeze

  def self.get(identifier = nil)
    puts "Solmization.get(#{identifier})"
    get_by_name(identifier)
  end

  def initialize(identifier)
    self.name = identifier.empty? ? DEFAULT_SOLMIZATION : identifier.to_s
  end
end
