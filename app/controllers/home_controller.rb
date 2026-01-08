# frozen_string_literal: true

class HomeController < ApplicationController
  include TypesenseListable

  def index
    typesense_search
  end
end
