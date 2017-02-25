class HeadMusic::System
  attr_reader :staves

  def initialize(staves: [])
    @staves = staves
  end

  def instruments
    staves.map(&:instrument).compact.uniq
  end
end
