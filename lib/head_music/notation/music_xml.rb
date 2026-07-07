# Renders HeadMusic::Content compositions as MusicXML documents
module HeadMusic::Notation::MusicXML
  # Renders a composition as a score-partwise MusicXML string.
  # No rendering options exist yet; keywords will be added with the first one.
  def self.render(composition)
    Writer.new(composition).to_s
  end

  # Raised when a composition cannot be expressed in the supported MusicXML subset
  class RenderError < HeadMusic::Notation::RenderError; end
end

# Helper classes load in name order; they reference one another only at runtime.
Dir[File.join(__dir__, "music_xml", "*.rb")].sort.each { |file| require file }
