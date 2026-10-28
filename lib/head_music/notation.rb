# A module for visual music notation
module HeadMusic::Notation; end

# Base error for notation-format parsing (ABC, LilyPond, ...)
class HeadMusic::Notation::ParseError < StandardError; end

# A parse error in a line-based text format, at a line and its text
class HeadMusic::Notation::LineParseError < HeadMusic::Notation::ParseError
  attr_reader :line_number, :snippet

  def initialize(message, line_number: nil, snippet: nil)
    @line_number = line_number
    @snippet = snippet
    message = "#{message} (line #{line_number})" if line_number
    super(message)
  end
end

# Base error for notation-format rendering (ABC, MusicXML, ...)
class HeadMusic::Notation::RenderError < StandardError; end

# Load notation classes
require "head_music/notation/musical_symbol"
require "head_music/notation/staff_position"
require "head_music/notation/staff_mapping"
require "head_music/notation/instrument_notation"
require "head_music/notation/notation_style"
require "head_music/notation/clef_selector"
require "head_music/notation/xml_text"
require "head_music/notation/xml_reading"
require "head_music/notation/parse_preflight"
require "head_music/notation/pitch_spelling"
require "head_music/notation/chord_clashes"
require "head_music/notation/concert_transposition"
require "head_music/notation/voice_track"
require "head_music/notation/bar_map"
require "head_music/notation/clef_changes"
require "head_music/notation/bar_marks"
require "head_music/notation/barline_placement"
require "head_music/notation/mark_reading"
require "head_music/notation/timeline_reading"
require "head_music/notation/fermata_marks"
require "head_music/notation/tempo_mark_reading"
require "head_music/notation/tempo_marks"
require "head_music/notation/tie_folding"
require "head_music/notation/voice_placer"
require "head_music/notation/render_plan"
require "head_music/notation/bar_splitter"
require "head_music/notation/written_links"
require "head_music/notation/beam_groups"
require "head_music/notation/beam_reading"
require "head_music/notation/tuplet_brackets"
require "head_music/notation/hairpin_segments"
require "head_music/notation/span_ends"
require "head_music/notation/melisma_fill"
require "head_music/notation/abc"
require "head_music/notation/music_xml"
require "head_music/notation/lily_pond"
require "head_music/notation/kern"
require "head_music/notation/mei"
