# frozen_string_literal: true

class EmailComponent < ViewComponent::Base
  Content = Data.define(:title, :greeting, :intro, :cta_intro, :cta_label, :url, :warning, :notice) do
    def initialize(greeting: nil, cta_intro: nil, cta_label: nil, url: nil, warning: nil, notice: nil, **rest)
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
    @notice = email_content.notice
  end

  private

  def inline_image_url(filename)
    return helpers.image_url(filename) unless helpers.respond_to?(:attachments)

    helpers.attachments[filename].url
  end
end
