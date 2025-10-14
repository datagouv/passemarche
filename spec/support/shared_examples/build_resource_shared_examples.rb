# frozen_string_literal: true

RSpec.shared_examples 'a successful resource builder' do
  it 'succeeds' do
    expect(subject).to be_success
  end

  it 'creates a BundledData object in context' do
    result = subject
    expect(result.bundled_data).to be_a(BundledData)
  end

  it 'creates a Resource object with the extracted data' do
    result = subject
    expect(result.bundled_data.data).to be_a(Resource)
  end

  it 'sets an empty context hash in BundledData' do
    result = subject
    expect(result.bundled_data.context).to eq({})
  end
end

RSpec.shared_examples 'resource field extraction' do |field_name, expected_value|
  it "extracts the #{field_name} field" do
    result = subject
    expect(result.bundled_data.data.public_send(field_name)).to eq(expected_value)
  end
end
