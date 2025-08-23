module HeadMusic::Rudiment; end

class HeadMusic::Rudiment::Base
  private

  def initialize
    raise NotImplementedError, "Cannot instantiate abstract rudiment base class"
  end
end
