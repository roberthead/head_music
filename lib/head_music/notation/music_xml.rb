# Renders HeadMusic::Content flows as MusicXML documents
module HeadMusic::Notation::MusicXML
  # Renders a flow as a score-partwise MusicXML string.
  # No rendering options exist yet; keywords will be added with the first one.
  def self.render(flow)
    Writer.new(flow).to_s
  end

  # Raised when a flow cannot be expressed in the supported MusicXML subset
  class RenderError < HeadMusic::Notation::RenderError; end
end

# Helper classes load in name order; they reference one another only at runtime.
Dir[File.join(__dir__, "music_xml", "*.rb")].sort.each { |file| require file }
