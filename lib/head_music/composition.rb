class HeadMusic::Composition
  attr_reader :name, :key_signature, :meter, :bars, :voices

  def initialize(name:, key_signature: nil, meter: nil)
    ensure_attributes(name, key_signature, meter)
    add_bar
    add_voice
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

  def add_voice
    @voices ||= []
    @voices << HeadMusic::Voice.new(composition: self)
  end

  private

  def ensure_attributes(name, key_signature, meter)
    @name = name
    @key_signature = HeadMusic::KeySignature.get(key_signature) if key_signature
    @key_signature ||= HeadMusic::KeySignature.default
    @meter = HeadMusic::Meter.get(meter) if meter
    @meter ||= HeadMusic::Meter.default
  end
end
