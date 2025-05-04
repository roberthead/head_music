# A module for musical content
module HeadMusic::Content; end

# Representation of a bar in a composition
# Encapsulates meter and key signature changes
class HeadMusic::Content::Bar
  attr_reader :composition
  attr_accessor :key_signature, :meter

  def initialize(composition, key_signature: nil, meter: nil)
    @composition = composition
    @key_signature = HeadMusic::Rudiment::KeySignature.get(key_signature) if key_signature
    @meter = HeadMusic::Rudiment::Meter.get(meter) if meter
  end

  def to_s
    ["Bar", key_signature, meter].compact.join(" ")
  end
end
