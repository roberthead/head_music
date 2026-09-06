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
  attr_reader :flow

  def initialize(flow)
    @flow = flow
    precompute_eager_data
  end

  def bar_numbers
    flow.earliest_bar_number..flow.latest_bar_number
  end

  def measure_key_changes
    @measure_key_changes ||= flow.key_signature_changes
      .select { |bar_number, _| bar_numbers.cover?(bar_number) }
      .transform_values { |event| key_value(event) }
  end

  def measure_time_changes
    @measure_time_changes ||= flow.meter_changes.select { |bar_number, _| bar_numbers.cover?(bar_number) }
  end

  def first_measure_key
    @first_measure_key ||= measure_key_changes[bar_numbers.first] || key_value(flow.timeline.opening_key_signature_event)
  end

  def first_measure_meter
    @first_measure_meter ||= effective_meter(bar_numbers.first)
  end

  def effective_meter(bar_number)
    change_bar = measure_time_changes.keys.select { |number| number <= bar_number }.max
    change_bar ? measure_time_changes[change_bar] : flow.meter
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

  # How the format renders a key signature event. A subclass answers in the
  # shape its Writer emits: a LilyPond token, a Hash of MusicXML element
  # values.
  #
  # The event rather than a key signature, because the two fields render
  # differently: MusicXML wants the signature and the interpretation as
  # separate elements, and LilyPond can only say one of them.
  def key_value(event)
    raise NotImplementedError, "#{self.class} must map a key signature event to its rendering"
  end
end
