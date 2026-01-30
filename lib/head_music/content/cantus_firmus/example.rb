module HeadMusic
  module Content
    module CantusFirmus
      # Sample cantus firmus examples from various pedagogical sources.
      # These are traditional melodies used for teaching counterpoint.
      class Example
        EXAMPLES_DATA = YAML.load_file(File.expand_path("examples.yml", __dir__)).freeze

        attr_reader :source, :tonal_center, :mode, :pitches

        class << self
          def all
            @all ||= EXAMPLES_DATA["cantus_firmus_examples"].map do |data|
              new(data: data)
            end
          end

          def by_source(source_identifier)
            source = Source.get(source_identifier)
            return [] unless source

            all.select { |example| example.source == source }
          end

          def sources
            all.map(&:source).uniq
          end

          def by_mode(mode_name)
            normalized_mode = mode_name.to_s.downcase
            all.select { |example| example.mode.to_s.downcase == normalized_mode }
          end

          def by_tonal_center(tonal_center_name)
            all.select { |example| example.tonal_center.to_s == tonal_center_name.to_s }
          end
        end

        def initialize(data:)
          @source = Source.get(data["source"])
          @tonal_center = data["tonal_center"]
          @mode = data["mode"]&.to_sym
          @pitches = data["pitches"] || []
        end

        def length
          pitches.length
        end

        def to_s
          "#{tonal_center} #{mode} (#{source})"
        end

        private_class_method :new
      end
    end
  end
end
