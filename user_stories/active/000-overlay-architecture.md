# Overlay Architecture for Instruments

AS a developer

I WANT instruments to resolve attributes through composable layers (prototype, instance, notation style, configuration)

SO THAT I can model the full complexity of instruments without deep inheritance or conflated concerns

## Background

The current instrument architecture uses nested objects (GenericInstrument → Variant → StaffScheme → Staff) which conflates several independent concerns:

1. **Species defaults** - What a trumpet typically is
2. **Pitched identity** - This specific clarinet is in A
3. **Notation conventions** - British brass band uses treble clef for euphonium
4. **Physical configuration** - Piccolo trumpet with A leadpipe installed

The overlay pattern resolves attributes through a stack of layers, where each layer can override specific attributes while letting others fall through to layers below.

## The Overlay Pattern

### Layer Stack (highest to lowest priority)

```
┌─────────────────────────────┐
│  Configuration Layer        │  ← Reversible modifications (leadpipes, mutes)
├─────────────────────────────┤
│  Notation Style Layer       │  ← Context-specific notation (clef, transposition display)
├─────────────────────────────┤
│  Instance Layer             │  ← Identity attributes (pitched variant selection)
├─────────────────────────────┤
│  Prototype Layer            │  ← Species defaults (from GenericInstrument)
└─────────────────────────────┘
```

### Resolution Example

```ruby
piccolo_trumpet = Instrument.new(
  prototype: GenericInstrument.get("piccolo_trumpet"),  # pitch: Bb, family: trumpet
  configuration: Configuration.get(:a_leadpipe)         # pitch: A
)

piccolo_trumpet.pitch   # => "A" (from configuration layer)
piccolo_trumpet.family  # => "trumpet" (falls through to prototype)
piccolo_trumpet.source_of(:pitch)  # => :configuration
```

### Key Characteristics

1. **Immutable**: Operations return new instances, originals unchanged
2. **Traceable**: Can query which layer provided each attribute
3. **Composable**: Layers can be added/removed independently
4. **Flat resolution**: No deep object traversal to get an attribute

## Core Attributes

These attributes can be provided by any layer:

| Attribute | Type | Description |
|-----------|------|-------------|
| `pitch` | Spelling | The pitch designation (Bb, A, F, etc.) |
| `family` | Symbol | Instrument family key (:trumpet, :clarinet) |
| `clef` | Clef | Primary clef for notation |
| `transposition` | Integer | Semitones from written to sounding pitch |
| `range_low` | Pitch | Lowest playable pitch |
| `range_high` | Pitch | Highest playable pitch |

## Proposed Implementation

### Core Class: Instrument

```ruby
class HeadMusic::Instruments::Instrument
  attr_reader :prototype, :attributes, :configuration, :notation_style

  LAYER_ORDER = [:configuration, :notation_style, :attributes, :prototype].freeze

  def initialize(prototype:, attributes: {}, configuration: nil, notation_style: nil)
    @prototype = prototype
    @attributes = attributes
    @configuration = configuration
    @notation_style = notation_style
  end

  # Resolve attribute through layers
  def [](attr)
    LAYER_ORDER.each do |layer_name|
      layer = layer_for(layer_name)
      next unless layer
      value = layer[attr] if layer.respond_to?(:[])
      return value unless value.nil?
    end
    nil
  end

  # Trace where an attribute comes from
  def source_of(attr)
    LAYER_ORDER.each do |layer_name|
      layer = layer_for(layer_name)
      next unless layer
      return layer_name if layer.respond_to?(:[]) && !layer[attr].nil?
    end
    nil
  end

  # Fluent builders (return new instances)
  def with(**attrs)
    self.class.new(
      prototype: prototype,
      attributes: attributes.merge(attrs),
      configuration: configuration,
      notation_style: notation_style
    )
  end

  def with_configuration(config)
    self.class.new(
      prototype: prototype,
      attributes: attributes,
      configuration: config,
      notation_style: notation_style
    )
  end

  def with_notation_style(style)
    self.class.new(
      prototype: prototype,
      attributes: attributes,
      configuration: configuration,
      notation_style: style
    )
  end

  def without_configuration
    with_configuration(nil)
  end

  # Convenience accessors
  def pitch = self[:pitch]
  def family = self[:family]
  def clef = self[:clef]
  def transposition = self[:transposition]

  private

  def layer_for(name)
    case name
    when :configuration then @configuration
    when :notation_style then @notation_style
    when :attributes then @attributes
    when :prototype then @prototype
    end
  end
end
```

