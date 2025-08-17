IN ORDER TO accurately model sound events
AS a developer
I WANT a clear way to group the notion of a Note (pitch + rhythmic value) and an unpitched note.

We need a hierarchy of classes

class RhythmicEvent
  attr_accessor :rhythmic_value

class Note < RhythmicEvent
  attr_accessor :pitch
  def sounded?
    true
  end

class UnpitchedNote < RhythmicEvent
  def sounded?
    true
  end

class Rest < RhythmicEvent
  def sounded?
    false
  end


acceptance criteria
- the above class hierarchy and implementation requirements
- full test coverage
- use AbstractMethodError instead of NotImplementedError in RhythmicEvent if and where appropriate.
