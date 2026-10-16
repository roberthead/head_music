# A module for musical analysis
module HeadMusic::Analysis; end

class HeadMusic::Analysis::KeyFinder
  # The 24 keys a key finder chooses among, fixed by name rather than built
  # through Key#relative. Of each enharmonic pair the tonic with fewer
  # accidentals wins; at six apiece, G♭ major and E♭ minor share a signature.
  KEYS = [
    *%w[C D♭ D E♭ E F G♭ G A♭ A B♭ B].map { |tonic| "#{tonic} major" },
    *%w[C C♯ D E♭ E F F♯ G G♯ A B♭ B].map { |tonic| "#{tonic} minor" }
  ].map { |name| HeadMusic::Rudiment::Key.get(name) }.freeze
end
