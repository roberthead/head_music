
Project = overall container.
Flow = segment-level unit (supports sketches, movements, cues).
Sequence = neutral term for the editing canvas (2D space).
Timeline = strictly the axis.




ScorePart
@name
>> instruments
def primary_instrument
def default_staff_system


MusicContent
>> score_parts
@score_type (orchestral, band, chamber, pop, solo)
def ordered_score_parts
def score_parts_grouped_by_orchestra_section
  # so we can square-bracket the sections



Score < MusicContent
@title
@subtitle
@dedication
>> score_credits


ScoreCredit
> person
- role (composer, songwriter, lyricist, arranger, transcriber)


Person
- full_name
- birth_year int optional
- death_year int optional


ScoreLayout < Layout



EnsembleSession (rehearsal, recording, or performance)
>> scores
>> score_part_players


ScorePartPlayer
> score_part
>> players




Player
> person
  - identity? // is a person really a person or a particular name
  - distinction between a unique person and a name



Fragment < MusicContent



Material?


Material

Fragment < Material

Score < Material
- name
-
