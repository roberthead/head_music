# Renders HeadMusic::Content flows as MusicXML documents
module HeadMusic::Notation::MusicXML
  # +work_title:+ names the whole this flow is a movement of and
  # +movement_number:+ its place in it; alone, a flow names only itself.
  #
  # +transposed:+ says the flow's pitches are already the written ones, so that
  # each part prints its own key and a <transpose> naming what it sounds.
  def self.render(flow, **options)
    Writer.new(flow, **options).to_s
  end

  # Raised when a flow cannot be expressed in the supported MusicXML subset
  class RenderError < HeadMusic::Notation::RenderError; end
end

# Helper classes load in name order; they reference one another only at runtime.
Dir[File.join(__dir__, "music_xml", "*.rb")].sort.each { |file| require file }
