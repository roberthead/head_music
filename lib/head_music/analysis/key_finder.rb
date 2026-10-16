# A module for musical analysis
module HeadMusic::Analysis; end

# Infers the key of unspelled notes by correlating their duration-weighted
# pitch-class histogram with a key profile (Krumhansl, Cognitive Foundations
# of Musical Pitch, 1990; Temperley, The Cognition of Basic Musical
# Structures, 2001). The input is anything NoteInput.for reads.
class HeadMusic::Analysis::KeyFinder
  # The 24 keys a key finder chooses among, fixed by name rather than built
  # through Key#relative. Of each enharmonic pair the tonic with fewer
  # accidentals wins; at six apiece, G♭ major and E♭ minor share a signature.
  KEYS = [
    *%w[C D♭ D E♭ E F G♭ G A♭ A B♭ B].map { |tonic| "#{tonic} major" },
    *%w[C C♯ D E♭ E F F♯ G G♯ A B♭ B].map { |tonic| "#{tonic} minor" }
  ].map { |name| HeadMusic::Rudiment::Key.get(name) }.freeze

  # On equal correlation, the key with fewer accidentals, then major, then the
  # lower tonic pitch class.
  PREFERENCE = KEYS.map do |key|
    [key.key_signature.num_alterations, key.major? ? 0 : 1, key.tonic_spelling.pitch_class.to_i]
  end.freeze

  Candidate = Data.define(:key, :correlation)

  attr_reader :input, :profile

  def initialize(input, profile: :aarden_essen, **note_input_options)
    @input = HeadMusic::Analysis::NoteInput.for(input, **note_input_options)
    @profile = HeadMusic::Analysis::KeyProfile.get(profile)
  end

  # The best key for the whole input, or nil when nothing sounds.
  def key
    candidates.first&.key
  end

  # All 24 keys, best first, or none when nothing sounds.
  def candidates
    @candidates ||= begin
      histogram = histogram_of(input.notes)
      if histogram.sum.zero?
        []
      else
        ranked(profile.correlations(histogram)).map { |index, correlation| Candidate.new(KEYS[index], correlation) }.freeze
      end
    end
  end

  private

  def histogram_of(notes)
    notes.each_with_object(Array.new(12, 0r)) do |note, histogram|
      histogram[note.number % 12] += note.duration
    end
  end

  def ranked(correlations)
    correlations.each_with_index.sort_by { |correlation, index| [-correlation, *PREFERENCE[index]] }.map(&:reverse)
  end
end
