# frozen_string_literal: true

module SiretHelpers
  private

  def siret
    context.params[:siret]
  end

  def siren
    context.params[:siret]&.[](0..8)
  end
end
