class FlowContext
  attr_reader :flow, :source, :expected_messages

  delegate :cantus_firmus_voice, to: :flow
  delegate :counterpoint_voice, to: :flow
  delegate :pitches, to: :cantus_firmus_voice, prefix: :cantus_firmus
  delegate :pitches, to: :counterpoint_voice, prefix: :counterpoint

  def self.from_cantus_firmus_params(params)
    from_params(params.merge(cantus_firmus_pitches: params[:pitches], cantus_firmus_durations: params[:durations]))
  end

  def self.from_params(params)
    flow = HeadMusic::Content::Flow.new(
      name: name_from_params(params),
      key_signature: HeadMusic::Rudiment::KeySignature.get(params[:key])
    )
    add_voices(flow, params)
    expected_messages = params[:expected_messages] || [params[:expected_message]].compact
    new(flow: flow, source: params[:source], expected_messages: expected_messages)
  end

  def self.add_voices(flow, params)
    cantus_firmus = flow.add_voice(role: "cantus firmus")
    add_pitches_to_voice(cantus_firmus, params[:cantus_firmus_pitches], params[:cantus_firmus_durations])
    counterpoint = flow.add_voice(role: "counterpoint")
    add_pitches_to_voice(counterpoint, params[:counterpoint_pitches], params[:counterpoint_durations])
  end

  def self.name_from_params(params)
    params[:name] || [params[:source], params[:key]].compact.join(" ") || "Composition"
  end

  def self.add_pitches_to_voice(voice, pitches_string, durations = nil)
    pitches = pitches_from_string(pitches_string)
    durations = [durations].flatten.compact
    pitches.each.with_index(1) do |pitch, bar|
      voice.place("#{bar}:1", durations[bar - 1] || durations.first || "whole", pitch)
    end
  end

  def self.pitches_from_string(pitches_string)
    [pitches_string].flatten.map { |pitch| HeadMusic::Rudiment::Pitch.from_name(pitch) }
  end

  def initialize(flow:, source: nil, expected_messages: [])
    @flow = flow
    @source = source
    @expected_messages = expected_messages
  end

  def key
    flow.key_signature
  end

  def description
    @description ||= [source, key, pitches_description].compact.reject do |element|
      element.to_s.strip.empty?
    end.join(" ")
  end

  def pitches_description
    @pitches_description ||=
      [counterpoint_string, cantus_firmus_string].map(&:to_s).reject(&:empty?).join(" against ")
  end

  def method_missing(method_name, *args, &block)
    respond_to_missing?(method_name) ? flow.send(method_name, *args, &block) : super
  end

  def respond_to_missing?(method_name, *_args)
    flow.respond_to?(method_name)
  end

  private

  def cantus_firmus_string
    "#{cantus_firmus_pitches.join(" ")} (CF)" if cantus_firmus_pitches&.any?
  end

  def counterpoint_string
    "#{counterpoint_pitches.join(" ")} (CPT)" if counterpoint_pitches&.any?
  end
end
