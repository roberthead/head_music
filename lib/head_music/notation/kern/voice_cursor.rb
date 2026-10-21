# A namespace for **kern parsing helpers
module HeadMusic::Notation::Kern
  # One live kern track's place in the file: the layer its tokens go to,
  # when the note it last attacked stops sounding, the tie chain it has
  # open, and the grace notes waiting for its next attack.
  #
  # A tie chain ([, _, ]) becomes one voice event whose rhythmic value
  # carries each tied link, as ABC's tie handling does, and it may cross
  # any number of barlines. A fermata on a later link holds from that link.
  #
  # Grace notes go to the track's next note. Before a rest or a tie's later
  # link they are dropped, and their slurs begin or end on what they lead to;
  # when the track ends first they are dropped too. On a note they keep, the
  # first one's opening slur or phrase begins on it, and their other span
  # marks go to the note. A last grace note tied to a pitch of the note
  # takes the place of the tie's start, so the note's ] ends no chain.
  class VoiceCursor
    # A queued grace token, and whether it is tied to the note after it.
    Grace = Data.define(:token, :tied) do
      def grace_note
        HeadMusic::Content::GraceNote.new(
          sounds: token.pitches, rhythmic_value: token.rhythmic_value, slashed: token.slashed, tied: tied, articulations: token.articulations
        )
      end
    end
    TIED_IN = {nil => nil, :start => :start, :middle => :start, :end => nil}.freeze

    attr_reader :layer
    attr_accessor :busy_until

    # A sub-spine a split starts may attack from the split on, while its
    # clock waits on the note its left sibling still holds, so that the
    # null tokens under that note read as they do in the left sub-spine.
    def initialize(layer, busy_until, starts_at: nil)
      @layer = layer
      @busy_until = busy_until
      @starts_at = starts_at
      @tie = nil
      @tie_line = nil
      @graces = []
    end

    def attackable_at?(time)
      busy_until <= time || (!@starts_at.nil? && @starts_at <= time)
    end

    def queue_grace(token)
      @graces << token
    end

    # Answers the event the token attacked, or nil when it continued a tie.
    def read(token, time, line)
      @starts_at = nil
      @busy_until = time + token.fraction
      queued = @graces
      @graces = []
      graces = (token.type == :note && !@tie) ? lead_ins(queued, token) : []
      grace_opens, grace_marks = graces.empty? ? [[], queued.flat_map(&:span_marks)] : split_marks(graces)
      token = token.with(span_marks: grace_marks + token.span_marks)
      token = token.with(tie: TIED_IN.fetch(token.tie)) if graces.last&.tied
      return continue_tie(token, time, line) if %i[middle end].include?(token.tie)

      ensure_tie_closed
      event = layer.add(time, token, graces, grace_opens)
      open_tie(event, line) if token.tie == :start
      event
    end

    def ensure_tie_closed
      return unless @tie

      raise ParseError.new("A tie is never closed", line_number: @tie_line, snippet: "[")
    end

    private

    def lead_ins(queued, token)
      queued.each_with_index.map do |grace, index|
        tied = index == queued.length - 1 && grace.tie == :start && (names(grace.pitches) - names(token.pitches)).empty?
        Grace.new(grace, tied)
      end
    end

    def split_marks(graces)
      first = graces.first.token.span_marks
      opens = first.reject { |mark| Layer::CLOSES.include?(mark[-1]) }
      closes = first.select { |mark| Layer::CLOSES.include?(mark[-1]) }
      [opens, closes + graces.drop(1).flat_map { |grace| grace.token.span_marks }]
    end

    def open_tie(event, line)
      @tie = event
      @tie_line = line
    end

    def continue_tie(token, time, line)
      mark = (token.tie == :end) ? "]" : "_"
      raise ParseError.new("#{mark} continues a tie that was never opened", line_number: line, snippet: mark) unless @tie
      unless names(@tie.pitches) == names(token.pitches)
        raise ParseError.new("A tie must connect notes of the same pitch", line_number: line, snippet: mark)
      end

      @tie.rhythmic_value = @tie.rhythmic_value.append_tied(token.rhythmic_value)
      @tie.fraction += token.fraction
      @tie.span_marks += token.span_marks
      @tie.fermatas += [time] if token.fermata
      @tie = nil if token.tie == :end
      nil
    end

    def names(pitches)
      pitches.map(&:to_s).sort
    end
  end
end
