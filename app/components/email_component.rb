# frozen_string_literal: true

class EmailComponent < ViewComponent::Base
  Content = Data.define(:title, :greeting, :intro, :cta_intro, :cta_label, :url, :warning) do
    def initialize(warning: nil, **rest)
      super
    end
  end

  def initialize(email_content)
    @title = email_content.title
    @greeting = email_content.greeting
    @intro = email_content.intro
    @cta_intro = email_content.cta_intro
    @cta_label = email_content.cta_label
    @url = email_content.url
    @warning = email_content.warning
  end

  private

  def logo_data_uri
    image_path = Rails.root.join('app/assets/images/passe-marche-logo-email.jpg')
    base64 = Base64.strict_encode64(File.binread(image_path))
    "data:image/jpeg;base64,#{base64}"
  end
end
