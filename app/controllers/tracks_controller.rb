class TracksController < ApplicationController
  def show
    @track = Track.find(params[:id])
  end
end
