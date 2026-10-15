module HeadMusic::Notation::MEI
  # The mark readers the core runs over every record, each registered by
  # the file that defines it; see MarkReader for what each may assume, and
  # MarkRecords for the records.
  MARK_READERS = []

  # Hands each record to a new instance of every reader, then has each apply
  # what it read.
  module MarkReaders
    HOOKS_BY_RECORD = {EventRecord => :event, ControlRecord => :control, MeasureRecord => :measure}.freeze

    module_function

    def run(records, flow, anchors, readers: MARK_READERS)
      instances = readers.map { |reader| reader.new(anchors) }
      records.each do |record|
        hook = HOOKS_BY_RECORD.fetch(record.class)
        instances.each { |reader| reader.public_send(hook, record) }
      end
      instances.each { |reader| reader.apply(flow) }
    end
  end
end
