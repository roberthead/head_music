# ValueEquality gives a value object structural equality based on a declared
# list of attributes. Two instances are equal when they are the same class and
# every declared attribute is equal.
#
#   class Stringing
#     include HeadMusic::ValueEquality
#     value_equality :instrument_key, :courses
#   end
#
# Attributes are read with +send+, so protected or private readers work too.
module HeadMusic::ValueEquality
  module ClassMethods
    def value_equality(*attributes)
      @value_equality_attributes = attributes.freeze
    end

    def value_equality_attributes
      @value_equality_attributes || superclass_value_equality_attributes
    end

    private

    def superclass_value_equality_attributes
      superclass.respond_to?(:value_equality_attributes) ? superclass.value_equality_attributes : []
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def ==(other)
    return false unless other.is_a?(self.class)

    self.class.value_equality_attributes.all? { |attribute| send(attribute) == other.send(attribute) }
  end
end
