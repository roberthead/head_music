# frozen_string_literal: true

class CompositionContext
  attr_reader :composition, :source, :expected_messages

  delegate :pitches, to: :cantus_firmus_voice, prefix: :cantus_firmus
  delegate :pitches, to: :counterpoint_voice, prefix: :counterpoint

  def self.from_cantus_firmus_params(params)
    from_params(params.merge(cantus_firmus_pitches: params[:pitches], cantus_firmus_durations: params[:durations]))
  end

  def self.from_params(params)
    composition = Composition.new(name: name_from_params(params), key_signature: KeySignature.get(params[:key]))
    cantus_firmus = composition.add_voice(role: 'cantus firmus')
    add_pitches_to_voice(cantus_firmus, params[:cantus_firmus_pitches], params[:cantus_firmus_durations])
    counterpoint = composition.add_voice(role: 'counterpoint')
    add_pitches_to_voice(counterpoint, params[:counterpoint_pitches], params[:counterpoint_durations])
    expected_messages = params[:expected_messages] || [params[:expected_message]].compact
    new(composition: composition, source: params[:source], expected_messages: expected_messages)
  end

  def self.name_from_params(params)
    @name ||= params[:name] || [params[:source], params[:key]].compact.join(' ') || 'Composition'
  end

  def self.add_pitches_to_voice(voice, pitches_string, durations = nil)
    pitches = pitches_from_string(pitches_string)
    durations = [durations].flatten.compact
    pitches.each.with_index(1) do |pitch, bar|
      voice.place("#{bar}:1", durations[bar - 1] || durations.first || 'whole', pitch)
    end
  end

  def self.pitches_from_string(pitches_string)
    [pitches_string].flatten.map { |pitch| Pitch.from_name(pitch) }
  end

  def initialize(composition:, source: nil, expected_messages: [])
    @composition = composition
    @source = source
    @expected_messages = expected_messages
  end

  def key
    composition.key_signature
  end

  def description
    @description ||= begin
      [source, key, pitches_description].compact.reject do |element|
        element.to_s.strip.empty?
      end.join(' ')
    end
  end

  def pitches_description
    @pitches_description ||=
      [counterpoint_string, cantus_firmus_string].map(&:to_s).reject(&:empty?).join(' against ')
  end

  def method_missing(method_name, *args, &block)
    composition.send(method_name, *args, &block)
  end

  private

  def cantus_firmus_string
    cantus_firmus_pitches.join(' ') + ' (CF)' if cantus_firmus_pitches && !cantus_firmus_pitches.empty?
  end

  def counterpoint_string
    counterpoint_pitches.join(' ') + ' (CPT)' if counterpoint_pitches && !counterpoint_pitches.empty?
  end
end
