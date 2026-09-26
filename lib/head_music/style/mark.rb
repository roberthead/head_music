# A mark is a fragment of music with an optional fitness score assigned.
# Marks are collected by a guideline, which comments on a voice.
class HeadMusic::Style::Mark
  attr_reader :start_position, :end_position, :voice_events, :fitness

  def self.for(voice_event, fitness: nil)
    new(voice_event.position, voice_event.next_position, voice_events: [voice_event], fitness: fitness)
  end

  def self.for_all(voice_events, fitness: nil)
    voice_events = [voice_events].flatten.compact
    return [] if voice_events.empty?

    start_position = voice_events.map(&:position).min
    end_position = voice_events.map(&:next_position).max
    new(start_position, end_position, voice_events: voice_events, fitness: fitness)
  end

  def self.for_each(voice_events, fitness: nil)
    voice_events = [voice_events].flatten
    voice_events.map do |voice_event|
      new(voice_event.position, voice_event.next_position, voice_events: voice_event, fitness: fitness)
    end
  end

  def initialize(start_position, end_position, voice_events: [], fitness: nil)
    @start_position = start_position
    @end_position = end_position
    @voice_events = [voice_events].flatten.compact
    @fitness = fitness || HeadMusic::PENALTY_FACTOR
  end

  def code
    [start_position, end_position].join(" to ")
  end
  alias_method :to_s, :code
end
