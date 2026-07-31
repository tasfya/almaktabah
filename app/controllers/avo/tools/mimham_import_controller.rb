# frozen_string_literal: true

class Avo::Tools::MimhamImportController < Avo::Tools::ApplicationController
  def index
    @result = nil
  end

  def import
    csv_file = params[:csv_file]
    dry_run = params[:dry_run] == "1"
    download_audio = params[:download_audio] == "1"

    if csv_file.blank?
      flash[:error] = "Please upload a CSV file"
      return redirect_to "/avo/tools/mimham_import"
    end

    service = MimhamImportService.new(
      csv_file: csv_file,
      dry_run: dry_run,
      download_audio: download_audio
    )

    @result = service.import
    @dry_run = dry_run

    render :index
  end
end
