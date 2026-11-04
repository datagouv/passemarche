# frozen_string_literal: true

class HomeController < ApplicationController
  def index
    respond_to do |format|
      format.html { render :buyer }
    end
  end

  def buyer
    respond_to(&:html)
  end

  def candidate
    respond_to(&:html)
  end
end
