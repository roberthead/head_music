# Renders HeadMusic::Content compositions as LilyPond documents
module HeadMusic::Notation::LilyPond
  # Renders a composition as a complete LilyPond source string.
  # No rendering options exist yet; keywords will be added with the first one.
  def self.render(composition, **options)
    Writer.new(composition, **options).to_s
  end

  # Raised when a composition cannot be expressed in the supported LilyPond subset
  class RenderError < HeadMusic::Notation::RenderError; end
end

# Helper classes load in name order; they reference one another only at runtime.
Dir[File.join(__dir__, "lily_pond", "*.rb")].sort.each { |file| require file }
