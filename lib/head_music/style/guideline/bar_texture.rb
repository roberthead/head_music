module HeadMusic::Style; end

class HeadMusic::Style::Guideline
  # The species texture of each of a voice's bars: :whole, :half, :quarter, or
  # :ligature (a half tied over the barline, as in fourth species), else
  # :florid for a mixed bar or :empty for a silent one.
  class BarTexture
    SINGLE_SPECIES_TEXTURES = %i[whole half quarter ligature].freeze

    attr_reader :voice

    def initialize(voice)
      @voice = voice
      @textures = {}
    end

    def [](bar_number)
      @textures[bar_number] ||= classify(bar_number)
    end

    def single_species?(bar_number)
      SINGLE_SPECIES_TEXTURES.include?(self[bar_number])
    end

    private

    # A mixed bar is florid; an empty bar is the rest rules' fault. Either one
    # ends a run without counting toward one.
    def classify(bar_number)
      tail = tail_into(bar_number)
      attacks = notes_in_bar(bar_number)
      return tail ? tail_texture(tail, attacks, bar_number) : :empty if attacks.empty?
      return tail_texture(tail, attacks, bar_number) if tail

      attack_texture(attacks, bar_number)
    end

    def notes_in_bar(bar_number)
      voice.notes.select { |note| note.position.bar_number == bar_number }
    end

    def downbeat_of(bar_number)
      HeadMusic::Content::Position.new(voice.flow, "#{bar_number}:1")
    end

    def tail_into(bar_number)
      downbeat = downbeat_of(bar_number)
      held = voice.note_at(downbeat)
      held if held && held.position < downbeat
    end

    def tail_texture(tail, attacks, bar_number)
      return :whole if attacks.empty? && tail.next_position >= downbeat_of(bar_number + 1)
      return :ligature if attacks.any? && attacks.all? { |note| undotted?(note, "half") }

      :florid
    end

    # A note that fills its bar is the first-species texture however it is
    # notated, so the dotted whole of a triple-meter cantus counts.
    def attack_texture(attacks, bar_number)
      return :whole if attacks.one? && fills_bar?(attacks.first, bar_number)
      return :half if attacks.all? { |note| undotted?(note, "half") }
      return :quarter if attacks.all? { |note| undotted?(note, "quarter") || undotted?(note, "eighth") }

      :florid
    end

    def fills_bar?(note, bar_number)
      note.position == downbeat_of(bar_number) && note.next_position >= downbeat_of(bar_number + 1)
    end

    # A tied note is judged by its attack.
    def undotted?(note, unit_name)
      attack = note.rhythmic_duration.values.first
      attack.unit_name == unit_name && attack.dots.zero?
    end
  end
end
