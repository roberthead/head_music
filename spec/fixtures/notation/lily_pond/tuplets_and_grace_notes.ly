\version "2.26.0"

\header {
  title = "Tuplets and Grace Notes"
  composer = "HeadMusic"
}

\score {
  <<
    \new Staff = "upper" \relative c'' {
      \clef treble \key c \major \time 4/4
      \tuplet 3/2 4 { c8( d e f e d c b a b) } \tuplet 3/2 { c4 } |
      \grace d16 c4 \slashedGrace { e16 d } c4 \appoggiatura d8 c4 \acciaccatura e8 d4 |
      \tuplet 3/2 { \grace d16 c8 \after 8 \p d4 } \tuplet 3/2 c4 \tuplet 3/2 d4 \tuplet 3/2 e4 \tuplet 5/4 { f16 e d c b } |
      \afterGrace 7/8 c2 { d16 e } \grace f16 r4 \tuplet 7/4 { c16 b a g f e d } |
      \tuplet 6/4 { c16 d e f g a } \acciaccatura { b16 } c2. \bar "|."
    }
    \new Staff = "lower" {
      \clef bass \key c \major \time 4/4
      \tupletSpan 4
      \tuplet 3/2 { c8 e g c' g e } \tupletSpan \default \times 2/3 { c4 e g } |
      c1 |
      \times 2/3 { c2 e g } |
      \grace c16~ c2 r2 |
      \grace { g,16( b, } c1) |
    }
  >>
}
