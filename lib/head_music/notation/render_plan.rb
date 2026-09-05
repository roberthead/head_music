# A module for visual music notation
module HeadMusic::Notation; end

# The measure-level facts every Writer needs, whatever format it emits: the
# range of bars, the key and time signatures in force at each one, and the
# placements each bar holds. A format's plan subclasses this and adds what
# only that format needs — LilyPond its tokens, MusicXML its divisions,
# durations, and beams.
#
# Construction eagerly computes everything that can raise on an unmappable
# key or meter, so a plan that builds successfully cannot fail assembly on
# those grounds.
class HeadMusic::Notation::RenderPlan
  attr_reader :composition

  def initialize(composition)
    @composition = composition
    precompute_eager_data
  end

  def bar_numbers
    composition.earliest_bar_number..composition.latest_bar_number
  end

  def measure_key_changes
    @measure_key_changes ||= bar_numbers.zip(composition.bars).filter_map { |bar_number, bar|
      [bar_number, key_value(bar.key_signature)] if bar.key_signature
    }.to_h
  end

  def measure_time_changes
    @measure_time_changes ||= bar_numbers.zip(composition.bars).filter_map { |bar_number, bar|
      [bar_number, bar.meter] if bar.meter
    }.to_h
  end

  def first_measure_key
    @first_measure_key ||= measure_key_changes[bar_numbers.first] || key_value(composition.key_signature)
  end

  def first_measure_meter
    @first_measure_meter ||= effective_meter(bar_numbers.first)
  end

  def effective_meter(bar_number)
    change_bar = measure_time_changes.keys.select { |number| number <= bar_number }.max
    change_bar ? measure_time_changes[change_bar] : composition.meter
  end

  def placements_by_bar(voice)
    @placements_by_bar ||= {}
    @placements_by_bar[voice] ||= voice.placements.group_by { |placement| placement.position.bar_number }
  end

  private

  # A subclass computes here whatever else must raise at construction, and
  # calls super for the signatures every format needs.
  def precompute_eager_data
    first_measure_key
    first_measure_meter
    measure_key_changes
    measure_time_changes
  end

  # How the format renders a key signature. A subclass answers in the shape
  # its Writer emits: a LilyPond token, a Hash of MusicXML element values.
  def key_value(key_signature)
    raise NotImplementedError, "#{self.class} must map a key signature to its rendering"
  end
end
