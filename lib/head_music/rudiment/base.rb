module HeadMusic::Rudiment; end

class HeadMusic::Rudiment::Base
  private

  def initialize
    raise HeadMusic::AbstractMethodError, "Cannot instantiate abstract rudiment base class"
  end
end
