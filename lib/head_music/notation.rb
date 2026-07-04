# A module for visual music notation
module HeadMusic::Notation; end

# Base error for notation-format parsing (ABC, LilyPond, ...)
class HeadMusic::Notation::ParseError < StandardError; end

# Load notation classes
require "head_music/notation/musical_symbol"
require "head_music/notation/staff_position"
require "head_music/notation/staff_mapping"
require "head_music/notation/abc"
