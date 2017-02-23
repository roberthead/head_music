class HeadMusic::Consonance
  LEVELS = %w[perfect imperfect dissonant]

  def self.get(name)
    @consonances ||= {}
    @consonances[name.to_sym] ||= new(name) if LEVELS.include?(name.to_s)
  end
  singleton_class.send(:alias_method, :[], :get)

  attr_reader :name

  delegate :to_s, to: :name

  def initialize(name)
    @name = name.to_s.to_sym
  end

  LEVELS.each do |method_name|
    define_method(:"#{method_name}?") { to_s == method_name }
  end
end
