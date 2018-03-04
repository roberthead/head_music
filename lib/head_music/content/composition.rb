# frozen_string_literal: true

# A composition is musical content.
class HeadMusic::Composition
  attr_reader :name, :key_signature, :meter, :voices

  def initialize(name: nil, key_signature: nil, meter: nil)
    ensure_attributes(name, key_signature, meter)
    @voices = []
  end

  def add_voice(role: nil)
    @voices << HeadMusic::Voice.new(composition: self, role: role)
    @voices.last
  end

  def meter_at(bar_number)
    meter_change = last_meter_change(bar_number)
    meter_change ? meter_change.meter : meter
  end

  def key_signature_at(bar_number)
    key_signature_change = last_key_signature_change(bar_number)
    key_signature_change ? key_signature_change.key_signature : key_signature
  end

  def bars(last = latest_bar_number)
    @bars ||= []
    (earliest_bar_number..last).each do |bar_number|
      @bars[bar_number] ||= HeadMusic::Bar.new(self)
    end
    @bars[earliest_bar_number..last]
  end

  def change_key_signature(bar_number, key_signature)
    bars(bar_number).last.key_signature = key_signature
  end

  def change_meter(bar_number, meter)
    bars(bar_number).last.meter = meter
  end

  def earliest_bar_number
    [voices.map(&:earliest_bar_number), 1].flatten.min
  end

  def latest_bar_number
    [voices.map(&:earliest_bar_number), 1].flatten.max
  end

  def cantus_firmus_voice
    voices.detect(&:cantus_firmus?)
  end

  def counterpoint_voice
    voices.reject(&:cantus_firmus?).first
  end

  def to_s
    "#{name} — #{voices.count} voice(s)"
  end

  private

  def ensure_attributes(name, key_signature, meter)
    @name = name || 'Composition'
    @key_signature = HeadMusic::KeySignature.get(key_signature) if key_signature
    @key_signature ||= HeadMusic::KeySignature.default
    @meter = HeadMusic::Meter.get(meter) if meter
    @meter ||= HeadMusic::Meter.default
  end

  def last_meter_change(bar_number)
    bars(bar_number)[earliest_bar_number..bar_number].reverse.detect(&:meter)
  end

  def last_key_signature_change(bar_number)
    bars(bar_number)[earliest_bar_number..bar_number].reverse.detect(&:key_signature)
  end
end
