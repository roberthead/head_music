module HeadMusic::Notation::MEI
  # Reads text and attributes so that REXML's expansion limits raise MEI's
  # ParseError; see HeadMusic::Notation::XmlReading.
  XmlReading = HeadMusic::Notation::XmlReading.for(ParseError, format: "MEI")
end
