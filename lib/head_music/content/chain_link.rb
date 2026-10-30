# A module for musical content
module HeadMusic::Content; end

# One link of a voice event's tied chain, with its exact onset and end in
# subticks from the event's position.
HeadMusic::Content::ChainLink = Data.define(:voice_event, :rhythmic_value, :onset, :finish, :first, :last) do
  def self.of(voice_event)
    chain = voice_event.rhythmic_duration.values
    onset = voice_event.onset_remainder
    chain.each_with_index.map do |link, index|
      finish = onset + link.link_fraction * HeadMusic::Rudiment::Rhythm::SUBTICKS_PER_WHOLE
      new(voice_event, link, onset, finish, index.zero?, index == chain.length - 1).tap { onset = finish }
    end
  end

  # The links of the voice events that sound from one position up to another.
  # Searched by where events start, so that only the event before from is
  # asked where it ends.
  def self.between(voice, from, to)
    events = voice.voice_events
    start = events.bsearch_index { |voice_event| voice_event.position > from } || events.length
    start -= 1 if start.positive? && events[start - 1].next_position > from
    events[start..].take_while { |voice_event| voice_event.position < to }.flat_map { |voice_event| of(voice_event) }
  end

  def ratio
    rhythmic_value.tuplet_ratio
  end

  # A voice event's own start and end are its rounded positions, which is
  # where a group inside a run of a rounding ratio begins and ends.
  def starts_at?(position)
    first ? voice_event.position == position : lands_on?(onset, position)
  end

  def ends_at?(position)
    last ? voice_event.next_position == position : lands_on?(finish, position)
  end

  def covers?(position)
    start_position <= position && position < offset_position(finish.round)
  end

  # Where the link starts and ends, rounded as positions are, so that a
  # group may start or end on a later link of a tied chain.
  def start_position
    first ? voice_event.position : offset_position(onset.round)
  end

  def end_position
    last ? voice_event.next_position : offset_position(finish.round)
  end

  def rounds?
    (finish - onset).denominator != 1
  end

  private

  def lands_on?(offset, position)
    offset.denominator == 1 && offset_position(offset.to_i) == position
  end

  def offset_position(subticks)
    voice_event.position.advance(subticks: subticks)
  end
end
