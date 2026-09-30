# Flows whose bars carry barline styles, rehearsal marks, repeats, endings,
# and navigation, for round trips through each format.
module NavigationFixtures
  module_function

  # Played 1, 2, 3, 4, then D.S. to bar 2, 3, To Coda, and the coda in bar 5.
  def dal_segno_al_coda
    HeadMusic::Notation::ABC.parse(<<~ABC)
      X:1
      T:Dal Segno al Coda
      M:4/4
      L:1/4
      K:C
      [P:A] C D E F | !segno! G A B c |[P:B] d c B A !dacoda!| G F E D !D.S.alcoda!|| !coda! C E G c |]
    ABC
  end

  # A repeated A section with 1st and 2nd endings, a B section, and D.C. back
  # to the Fine at the end of the 2nd ending.
  def da_capo_al_fine
    HeadMusic::Notation::ABC.parse(<<~ABC)
      X:1
      T:Da Capo al Fine
      M:3/4
      L:1/4
      K:G
      [P:A]|: G A B |[1 c B A :|[2 c2 d !fine!||
      [P:B] e d c | B A G | A G F | G3 !D.C.alfine!|]
    ABC
  end
end
