# A module for musical analysis
module HeadMusic::Analysis; end

# A PitchClassSet represents a pitch-class set or pitch collection.
# See also: PitchCollection, PitchClass
class HeadMusic::Analysis::PitchClassSet
  attr_reader :pitch_classes

  delegate :empty?, to: :pitch_classes
  alias_method :empty_set?, :empty?

  def initialize(identifiers)
    @pitch_classes = identifiers.map { |identifier| HeadMusic::Rudiment::PitchClass.get(identifier) }.uniq.sort
  end

  def to_s
    pitch_classes.map(&:to_i).inspect
  end
  alias_method :inspect, :to_s

  def ==(other)
    pitch_classes == other.pitch_classes
  end

  def equivalent?(other)
    pitch_classes == other.pitch_classes
  end

  def size
    @size ||= pitch_classes.length
  end

  def monochord?
    size == 1
  end
  alias_method :monad?, :monochord?

  def dichord?
    size == 2
  end
  alias_method :dyad?, :dichord?

  def trichord?
    size == 3
  end

  def tetrachord?
    size == 4
  end

  def pentachord?
    size == 5
  end

  def hexachord?
    size == 6
  end

  def heptachord?
    size == 7
  end

  def octachord?
    size == 8
  end

  def nonachord?
    size == 9
  end

  def decachord?
    size == 10
  end

  def undecachord?
    size == 11
  end

  def dodecachord?
    size == 12
  end

  # Returns the inversion of the pitch class set
  # Inversion maps each pitch class to its inverse around 0
  # For pitch class n, the inversion is (12 - n) mod 12
  def inversion
    @inversion ||=
      self.class.new(
        pitch_classes.map { |pc| (12 - pc.to_i) % 12 }
      )
  end

  # Returns the normal form of the pitch class set
  # The normal form is the most compact rotation of the set
  # Algorithm:
  # 1. Generate all rotations of the pitch class set
  # 2. For each rotation, calculate the span (difference between first and last)
  # 3. Choose the rotation with the smallest span
  # 4. If there's a tie, choose the one with the smallest intervals from the left
  def normal_form
    return self if size <= 1

    @rotations ||= generate_rotations
    @most_compact_rotation ||= find_most_compact_rotation(@rotations)

    self.class.new(@most_compact_rotation)
  end

  # Returns the prime form of the pitch class set
  # The prime form is the most compact form among the normal form and its inversion
  # Algorithm:
  # 1. Find the normal form of the original set
  # 2. Find the normal form of the inverted set
  # 3. Compare and choose the most compact one
  # 4. Transpose to start at 0
  def prime_form
    @prime_form ||= begin
      # Handle edge cases
      return self if size.zero?
      return self.class.new([0]) if size == 1

      normal = normal_form.pitch_classes
      inverted_normal = inversion.normal_form.pitch_classes

      # Compare which is more compact
      chosen = compare_forms(normal, inverted_normal)

      # Transpose to start at 0
      transposed = transpose_to_zero(chosen)

      self.class.new(transposed)
    end
  end

  private

  # Generate all rotations of the pitch class set
  def generate_rotations
    return [pitch_classes] if size <= 1

    numbers = pitch_classes.map(&:to_i)
    (0...size).map do |i|
      rotation = numbers.rotate(i)
      # Normalize each rotation to start from the first element
      first = rotation.first
      rotation.map { |n| (n - first) % 12 }
    end
  end

  # Find the most compact rotation
  # Returns the rotation with the smallest span
  # In case of tie, prefer the one with smaller intervals from the left
  def find_most_compact_rotation(rotations)
    rotations.min_by do |rotation|
      # Create a comparison key: [span, intervals from left]
      [rotation.last] + rotation
    end
  end

  # Compare two normal forms and return the more compact one
  # If equal, return the first one
  def compare_forms(form1, form2)
    normalized1 = transpose_to_zero(form1).map(&:to_i)
    normalized2 = transpose_to_zero(form2).map(&:to_i)

    # Compare lexicographically element by element
    comparison = normalized1 <=> normalized2
    (comparison && comparison <= 0) ? form1 : form2
  end

  # Transpose a set of pitch classes to start at 0
  def transpose_to_zero(pcs)
    return pcs if pcs.empty?

    numbers = pcs.map(&:to_i)
    first = numbers.first
    numbers.map { |n| HeadMusic::Rudiment::PitchClass.get((n - first) % 12) }
  end
end
