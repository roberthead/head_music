# Representation of a bar in a composition
# Encapsulates meter and key signature changes
class HeadMusic::Bar
  attr_reader :composition
  attr_accessor :key_signature, :meter

  def initialize(composition, key_signature: nil, meter: nil)
    @composition = composition
    @key_signature = HeadMusic::KeySignature.get(key_signature) if key_signature
    @meter = HeadMusic::Meter.get(meter) if meter
  end

  def to_s
    ['Bar', key_signature, meter].reject(&:nil?).join(' ')
  end
end
