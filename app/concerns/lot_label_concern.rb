module LotLabelConcern
  def lot_display_label(lot)
    number = I18n.t('candidate.lot_selection.lot_number', number: lot.position)
    type = lot_type_label(lot)
    type ? "#{number} - #{type}" : number
  end

  def lot_type_label(lot)
    code = lot_type_code(lot)
    code.present? ? I18n.t("market_types.#{code}", default: code.humanize) : nil
  end

  def lot_type_code(lot)
    lot.effective_market_type&.code || public_market.market_type_codes.first
  end
end
