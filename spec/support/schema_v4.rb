# Turns a schema-5 flow hash back into the schema-4 shape, for building the
# documents a 22.x release wrote.
module SchemaV4
  def self.flow_hash(flow_hash)
    flow_hash.merge("schema_version" => 4, "parts" => flow_hash["parts"].map do |part_hash|
      part_hash.merge("voices" => part_hash["voices"].map do |voice_hash|
        voice_hash.except("voice_events").merge("placements" => voice_hash["voice_events"])
      end)
    end)
  end
end
