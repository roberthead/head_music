# Module for style guidelines.
module HeadMusic::Style::Guidelines; end

# Fifth species lets the space between a suspension and its resolution be
# decorated. The resolution is still the note sounding on the bar's second
# strong beat, as in fourth species: a step down from the suspended pitch and
# consonant there, whether attacked on that beat or anticipated and held.
# What is attacked in between is FloridDissonanceTreatment's to judge.
class HeadMusic::Style::Guidelines::EmbellishedSuspensionTreatment < HeadMusic::Style::Guidelines::SuspensionTreatment
  private

  def resolved?(cp_note, cf_note)
    position = resolution_position(cf_note)
    return super unless position

    resolution = voice.note_at(position)
    return false unless resolution

    melodic = HeadMusic::Analysis::MelodicInterval.new(cp_note, resolution)
    melodic.step? && melodic.descending? && consonant_at?(position)
  end

  # The slot presupposes a suspension over a downbeat that lasts to the bar's
  # second strong beat. A cantus note attacked off the downbeat or gone
  # before that beat (a cantus firmus graded against a florid line), and a
  # meter with no second strong beat, all get the strict rule instead.
  def resolution_position(cf_note)
    position = cf_note.position
    return unless position.count == 1 && position.tick.zero?

    slot = (2..position.meter.counts_per_bar)
      .map { |count| HeadMusic::Content::Position.new(flow, "#{position.bar_number}:#{count}") }
      .detect(&:strong?)
    slot if slot&.within_placement?(cf_note)
  end
end
