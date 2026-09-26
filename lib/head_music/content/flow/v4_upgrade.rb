class HeadMusic::Content::Flow
  # Schema 5 renamed each voice's "placements" to "voice_events" and changed
  # nothing else, so a schema-4 document is upgraded by renaming the key.
  # Kept through 23.x so persisted documents can be read and saved again.
  module V4Upgrade
    VERSION = 4

    module_function

    def flow(hash)
      upgraded(hash) { |document| upgrade_flow(document) }
    end

    # Each flow in a project carries its own version. One that is not v4 is
    # left for Flow.from_h to refuse.
    def project(hash)
      upgraded(hash) do |document|
        document.merge("flows" => Array(document["flows"]).map do |flow_hash|
          next flow_hash unless flow_hash["schema_version"] == VERSION

          upgrade_flow(flow_hash).merge("schema_version" => HeadMusic::Content::Flow::SCHEMA_VERSION)
        end)
      end
    end

    def upgraded(hash)
      raise ArgumentError, "expected a Hash, got #{hash.class}" unless hash.is_a?(Hash)

      document = hash.deep_transform_keys(&:to_s)
      version = document["schema_version"]
      raise ArgumentError, "expected schema_version 4, got #{version.inspect}" unless version == VERSION

      yield(document).merge("schema_version" => HeadMusic::Content::Flow::SCHEMA_VERSION)
    end

    def upgrade_flow(flow_hash)
      flow_hash.merge("parts" => Array(flow_hash["parts"]).map do |part_hash|
        part_hash.merge("voices" => Array(part_hash["voices"]).map do |voice_hash|
          voice_hash.except("placements").merge("voice_events" => voice_hash["placements"])
        end)
      end)
    end

    private_class_method :upgraded, :upgrade_flow
  end
end
