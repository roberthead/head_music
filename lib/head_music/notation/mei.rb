# Renders HeadMusic::Content flows as MEI 5.1 documents
module HeadMusic::Notation::MEI
  # +transposed:+ says the flow's pitches are already the written ones.
  # +arranger:+ is a name or a list of names, each its own credit.
  def self.render(flow, **options)
    Writer.new([flow], **options).to_s
  end

  # Raised when a flow cannot be expressed in the supported MEI subset
  class RenderError < HeadMusic::Notation::RenderError; end
end

# The writers that own the extension hooks load first, so that a feature file
# can register with them as it loads.
%w[markup event_writer measure_writer score_def_writer section_writer].each do |name|
  require_relative "mei/#{name}"
end
Dir[File.join(__dir__, "mei", "*.rb")].sort.each { |file| require file }
