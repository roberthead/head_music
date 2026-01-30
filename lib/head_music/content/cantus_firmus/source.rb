module HeadMusic
  module Content
    module CantusFirmus
      # A pedagogical source of cantus firmus examples.
      # Sources include books and treatises on counterpoint.
      class Source
        SOURCES_DATA = YAML.load_file(File.expand_path("sources.yml", __dir__)).freeze

        attr_reader :key, :publication_name, :publication_edition, :author_names, :notes

        class << self
          def all
            @all ||= SOURCES_DATA["cantus_firmus_sources"].map do |key, data|
              new(key: key, data: data)
            end
          end

          def get(identifier)
            return identifier if identifier.is_a?(self)

            normalized_key = normalize_key(identifier)
            all.find { |source| source.key == normalized_key }
          end

          def keys
            all.map(&:key)
          end

          private

          # Normalize various source name formats to the YAML key format
          # e.g., "Fux" -> "fux", "Clendinning & Marvin" -> "clendinning_and_marvin"
          def normalize_key(identifier)
            identifier.to_s
                      .downcase
                      .gsub(/\s*&\s*/, "_and_")
                      .gsub(/\s+/, "_")
                      .to_sym
          end
        end

        def initialize(key:, data:)
          @key = key.to_sym
          @publication_name = data["publication_name"]
          @publication_edition = data["publication_edition"]
          @author_names = data["author_names"] || []
          @notes = data["notes"]&.strip
        end

        def to_s
          publication_name
        end

        private_class_method :new
      end
    end
  end
end
