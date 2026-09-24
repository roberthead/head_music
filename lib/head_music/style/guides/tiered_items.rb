# Module for guides
module HeadMusic::Style::Guides; end

# Every item a guide declares, flattened in tier order, for anything that
# answers items_by_tier.
module HeadMusic::Style::Guides::TieredItems
  def guide_items
    @guide_items ||= HeadMusic::Style::Guides::Base::TIERS.flat_map { |tier| items_by_tier[tier] }.freeze
  end
end
