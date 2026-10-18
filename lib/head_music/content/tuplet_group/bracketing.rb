# A module for musical content
module HeadMusic::Content; end

# The links of a voice that a tuplet bracket from one position up to another
# holds, and their ratio. Bracketing refuses a span whose links do not make
# exactly one tuplet.
class HeadMusic::Content::TupletGroup::Bracketing
  attr_reader :ratio, :links

  # The links inside a bracket already made.
  def self.links_inside(voice, from, to)
    HeadMusic::Content::ChainLink.between(voice, from, to).drop_while { |link| !link.starts_at?(from) }
      .take_while { |link| link.voice_event.position < to && !link.starts_at?(to) }
  end

  def initialize(voice, from, to)
    @from = from
    @to = to
    @links = bracketed_links(HeadMusic::Content::ChainLink.between(voice, from, to))
    ensure_one_ratio
    freeze
  end

  private

  def label
    HeadMusic::Content::TupletGroup.label(ratio, @from, @to)
  end

  def bracketed_links(candidates)
    first = candidates.index { |link| link.starts_at?(@from) }
    ensure_start(candidates) unless first

    @ratio = candidates[first].ratio
    ensure_consecutive(candidates)
    last = candidates.index { |link| link.ends_at?(@to) }
    raise ArgumentError, "the #{label} must end where a note, rest, or tied link ends, filling its span exactly" unless last

    candidates[first..last]
  end

  def ensure_start(candidates)
    sounding = candidates.find { |link| link.covers?(@from) }
    @ratio = sounding&.ratio
    message = "the #{label} must start where a note, rest, or tied link starts"
    if sounding&.rounds?
      message += ", but it falls inside the #{sounding.rhythmic_value} at #{sounding.voice_event.position}, " \
        "in a run of values rounded to the nearest subtick"
    end
    raise ArgumentError, message
  end

  def ensure_consecutive(candidates)
    candidates.map(&:voice_event).uniq.each_cons(2) do |previous, current|
      next if previous.next_position == current.position

      raise ArgumentError, "the #{label} must hold consecutive notes and rests, but none starts at #{previous.next_position}"
    end
  end

  def ensure_one_ratio
    stray = links.find { |link| link.ratio.nil? || link.ratio != ratio }
    if stray
      raise ArgumentError, "the #{label} must hold values of one tuplet ratio, " \
        "but the #{stray.rhythmic_value} at #{stray.voice_event.position} #{stray.ratio ? "is not #{ratio.to_a.join(":")}" : "has none"}"
    end
    ensure_event_boundaries if links.any?(&:rounds?)
  end

  # A ratio that rounds has its onsets measured from where its group starts,
  # so the group must start and end where voice events do.
  def ensure_event_boundaries
    return if links.first.first && links.last.last

    raise ArgumentError, "the #{label} must start and end where notes or rests do, since its ratio does not land on whole subticks"
  end
end
