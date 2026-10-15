# A module for musical content
module HeadMusic::Content; end

# A tuplet group says which notes and rests of a voice one tuplet bracket
# holds, from one position up to an exclusive end. Its values carry the ratio
# already; the group tells two triplets from one sextuplet, and gives the
# written unit its bracket counts in. It brackets tied links rather than
# whole events, so a triplet whose last note is tied over the beat is one
# group.
#
# It holds positions rather than voice events, as a span does, because a note
# placed on a rest replaces the rest's object.
class HeadMusic::Content::TupletGroup
  include Comparable

  # One link of a voice event's tied chain, with its exact onset and end in
  # subticks from the event's position.
  Link = Data.define(:voice_event, :rhythmic_value, :onset, :finish, :first, :last) do
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
      voice_event.position.advance(subticks: onset.round) <= position &&
        position < voice_event.position.advance(subticks: finish.round)
    end

    def rounds?
      (finish - onset).denominator != 1
    end

    private

    def lands_on?(offset, position)
      offset.denominator == 1 && voice_event.position.advance(subticks: offset.to_i) == position
    end
  end

  attr_reader :voice, :from, :to, :unit, :ratio

  delegate :flow, to: :voice

  # The links of the voice events that sound from one position up to another.
  # Searched by where events start, so that only the event before from is
  # asked where it ends.
  def self.links_between(voice, from, to)
    events = voice.voice_events
    start = events.bsearch_index { |voice_event| voice_event.position > from } || events.length
    start -= 1 if start.positive? && events[start - 1].next_position > from
    events[start..].take_while { |voice_event| voice_event.position < to }.flat_map { |voice_event| links_of(voice_event) }
  end

  def self.links_of(voice_event)
    chain = voice_event.rhythmic_value.tied_chain
    onset = voice_event.onset_remainder
    chain.each_with_index.map do |link, index|
      finish = onset + link.link_fraction * HeadMusic::Rudiment::Rhythm::SUBTICKS_PER_WHOLE
      Link.new(voice_event, link, onset, finish, index.zero?, index == chain.length - 1).tap { onset = finish }
    end
  end

  # The written total over the ratio's actual count where that is one plain
  # or dotted value, as three triplet eighths count in eighths; otherwise the
  # largest value that divides every written fraction.
  def self.default_unit(written_fractions, ratio)
    single_value(written_fractions.sum / ratio.actual) ||
      single_value(written_fractions.reduce { |gcd, fraction| fraction_gcd(gcd, fraction) })
  end

  def self.single_value(fraction)
    value = HeadMusic::Notation::DottedDuration.rhythmic_value_for(fraction)
    value unless value.nil? || value.tied_value
  end

  def self.fraction_gcd(one, other)
    Rational(one.numerator.gcd(other.numerator), one.denominator.lcm(other.denominator))
  end
  private_class_method :single_value, :fraction_gcd

  def initialize(voice, from:, to:, unit: nil)
    @voice = voice
    @from = position_for(from)
    @to = position_for(to)
    raise ArgumentError, "the #{label} must end after it starts" unless @from < @to

    links = bracketed_links
    @unit = unit ? unit_for(unit) : default_unit(links)
    freeze
  end

  # The voice events with a link inside the group, in order.
  def voice_events
    links.map(&:voice_event).uniq
  end

  # The links inside the group, in order.
  def links
    self.class.links_between(voice, from, to).drop_while { |link| !link.starts_at?(from) }
      .take_while { |link| link.voice_event.position < to && !link.starts_at?(to) }
  end

  def covers?(position)
    from <= position && position < to
  end

  def overlaps?(other)
    from < other.to && other.from < to
  end

  # Ordered as spans are: by where a group starts, then ends.
  def <=>(other)
    return unless other.is_a?(self.class)

    [from, to] <=> [other.from, other.to]
  end

  def to_s
    label
  end

  def inspect
    "#<#{self.class.name} #{self}>"
  end

  def to_h
    {"from" => from.to_s, "to" => to.to_s, "unit" => unit.to_s}
  end

  private

  def label
    [ratio&.to_a&.join(":"), "tuplet from #{from} to #{to}"].compact.join(" ")
  end

  def bracketed_links
    links = self.class.links_between(voice, from, to)
    first = links.index { |link| link.starts_at?(from) }
    ensure_start(links) unless first

    @ratio = links[first].ratio
    ensure_consecutive(links)
    last = links.index { |link| link.ends_at?(to) }
    raise ArgumentError, "the #{label} must end where a note, rest, or tied link ends, filling its span exactly" unless last

    links[first..last].tap { |inside| ensure_one_ratio(inside) }
  end

  def ensure_start(links)
    sounding = links.find { |link| link.covers?(from) }
    @ratio = sounding&.ratio
    message = "the #{label} must start where a note, rest, or tied link starts"
    if sounding&.rounds?
      message += ", but it falls inside the #{sounding.rhythmic_value} at #{sounding.voice_event.position}, " \
        "in a run of values rounded to the nearest subtick"
    end
    raise ArgumentError, message
  end

  def ensure_consecutive(links)
    links.map(&:voice_event).uniq.each_cons(2) do |previous, current|
      next if previous.next_position == current.position

      raise ArgumentError, "the #{label} must hold consecutive notes and rests, but none starts at #{previous.next_position}"
    end
  end

  def ensure_one_ratio(links)
    ratio = links.first.ratio
    stray = links.find { |link| link.ratio.nil? || link.ratio != ratio }
    if stray
      raise ArgumentError, "the #{label} must hold values of one tuplet ratio, " \
        "but the #{stray.rhythmic_value} at #{stray.voice_event.position} #{stray.ratio ? "is not #{ratio.to_a.join(":")}" : "has none"}"
    end
    ensure_event_boundaries(links) if links.any?(&:rounds?)
  end

  # A ratio that rounds has its onsets measured from where its group starts,
  # so the group must start and end where voice events do.
  def ensure_event_boundaries(links)
    return if links.first.first && links.last.last

    raise ArgumentError, "the #{label} must start and end where notes or rests do, since its ratio does not land on whole subticks"
  end

  def default_unit(links)
    self.class.default_unit(links.map { |link| link.rhythmic_value.written_fraction }, ratio)
  end

  def unit_for(identifier)
    unit = HeadMusic::Rudiment::RhythmicValue.get(identifier)
    unless unit&.unit && !unit.tied_value && !unit.tuplet?
      raise ArgumentError, "the #{label} needs a plain or dotted value for its unit, not #{identifier.inspect}"
    end

    unit
  end

  def position_for(position)
    return HeadMusic::Content::Position.new(voice.flow, position) unless position.is_a?(HeadMusic::Content::Position)
    raise ArgumentError, "position belongs to a different flow" unless position.flow.equal?(voice.flow)

    position
  end
end
