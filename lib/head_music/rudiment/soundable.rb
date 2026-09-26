# A module for music rudiments
module HeadMusic::Rudiment; end

# Something a voice event can sound: a pitch, or an unpitched sound such as a
# drum hit. A role rather than a superclass, since the two share no state and
# a pitch is also a rudiment of scales, intervals, and keys.
module HeadMusic::Rudiment::Soundable
  def pitched?
    raise NotImplementedError, "#{self.class} must say whether it is pitched"
  end
end
