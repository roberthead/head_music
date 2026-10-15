# A mark reader that keeps every record it is handed, in order, for specs of
# the MEI reader's frozen contract. Run a parse with it alone registered:
#
#   recorder = MEIMarkRecorder.parse(xml)
#   recorder.records # => every record, in the order the hooks saw them
class MEIMarkRecorder < HeadMusic::Notation::MEI::MarkReader
  class << self
    attr_accessor :last

    def parse(xml)
      original = HeadMusic::Notation::MEI::MARK_READERS.dup
      HeadMusic::Notation::MEI::MARK_READERS.replace([self])
      HeadMusic::Notation::MEI.parse(xml)
      last
    ensure
      HeadMusic::Notation::MEI::MARK_READERS.replace(original)
    end
  end

  attr_reader :records, :flow, :hooks

  def initialize(anchors)
    super
    @records = []
    @hooks = []
    self.class.last = self
  end

  public :anchors

  def event(record)
    keep(:event, record)
  end

  def control(record)
    keep(:control, record)
  end

  def measure(record)
    keep(:measure, record)
  end

  def apply(flow)
    @hooks << :apply
    @flow = flow
  end

  def of(type)
    records.grep(type)
  end

  private

  def keep(hook, record)
    @hooks << hook
    @records << record
  end
end