### Layer Classes

Each layer is a simple object that responds to `[]`:

```ruby
# Prototype layer (GenericInstrument) - already exists, needs to respond to []
# Instance layer - just a Hash
# Configuration layer - new class
# NotationStyle layer - new class

class HeadMusic::Instruments::Configuration
  attr_reader :key, :attributes

  def [](attr)
    attributes[attr]
  end
end

class HeadMusic::Notation::NotationStyle
  attr_reader :key, :instrument_notations

  def [](attr)
    # Returns notation-specific overrides
  end
end
```

## User Stories

### STORY 1: Implement layer resolution

AS a developer
WHEN I access an attribute on an Instrument
I WANT it resolved through the layer stack
SO THAT the highest-priority layer providing that attribute wins

**Acceptance criteria:**
- `Instrument#[]` checks layers in order: configuration, notation_style, attributes, prototype
- Returns first non-nil value found
- Returns nil if no layer provides the attribute

### STORY 2: Implement source tracing

AS a developer
WHEN I need to understand where an attribute value comes from
I WANT to query `source_of(attr)`
SO THAT I can debug and inspect instrument configuration

**Acceptance criteria:**
- `Instrument#source_of(:pitch)` returns `:configuration`, `:notation_style`, `:attributes`, or `:prototype`
- Returns `nil` if attribute not found in any layer

### STORY 3: Implement fluent builders

AS a developer
WHEN I need to create a modified instrument
I WANT fluent methods that return new instances
SO THAT instruments remain immutable and composable

**Acceptance criteria:**
- `instrument.with(pitch: "A")` returns new instance with attribute override
- `instrument.with_configuration(config)` returns new instance with configuration
- `instrument.with_notation_style(style)` returns new instance with notation style
- `instrument.without_configuration` returns new instance without configuration
- Original instance is unchanged

### STORY 4: Update GenericInstrument to act as prototype layer

AS a developer
WHEN GenericInstrument is used as a prototype layer
I WANT it to respond to `[]` for attribute access
SO THAT it integrates with the layer resolution system

**Acceptance criteria:**
- `GenericInstrument#[]` returns attribute values
- Existing `GenericInstrument` methods continue to work
- Factory method `.get()` unchanged

### STORY 5: Migrate existing Instrument class

AS a developer
WHEN I use the existing `Instrument.get()` API
I WANT it to work with the new overlay architecture
SO THAT existing code continues to function

**Acceptance criteria:**
- `Instrument.get("trumpet")` returns instrument with prototype layer
- `Instrument.get("clarinet_in_a")` returns instrument with instance layer override
- `Instrument.get("piccolo_trumpet", :a_leadpipe)` returns instrument with configuration
- All existing tests pass

## Migration Strategy

1. **Phase 1**: Add `[]` method to GenericInstrument (backward compatible)
2. **Phase 2**: Implement new Instrument class with layer resolution
3. **Phase 3**: Create Configuration class (enables story 001)
4. **Phase 4**: Create NotationStyle class (enables story 002)
5. **Phase 5**: Simplify Variant to PitchedVariant (enables story 003)
6. **Phase 6**: Add InstrumentState classes (enables story 004)

## Relationship to Other Stories

This story is a **prerequisite** for:
- 001-instrument-configuration.md (Configuration layer)
- 002-notation-style.md (NotationStyle layer)
- 003-pitched-variant.md (Instance layer refinement)
- 004-instrument-state.md (Configuration layer extension)

## Acceptance Criteria

- [ ] `Instrument` class implements layer resolution via `[]`
- [ ] `Instrument#source_of` traces attribute origins
- [ ] Fluent builders (`with`, `with_configuration`, `with_notation_style`) work correctly
- [ ] `GenericInstrument` responds to `[]` for use as prototype layer
- [ ] `Instrument.get()` API preserved for backward compatibility
- [ ] All existing tests pass
- [ ] New tests cover layer resolution, tracing, and builders
- [ ] Maintains 90%+ test coverage

## Open Questions

1. **Additive attributes**: Some attributes (like range extensions) should *add to* rather than *replace* prototype values. How should this be handled? Options:
   - Special resolution logic for specific attributes
   - Layers declare whether they extend or replace
   - Separate `extend_range_low` attribute that's always additive

2. **Multiple staves**: Piano needs two staves (grand staff). Is this one attribute (`staves: [treble, bass]`) or should each staff be a separate concern?

3. **Notation style scope**: Should NotationStyle provide instrument-specific overrides, or just context defaults that instruments can reference?
