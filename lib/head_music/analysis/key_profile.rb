# A module for musical analysis
module HeadMusic::Analysis; end

# The weight of each pitch class in a key, from the tonic upward in semitones,
# for major and for minor. Correlating a pitch-class histogram with each of
# the 24 rotations scores how well the music fits each key.
#
# The values are stored as Rationals, so that keys whose correlations are
# equal in exact arithmetic tie exactly.
HeadMusic::Analysis::KeyProfile = Data.define(:name, :major, :minor, :source)

class HeadMusic::Analysis::KeyProfile
  # Each table was checked against Humdrum keycor (humextra cli/keycor.cpp)
  # and music21 (analysis/discrete.py), which agree digit for digit.
  PROFILES = {
    aarden_essen: {
      major: [17.7661r, 0.145624r, 14.9265r, 0.160186r, 19.8049r, 11.3587r, 0.291248r, 22.062r, 0.145624r, 8.15494r, 0.232998r, 4.95122r],
      minor: [18.2648r, 0.737619r, 14.0499r, 16.8599r, 0.702494r, 14.4362r, 0.702494r, 18.6161r, 4.56621r, 1.93186r, 7.37619r, 1.75623r],
      source: "Aarden, Dynamic Melodic Expectancy, PhD dissertation, Ohio State University (2003), from the Essen Folksong Collection"
    },
    krumhansl_kessler: {
      major: [6.35r, 2.23r, 3.48r, 2.33r, 4.38r, 4.09r, 2.52r, 5.19r, 2.39r, 3.66r, 2.29r, 2.88r],
      minor: [6.33r, 2.68r, 3.52r, 5.38r, 2.60r, 3.53r, 2.54r, 4.75r, 3.98r, 2.69r, 3.34r, 3.17r],
      source: "Krumhansl, Cognitive Foundations of Musical Pitch (1990), from Krumhansl and Kessler, Psychological Review 89 (1982)"
    },
    temperley: {
      major: [0.748r, 0.060r, 0.488r, 0.082r, 0.670r, 0.460r, 0.096r, 0.715r, 0.104r, 0.366r, 0.057r, 0.400r],
      minor: [0.712r, 0.084r, 0.474r, 0.618r, 0.049r, 0.460r, 0.105r, 0.747r, 0.404r, 0.067r, 0.133r, 0.330r],
      source: "Temperley, Music and Probability (2007), p. 85, from the Kostka-Payne corpus"
    }
  }.freeze

  def self.get(name)
    return name if name.is_a?(self)

    attributes = PROFILES[name&.to_sym]
    raise ArgumentError, "unknown key profile #{name.inspect}; use one of #{names.join(", ")}" unless attributes

    new(name: name.to_sym, **attributes)
  end

  def self.names
    PROFILES.keys
  end

  def initialize(name:, major:, minor:, source:)
    super(name: name, major: major.map(&:to_r).freeze, minor: minor.map(&:to_r).freeze, source: source)
  end

  # The Pearson correlation of the histogram with each key: the twelve major
  # keys with tonics C upward, then the twelve minor keys. A histogram or
  # profile with no variance correlates 0 with everything.
  def correlations(histogram)
    weights = histogram.map(&:to_r)
    deviations = deviations_of(weights)
    variance = sum_of_squares(deviations)
    [terms_of(major), terms_of(minor)].flat_map do |profile_deviations, profile_variance|
      (0..11).map do |tonic|
        next 0.0 if variance.zero? || profile_variance.zero?

        covariance = (0..11).sum { |pitch_class| deviations[pitch_class] * profile_deviations[(pitch_class - tonic) % 12] }
        covariance.to_f / Math.sqrt((variance * profile_variance).to_f)
      end
    end
  end

  private

  def terms_of(values)
    deviations = deviations_of(values)
    [deviations, sum_of_squares(deviations)]
  end

  def deviations_of(values)
    mean = values.sum(0r) / values.length
    values.map { |value| value - mean }
  end

  def sum_of_squares(values)
    values.sum(0r) { |value| value * value }
  end
end
