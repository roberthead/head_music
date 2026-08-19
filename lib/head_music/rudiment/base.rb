module HeadMusic::Rudiment; end

class HeadMusic::Rudiment::Base
  # Rudiments are values: the C♯ in one chord is the C♯ in another, so each one
  # is built once and looked up by key from then on. Identity is the point --
  # equal rudiments are the same object, and a spelling can be compared with
  # equal? without anyone having written ==.
  #
  # The registry is per class rather than per hierarchy: the ivar is set on
  # whichever class the call arrives at, so Note and Rest keep their own even
  # though both inherit this from RhythmicElement.
  def self.registry
    @registry ||= {}
  end

  # Builds only on a miss, from the key itself unless the rudiment takes
  # something else -- a key is often already the value it identifies.
  def self.fetch_or_register(key, *arguments)
    arguments = [key] if arguments.empty?
    registry[key] ||= new(*arguments)
  end

  private_class_method :registry, :fetch_or_register

  private

  def initialize
    raise NotImplementedError, "Cannot instantiate abstract rudiment base class"
  end
end
