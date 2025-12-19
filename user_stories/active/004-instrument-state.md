# Instrument State Model

AS a developer

I WANT to model transient states of instruments (such as tunings, capos, and mutes)

SO THAT I can represent how an instrument is set up for a particular passage or piece

## Prerequisites

This story depends on **000-overlay-architecture.md**. Instrument states extend the **configuration layer** concept for transient, performance-time modifications that can change during a piece.

## Background

Beyond physical configurations (story 001), instruments can have transient states that affect their sound or pitch. These differ from configurations in that they:
- Can change during a performance
- Are often indicated in the score
- May be accessories rather than parts of the instrument itself

This story complements:
- **Configurations** (001): Physical setup of the instrument itself
- **Playing Techniques**: How the instrument is played (already modeled in `PlayingTechnique`)

## Categories of Instrument State

### 1. Tunings

Instruments can be tuned differently from standard tuning:

| Instrument | Standard Tuning | Alternate Tuning | Name |
|------------|-----------------|------------------|------|
| Guitar | E-A-D-G-B-E | D-A-D-G-B-E | Drop D |
| Guitar | E-A-D-G-B-E | D-A-D-G-A-D | Open D |
| Violin | G-D-A-E | G-D-A-E♭ | Scordatura (varies) |
| Cello | C-G-D-A | B-G-D-A | Bach Suite No. 5 |
| Timpani | Various | Various | Retuned per piece |

### 2. Capos

Fretted instruments can use a capo to raise all strings:

| Instrument | Capo Position | Effect |
|------------|--------------|--------|
| Guitar | Fret 2 | Raises all strings by 2 semitones |
| Banjo | Fret 5 | Raises all strings by 5 semitones |
| Ukulele | Fret 3 | Raises all strings by 3 semitones |

### 3. Mutes

Mutes affect timbre and sometimes pitch:

| Instrument | Mute Type | Effect |
|------------|-----------|--------|
| Trumpet | Straight mute | Alters timbre |
| Trumpet | Cup mute | Warmer, muffled sound |
| Trumpet | Harmon mute | Distinctive "wah" sound |
| Horn | Stopping mute | Raises pitch by semitone |
| Violin | Practice mute | Greatly reduces volume |
| Violin | Orchestral mute | Slightly muffled sound |
| Piano | Soft pedal (una corda) | Shifts hammers |

**Note**: Many mute indications may already be covered by `PlayingTechnique` (e.g., "con sordino", "senza sordino"). This story should clarify the relationship.

## Relationship to PlayingTechnique

The existing `PlayingTechnique` class handles *how* an instrument is played. Some overlap exists:

| Concept | PlayingTechnique? | InstrumentState? |
|---------|-------------------|------------------|
| Pizzicato | ✓ | |
| Con sordino (muted) | ✓ | ✓ (mute type) |
| Harmonics | ✓ | |
| Scordatura | | ✓ |
| Capo | | ✓ |

The distinction:
- **PlayingTechnique**: An action or method of playing
- **InstrumentState**: A setup condition that persists

"Con sordino" is a playing technique indication, but the *type* of mute used is an instrument state.

## Proposed Model

```ruby
# Represents a transient state of an instrument
class HeadMusic::Instruments::InstrumentState
  attr_reader :state_type  # :tuning, :capo, :mute
  attr_reader :details     # type-specific information
end

# Specific state types
class HeadMusic::Instruments::Tuning
  attr_reader :string_pitches  # Array of pitches, low to high
  attr_reader :name            # e.g., "Drop D", "Open G"
end

class HeadMusic::Instruments::Capo
  attr_reader :fret_position   # Integer
  attr_reader :transposition   # Derived from fret_position
end

class HeadMusic::Instruments::Mute
  attr_reader :mute_type       # e.g., :straight, :cup, :harmon, :stopping
  attr_reader :pitch_effect    # Semitones (0 for most, 1 for stopping mute)
end
```

## YAML Representation

```yaml
# In instruments.yml or a separate instrument_states.yml

guitar:
  standard_tuning:
    strings: [E2, A2, D3, G3, B3, E4]
  alternate_tunings:
    drop_d:
      name: "Drop D"
      strings: [D2, A2, D3, G3, B3, E4]
    open_g:
      name: "Open G"
      strings: [D2, G2, D3, G3, B3, D4]
  supports_capo: true

trumpet:
  mutes:
    straight:
      name: "Straight mute"
      pitch_effect: 0
    cup:
      name: "Cup mute"
      pitch_effect: 0
    harmon:
      name: "Harmon mute"
      pitch_effect: 0

horn:
  mutes:
    stopping:
      name: "Stopping mute"
      pitch_effect: 1  # Raises pitch by semitone
```

## User Stories

**STORY 1: Model string tunings**

AS a developer
WHEN I need to represent an alternate tuning
I WANT to use a Tuning object
SO THAT I can calculate correct pitches for fretted/bowed instruments

**STORY 2: Model capo position**

AS a developer
WHEN a guitar or similar instrument uses a capo
I WANT to specify the fret position
SO THAT pitch calculations account for the transposition

**STORY 3: Model mute types**

AS a developer
WHEN a muted passage specifies a particular mute
I WANT to represent the mute type
SO THAT I can distinguish between mute types and their effects

**STORY 4: Integrate with PlayingTechnique**

AS a developer
WHEN a score indicates "con sordino"
I WANT to optionally specify which mute
SO THAT the playing technique and instrument state work together

## Implementation Notes

1. Create `HeadMusic::Instruments::InstrumentState` base class or module
2. Create specific classes: `Tuning`, `Capo`, `Mute`
3. Each state class responds to `[]` for overlay layer resolution
4. Define standard and alternate tunings in YAML
5. States are applied via `instrument.with_state(state)` fluent builder
6. Consider how states interact with `Instrument` and `Content::Note`
7. Clarify relationship with `PlayingTechnique` — possibly `Mute` is referenced by the "con sordino" technique

## Relationship to Overlay Architecture

Instrument states operate at the **configuration layer** level but represent more transient modifications than physical configurations:

```ruby
# Physical configuration (semi-permanent)
piccolo = Instrument.get("piccolo_trumpet")
  .with_configuration(:a_leadpipe)  # player swapped the leadpipe

# Instrument state (can change during performance)
guitar = Instrument.get("guitar")
  .with_state(Tuning.get(:drop_d))  # retuned for this piece
  .with_state(Capo.new(fret: 2))    # capo for this song

horn = Instrument.get("french_horn")
  .with_state(Mute.get(:stopping))  # mute inserted for this passage
```

The distinction between Configuration and InstrumentState:
- **Configuration**: Physical setup that typically doesn't change during performance
- **InstrumentState**: Setup that can change during performance, often indicated in the score

## Acceptance Criteria

- [ ] `HeadMusic::Instruments::Tuning` class exists
- [ ] Standard tunings defined for guitar, violin family, etc.
- [ ] Alternate tunings can be looked up by name
- [ ] `HeadMusic::Instruments::Capo` class exists
- [ ] Capo transposition is calculated correctly
- [ ] `HeadMusic::Instruments::Mute` class exists
- [ ] Mute types defined for brass, strings
- [ ] Pitch effects (e.g., stopping mute) are modeled
- [ ] All existing tests pass
- [ ] New tests cover state functionality
- [ ] Maintains 90%+ test coverage

## Future Considerations

- Partial capos (capo only some strings)
- Pedal positions for harp
- Prepared piano preparations
- Electronic instrument settings/patches
