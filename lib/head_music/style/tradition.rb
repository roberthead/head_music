# A style tradition represents a historical or theoretical approach to music
module HeadMusic::Style
  class Tradition
    def self.get(name)
      case name&.to_sym
      when :modern, :standard_practice then ModernTradition.new
      when :renaissance_counterpoint, :two_part_harmony then RenaissanceTradition.new
      when :medieval then MedievalTradition.new
      else ModernTradition.new
      end
    end

    def consonance_classification(interval)
      raise HeadMusic::AbstractMethodError, "#{self.class} must implement consonance_classification"
    end

    def name
      self.class.name.split("::").last.sub(/Tradition$/, "").downcase.gsub(" ", "_").to_sym
    end
  end
end
