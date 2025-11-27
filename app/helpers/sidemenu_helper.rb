# frozen_string_literal: true

module SidemenuHelper
  def display_sidemenu?(subcategories)
    subcategories.present? && subcategories.size > 1
  end
end
