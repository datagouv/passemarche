# frozen_string_literal: true

class Qualifelec::MakeRequest < MakeRequest
  def endpoint_url
    "v3/qualifelec/etablissements/#{siret}/certificats"
  end

  private

  def siret
    context.params[:siret]
  end
end
