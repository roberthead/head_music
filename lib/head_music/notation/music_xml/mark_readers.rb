require_relative "mark_records"
%w[marking_reader lyric_reader direction_reader slur_reader beam_reader barline_reader navigation_reader].each do |file|
  require_relative file
end

# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  # The mark readers the core runs over every part's records; see MarkReader
  # for what each may assume, and MarkRecords for the records.
  MARK_READERS = [
    MarkingReader, LyricReader, DirectionReader, SlurReader, BeamReader, BarlineReader, NavigationReader
  ].freeze

  # Hands each record to a new instance of every reader, then has each apply
  # what it read.
  module MarkReaders
    HOOKS_BY_RECORD = {NoteRecord => :note, DirectionRecord => :direction, BarlineRecord => :barline}.freeze

    module_function

    def run(records, flow, readers: MARK_READERS)
      instances = readers.map(&:new)
      records.each do |record|
        hook = HOOKS_BY_RECORD.fetch(record.class)
        instances.each { |reader| reader.public_send(hook, record) }
      end
      instances.each { |reader| reader.apply(flow) }
    end
  end
end
