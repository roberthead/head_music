# A namespace for LilyPond-notation parsing helpers
module HeadMusic::Notation::LilyPond
  # Everything the reader learned from a document, before any flow
  # exists: the header's identity fields and one event stream per voice.
  # The flow cannot be constructed until the opening key and meter
  # are known, and they arrive inside the first voice, so the document
  # holds the streams until the reader is done.
  class Document
    # A \new PianoStaff or \new StaffGroup, with the staves declared in it in
    # order. A staff's name is what a \change Staff command refers to.
    Group = Struct.new(:bracket, :staves)
    GroupStaff = Struct.new(:group, :name)

    attr_accessor :title, :composer
    attr_reader :streams, :groups, :dynamics_streams

    def initialize
      @streams = []
      @groups = []
      @dynamics_streams = []
    end

    def add_group(bracket)
      Group.new(bracket, []).tap { |group| @groups << group }
    end

    def add_group_staff(group, name)
      GroupStaff.new(group, name).tap { |staff| group.staves << staff }
    end

    def add_stream(role = nil)
      stream = VoiceStream.new(role)
      @streams << stream
      stream
    end

    def remove_stream(stream)
      @streams.delete(stream)
    end

    # A \new Dynamics holds no voice, so its stream is kept apart from the
    # voices'. Its target is the Group, or the voice streams of the staff,
    # whose part its dynamics govern.
    def add_dynamics_stream(target)
      stream = VoiceStream.new
      stream.dynamics_target = target
      @dynamics_streams << stream
      stream
    end

    def first_key_signature
      leading_event(:key)&.key_signature
    end

    def first_meter
      leading_event(:time)&.meter
    end

    private

    # The first command of a kind that precedes any music in its stream,
    # taken from the first stream that has one.
    def leading_event(kind)
      streams.each do |stream|
        event = stream.events.take_while { |candidate| !candidate.music? }.find { |candidate| candidate.kind == kind }
        return event if event
      end
      nil
    end
  end
end
