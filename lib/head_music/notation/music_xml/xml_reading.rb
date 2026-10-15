# A namespace for MusicXML-notation reading helpers
module HeadMusic::Notation::MusicXML
  XmlReading = HeadMusic::Notation::XmlReading.for(ParseError, format: "MusicXML")
end
