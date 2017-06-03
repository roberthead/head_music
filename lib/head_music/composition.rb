class HeadMusic::Composition
  attr_reader :name, :key_signature, :meter, :bars, :voices

  def initialize(name: nil, key_signature: nil, meter: nil)
    ensure_attributes(name, key_signature, meter)
    @voices = []
  end

  def add_bar
    add_bars(1)
  end

  def add_bars(number)
    @bars ||= []
    number.times do
      @bars << HeadMusic::Bar.new(self)
    end
  end

  def add_voice(role: nil)
    @voices << HeadMusic::Voice.new(composition: self, role: role)
    @voices.last
  end

  private

  def ensure_attributes(name, key_signature, meter)
    @name = name || 'Composition'
    @key_signature = HeadMusic::KeySignature.get(key_signature) if key_signature
    @key_signature ||= HeadMusic::KeySignature.default
    @meter = HeadMusic::Meter.get(meter) if meter
    @meter ||= HeadMusic::Meter.default
  end
end
