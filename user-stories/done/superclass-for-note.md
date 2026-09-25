<!--
metadata:
  created_at:
  activated_at:
  planned_at:
  finished_at:
  updated_at:   2026-09-25T13:09:06-07:00
-->

# Story: A Common Superclass for Notes and Rests

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
- use NotImplementedError instead of NotImplementedError in RhythmicEvent if and where appropriate.
