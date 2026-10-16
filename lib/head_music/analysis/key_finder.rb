# A module for musical analysis
module HeadMusic::Analysis; end

# Infers the key of unspelled notes by correlating their duration-weighted
# pitch-class histogram with a key profile (Krumhansl, Cognitive Foundations
# of Musical Pitch, 1990; Temperley, The Cognition of Basic Musical
# Structures, 2001). The input is anything NoteInput.for reads.
#
# Over a whole piece it answers key regions, each starting at a downbeat. Each
# bar is scored by the histogram of the time sounding in it, summed with
# +window+ bars on either side. The regions maximize the summed correlation of
# each bar with its key, less +change_penalty+ for every change of key, so a
# region is worth starting only where it gains more than the penalty. The
# first region's tonic is spelled as KEYS spells it, and each later one by the
# enharmonic nearer the previous region's on the line of fifths, so a piece in
# B major moves to F♯ major rather than to G♭ major.
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

  attr_reader :input, :profile, :change_penalty, :window

  def initialize(input, profile: :aarden_essen, change_penalty: 1.0, window: 0, **note_input_options)
    raise ArgumentError, "change_penalty: must not be negative" if change_penalty.negative?
    raise ArgumentError, "window: must be a non-negative Integer" unless window.is_a?(Integer) && !window.negative?

    @input = HeadMusic::Analysis::NoteInput.for(input, **note_input_options)
    @profile = HeadMusic::Analysis::KeyProfile.get(profile)
    @change_penalty = change_penalty
    @window = window
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

  # The key regions of the input, in bar order, or none when nothing sounds.
  # An empty bar scores nothing, so the key in force carries through it.
  def regions
    @regions ||= if candidates.empty?
      []
    else
      bar_starts = input.bar_starts.to_a
      previous = nil
      key_path.each_with_index.chunk_while { |(a, _), (b, _)| a == b }.map do |run|
        key_index, bar_index = run.first
        bar_number, onset = bar_starts[bar_index]
        previous = previous ? self.class.enharmonic_nearer(KEYS[key_index], previous) : KEYS[key_index]
        HeadMusic::Analysis::KeyRegion.new(bar_number: bar_number, onset: onset, key: previous)
      end.freeze
    end
  end

  # The spelling of a key whose tonic is nearer another key's on the line of
  # fifths, within seven accidentals, keeping the key as spelled on a tie.
  def self.enharmonic_nearer(key, other)
    line_of_fifths = HeadMusic::Analysis::LineOfFifths
    tonic = line_of_fifths.index_of(key.tonic_spelling)
    target = line_of_fifths.index_of(other.tonic_spelling)
    offset = key.major? ? 0 : -3
    nearest = [tonic, tonic - 12, tonic + 12].select { |index| (index + offset).abs <= 7 }.min_by { |index| (index - target).abs }
    return key if nearest == tonic

    HeadMusic::Rudiment::Key.get("#{line_of_fifths.spelling_at(nearest)} #{key.quality}")
  end

  private

  # Viterbi over bars and keys; a tie keeps the key in force. A bar that
  # scores nothing changes no key, so a change waits for the music.
  def key_path
    scores = local_scores
    totals = scores.first.dup
    back_pointers = scores.drop(1).map do |bar_scores|
      next totals.each_index.to_a if bar_scores.all?(&:zero?)

      leader = best_index(totals)
      moved = totals[leader] - change_penalty
      pointers = totals.each_index.map { |index| (totals[index] >= moved) ? index : leader }
      totals = pointers.each_with_index.map { |from, index| totals[from] - ((from == index) ? 0 : change_penalty) + bar_scores[index] }
      pointers
    end
    path = [best_index(totals)]
    back_pointers.reverse_each { |pointers| path.unshift(pointers[path.first]) }
    path
  end

  def best_index(totals)
    totals.each_index.min_by { |index| [-totals[index], *PREFERENCE[index]] }
  end

  def local_scores
    histograms = bar_histograms
    prefix = histograms.each_with_object([Array.new(12, 0r)]) do |histogram, sums|
      sums << sums.last.zip(histogram).map(&:sum)
    end
    histograms.each_index.map do |index|
      low = [index - window, 0].max
      high = [index + window, histograms.length - 1].min
      profile.correlations(prefix[high + 1].zip(prefix[low]).map { |upper, lower| upper - lower })
    end
  end

  # Each note's duration is credited to the bars it sounds in.
  def bar_histograms
    starts = input.bar_starts.values
    index_of_bar = input.bar_starts.keys.each_with_index.to_h
    histograms = Array.new(starts.length) { Array.new(12, 0r) }
    input.notes.each do |note|
      bar_index = index_of_bar.fetch(input.bar_at(note.onset))
      from = note.onset
      finish = note.onset + note.duration
      while from < finish
        bar_end = starts[bar_index + 1]
        to = (bar_end.nil? || finish < bar_end) ? finish : bar_end
        histograms[bar_index][note.number % 12] += to - from
        from = to
        bar_index += 1
      end
    end
    histograms
  end

  def histogram_of(notes)
    notes.each_with_object(Array.new(12, 0r)) do |note, histogram|
      histogram[note.number % 12] += note.duration
    end
  end

  def ranked(correlations)
    correlations.each_with_index.sort_by { |correlation, index| [-correlation, *PREFERENCE[index]] }.map(&:reverse)
  end
end
