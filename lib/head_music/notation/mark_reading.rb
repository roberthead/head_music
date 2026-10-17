# A module for visual music notation
module HeadMusic::Notation
  # Hands each record to every reader, by the hook its record class names,
  # then has each reader apply what it read.
  module MarkReading
    module_function

    def run(records, flow, readers, hooks)
      records.each do |record|
        hook = hooks.fetch(record.class)
        readers.each { |reader| reader.public_send(hook, record) }
      end
      readers.each { |reader| reader.apply(flow) }
    end
  end
end
