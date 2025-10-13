# frozen_string_literal: true

RSpec.shared_examples 'a successful API request' do
  it 'succeeds' do
    expect(subject).to be_success
  end

  it 'returns the API response in context' do
    result = subject
    expect(result.response).to be_a(Net::HTTPOK)
    expect(result.response.body).to eq(successful_response_body)
  end

  it 'includes the correct Authorization header' do
    subject
    expect(
      a_request(:get, endpoint_url)
        .with(headers: { 'Authorization' => "Bearer #{token}" })
    ).to have_been_made.once
  end

  it 'includes the correct Content-Type header' do
    subject
    expect(
      a_request(:get, endpoint_url)
        .with(headers: { 'Content-Type' => 'application/json' })
    ).to have_been_made.once
  end
end

RSpec.shared_examples 'a failed API request' do |status_code, http_class|
  it 'fails' do
    expect(subject).to be_failure
  end

  it "returns the #{status_code} response in context" do
    result = subject
    expect(result.response).to be_a(http_class)
    expect(result.response.code).to eq(status_code.to_s)
  end

  it 'sets an error message' do
    result = subject
    expect(result.error).to be_present
  end
end

RSpec.shared_examples 'API request error handling' do
  context 'when the API request fails (HTTP 404)' do
    let(:error_response_body) do
      {
        errors: [
          {
            code: '00404',
            title: 'Ressource non trouvée',
            detail: "La ressource demandée n'existe pas",
            source: {},
            meta: {}
          }
        ]
      }.to_json
    end

    before do
      stub_request(:get, endpoint_url)
        .with(
          headers: {
            'Authorization' => "Bearer #{token}",
            'Content-Type' => 'application/json'
          }
        )
        .to_return(
          status: 404,
          body: error_response_body,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it_behaves_like 'a failed API request', 404, Net::HTTPNotFound

    it 'returns the error response body' do
      result = subject
      expect(result.response.body).to eq(error_response_body)
    end
  end

  context 'when the API request fails (HTTP 401 Unauthorized)' do
    before do
      stub_request(:get, endpoint_url)
        .to_return(
          status: 401,
          body: {
            errors: [
              {
                code: '00101',
                title: 'Interdit',
                detail: "Votre token n'est pas valide ou n'est pas renseigné",
                source: { parameter: 'token' },
                meta: {}
              }
            ]
          }.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
    end

    it_behaves_like 'a failed API request', 401, Net::HTTPUnauthorized
  end

  context 'when the API request fails (HTTP 500 Server Error)' do
    before do
      stub_request(:get, endpoint_url)
        .to_return(
          status: 500,
          body: 'Internal Server Error',
          headers: { 'Content-Type' => 'text/plain' }
        )
    end

    it_behaves_like 'a failed API request', 500, Net::HTTPInternalServerError
  end
end
