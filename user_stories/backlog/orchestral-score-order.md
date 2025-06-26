# Orchestral Score Order

As a composer or conductor

I want to organize instruments in orchestral score order

So that my scores follow standard orchestral conventions

## Scenario: Display instruments in orchestral order

Given I have a composition with multiple instruments

When I request the score order for an orchestral arrangement

Then the instruments should be ordered as follows:
  - Woodwinds (flutes, oboes, clarinets, bassoons)
  - Brass (horns, trumpets, trombones, tuba)
  - Percussion (timpani, percussion)
  - Harp and keyboards
  - Soloists (instrumental or vocal)
  - Voices
  - Strings (violins I, violins II, viola, violoncellos, double bass)

## Scenario: Use standard orchestral abbreviations

Given I am creating an orchestral score

When I display instrument names

Then I should see standard abbreviations:
  - Fl or Fls for Flutes
  - Ob or Obs for Oboes
  - Cl or Cls for Clarinets
  - Bsn or Bsns for Bassoons
  - Hn or Hns for Horns
  - Tpt or Tpts for Trumpets
  - Trb or Trbs for Trombones
  - Timp for Timpani
  - Perc for Percussion
  - Vlns for Violins
  - Vla for Viola
  - Vcl for Violoncellos
  - DB for Double Bass
