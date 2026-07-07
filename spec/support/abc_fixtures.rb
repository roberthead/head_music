# Shared ABC tune strings used across notation specs.
module ABCFixtures
  SPEED_THE_PLOUGH = <<~ABC.freeze
    X:1
    T:Speed the Plough
    M:4/4
    L:1/8
    K:G
    |:GABc dedB|dedB dedB|c2ec B2dB|c2A2 A2BA|
    GABc dedB|dedB dedB|c2ec B2dB|A2F2 G4:|
  ABC

  # Exercises mid-bar accidentals and same-bar natural cancellations.
  CHROMATIC_AIR = <<~ABC.freeze
    X:3
    T:Chromatic Air
    C:Trad.
    O:Nowhere in Particular
    M:4/4
    L:1/8
    K:Am
    A^GA=G ABc2|_BA^F=F E2A2|^c^de=d =c2B2|A2E2 A4|
  ABC
end
