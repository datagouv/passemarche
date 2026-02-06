# frozen_string_literal: true

class RobotsTxtController < ApplicationController
  def show
    render plain: robots_content, content_type: 'text/plain'
  end

  private

  def robots_content
    if Rails.env.production?
      <<~ROBOTS
        User-agent: *
        Allow: /
      ROBOTS
    else
      <<~ROBOTS
        User-agent: *
        Disallow: /
      ROBOTS
    end
  end
end
