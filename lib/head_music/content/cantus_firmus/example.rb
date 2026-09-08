module HeadMusic
  module Content
    module CantusFirmus
      # Sample cantus firmus examples from various pedagogical sources.
      class Example
        EXAMPLES_DATA = YAML.load_file(File.expand_path("examples.yml", __dir__)).freeze

        attr_reader :slug, :source, :tonal_center, :mode, :pitches

        class << self
          def all
            @all ||= EXAMPLES_DATA["cantus_firmus_examples"].map do |data|
              new(data: data)
            end
          end

          def find_by_slug(slug)
            all.find { |example| example.slug == slug.to_s }
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
          @slug = data["slug"]
          @source = Source.get(data["source"])
          @tonal_center = data["tonal_center"]
          @mode = data["mode"]&.to_sym
          @pitches = data["pitches"] || []
        end

        def length
          pitches.length
        end

        # An example is a catalog datum -- a pitch list with a mode and a
        # citation -- not content, so rhythm and meter are the realization's
        # choice rather than the datum's, and are parameters.
        def to_flow(rhythmic_value: :whole, meter: "4/4")
          flow = HeadMusic::Content::Flow.new(name: to_s, key_signature: key_signature_name, meter: meter)
          flow.source = source
          voice = flow.add_voice(role: "cantus firmus")
          pitches.each_with_index { |pitch, index| voice.place("#{index + 1}:1", rhythmic_value, pitch) }
          flow
        end

        # The mode named on its own tonal center, which KeySignature reads as a
        # collection while retaining the scale type.
        def key_signature_name
          [tonal_center, mode].compact.join(" ")
        end

        def to_s
          "#{tonal_center} #{mode} (#{source})"
        end

        private_class_method :new
      end
    end
  end
end
