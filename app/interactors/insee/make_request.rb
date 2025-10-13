# frozen_string_literal: true

class Insee::MakeRequest < MakeRequest
  def endpoint_url
    "v3/insee/sirene/etablissements/#{siret}"
  end

  def request_params
    {}
  end

  private

  def siret
    context.params[:siret]
  end
end
