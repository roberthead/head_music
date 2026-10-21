# A module for visual music notation
module HeadMusic::Notation; end

# The measure-level facts every Writer needs, whatever format it emits; a
# format's plan subclasses this and adds what only that format needs. Keys are
# per part, because a mixed ensemble has as many written keys as it has
# transpositions. Construction eagerly computes everything that can raise, so a
# plan that builds successfully cannot fail assembly on those grounds.
class HeadMusic::Notation::RenderPlan
  attr_reader :flow

  def initialize(flow, transposed: false)
    @flow = flow
    @transposed = transposed
    precompute_eager_data
  end

  def transposed?
    !!@transposed
  end

  def bar_numbers
    @bar_numbers ||= flow.earliest_bar_number..flow.last_sounding_bar_number
  end

  # A bar of the score, or nil outside it, where no bar is allocated for
  # asking.
  def bar(bar_number)
    flow.bar(bar_number) if bar_numbers.cover?(bar_number)
  end

  # The key changes to print in this part, by bar. A nil part answers the
  # sounding key, which is every part's key in a concert-pitch plan.
  def measure_key_changes(part = nil)
    keys_by_part[[:changes, part]] ||= build_measure_key_changes(part)
  end

  def measure_time_changes
    @measure_time_changes ||= flow.meter_changes.select { |bar_number, _| bar_numbers.cover?(bar_number) }
  end

  def first_measure_key(part = nil)
    keys_by_part[[:first, part]] ||= build_first_measure_key(part)
  end

  # The key in force in the part at a bar: its latest change there or
  # before, or else its first.
  def measure_key_at(bar_number, part = nil)
    changes = measure_key_changes(part)
    change_bar = changes.keys.select { |number| number <= bar_number }.max
    change_bar ? changes[change_bar] : first_measure_key(part)
  end

  def first_measure_meter
    @first_measure_meter ||= effective_meter(bar_numbers.first)
  end

  def effective_meter(bar_number)
    change_bar = measure_time_changes.keys.select { |number| number <= bar_number }.max
    change_bar ? measure_time_changes[change_bar] : flow.meter
  end

  # The flow's tempo marks are written in its first voice.
  def lead?(voice)
    voice.equal?(flow.voices.first)
  end

  # Where in the final bar every voice's music ends together, or nil where
  # it ends at the barline.
  def music_end_fraction
    return @music_end_fraction if defined?(@music_end_fraction)

    offset = music_end && HeadMusic::Notation::BarSplitter.offset_in_bar(music_end)
    @music_end_fraction = (offset && !offset.zero?) ? offset : nil
  end

  # The voice events marked with each fermata they sound under where it
  # begins.
  def fermata_carriers
    @fermata_carriers ||= HeadMusic::Notation::FermataMarks.carriers(flow)
  end

  # What each bar holds of the voice, with a voice event that crosses a barline
  # appearing in every bar it sounds in.
  def segments_by_bar(voice)
    @segments_by_bar ||= {}
    @segments_by_bar[voice] ||= HeadMusic::Notation::BarSplitter.segments(voice.voice_events).group_by(&:bar_number)
  end

  # Where the last voice's music ends.
  def music_end
    return @music_end if defined?(@music_end)

    @music_end = flow.voices.filter_map { |voice| voice.last_voice_event&.next_position }.max
  end

  private

  # A subclass computes here whatever else must raise at construction, and
  # calls super for the signatures every format needs.
  def precompute_eager_data
    first_measure_key
    first_measure_meter
    measure_key_changes
    measure_time_changes
    precompute_part_keys
  end

  # A written key that no signature can print must raise here rather than
  # midway through assembly, so every part's keys are computed up front.
  def precompute_part_keys
    return unless transposed?

    flow.parts.each do |part|
      first_measure_key(part)
      measure_key_changes(part)
    end
  end

  def keys_by_part
    @keys_by_part ||= {}
  end

  def build_first_measure_key(part)
    measure_key_changes(part)[bar_numbers.first] ||
      written_key_value(part, bar_numbers.first, flow.timeline.opening_key_signature_event)
  end

  def build_measure_key_changes(part)
    changes = flow.key_signature_changes
      .select { |bar_number, _| bar_numbers.cover?(bar_number) }
      .to_h { |bar_number, event| [bar_number, written_key_value(part, bar_number, event)] }
    changes.merge(instrument_change_keys(part))
  end

  # A part that changes instrument mid-flow changes written key with it, even
  # though the timeline holds no change there.
  def instrument_change_keys(part)
    return {} unless transposed? && part

    bars = part.instrument_changes.keys.select { |bar| bar_numbers.cover?(bar) && bar > bar_numbers.first }
    bars.filter_map { |bar|
      value = written_key_value(part, bar, effective_key_event(bar))
      [bar, value] unless value == written_key_value(part, bar - 1, effective_key_event(bar - 1))
    }.to_h
  end

  def effective_key_event(bar_number)
    change_bar = flow.key_signature_changes.keys.select { |number| number <= bar_number }.max
    change_bar ? flow.key_signature_changes[change_bar] : flow.timeline.opening_key_signature_event
  end

  # In a concert-pitch plan the event is mapped exactly as it always was.
  def written_key_value(part, bar_number, event)
    transposition = transposition_at(part, bar_number)
    key_value(transposition ? transposition.key_signature_event(event) : event)
  end

  def transposition_at(part, bar_number)
    return nil unless transposed? && part

    HeadMusic::Content::Layout::Transposition.for(part.instrument_at(bar_number))
  end

  # How the format renders a key signature event. The event rather than a key
  # signature, because MusicXML wants the signature and the interpretation as
  # separate elements and LilyPond can only say one of them.
  def key_value(event)
    raise NotImplementedError, "#{self.class} must map a key signature event to its rendering"
  end
end
