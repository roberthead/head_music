module HeadMusic
  module Content
    module CantusFirmus
      # A pedagogical source of cantus firmus examples: a Publication with a
      # catalog key, the same noun any flow may cite.
      class Source < HeadMusic::Content::Publication
        SOURCES_DATA = YAML.load_file(File.expand_path("sources.yml", __dir__)).freeze

        attr_reader :key

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

          def normalize_key(identifier)
            identifier.to_s
              .downcase
              .gsub(/\s*&\s*/, "_and_")
              .gsub(/\s+/, "_")
              .to_sym
          end
        end

        # The key is assigned before the superclass freezes the object.
        def initialize(key:, data:)
          @key = key.to_sym
          super(
            title: data["publication_name"],
            edition: data["publication_edition"],
            abbreviation: data["abbreviation"],
            notes: data["notes"]&.strip,
            credits: author_credits(data["author_names"])
          )
        end

        alias_method :publication_name, :title
        alias_method :publication_edition, :edition
        alias_method :author_names, :authors

        def to_h
          super.merge("key" => key.to_s)
        end

        private_class_method :new

        private

        def author_credits(names)
          Array(names).map do |name|
            HeadMusic::Content::Credit.new(person: HeadMusic::Content::Person.new(full_name: name), role: :author)
          end
        end
      end
    end
  end
end
