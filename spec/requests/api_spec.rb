# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API", type: :request do
  let(:token) { "test-download-token" }
  let(:auth_headers) { { "Authorization" => "Bearer #{token}" } }
  let(:video_upload) { fixture_file_upload(Rails.root.join("spec/files/test_video.mp4"), "video/mp4") }
  let(:thumbnail_upload) { fixture_file_upload(Rails.root.join("spec/files/thumbnail.jpg"), "image/jpeg") }

  before do
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials).to receive(:dig).with(:api, :download_token).and_return(token)
  end

  def json
    JSON.parse(response.body)
  end

  describe "authentication" do
    endpoints = {
      "GET /api/lectures/pending_downloads" => [ :get, "/api/lectures/pending_downloads" ],
      "POST /api/lectures/:id/upload_video" => [ :post, "/api/lectures/1/upload_video" ],
      "GET /api/lessons/pending_downloads" => [ :get, "/api/lessons/pending_downloads" ],
      "POST /api/lessons/:id/upload_video" => [ :post, "/api/lessons/1/upload_video" ],
      "GET /api/transcriptions/pending" => [ :get, "/api/transcriptions/pending" ],
      "POST /api/transcriptions/:type/:id/upload" => [ :post, "/api/transcriptions/lecture/1/upload" ]
    }

    endpoints.each do |name, (verb, path)|
      context name do
        it "rejects a request without a token" do
          send(verb, path)

          expect(response).to have_http_status(:unauthorized)
          expect(json).to eq("error" => "Unauthorized")
        end

        it "rejects a wrong bearer token" do
          send(verb, path, headers: { "Authorization" => "Bearer wrong" })

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    it "rejects the token when it is sent without the Bearer prefix" do
      get "/api/lectures/pending_downloads", headers: { "Authorization" => "Token #{token}" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects every request when no token is configured" do
      allow(Rails.application.credentials).to receive(:dig).with(:api, :download_token).and_return(nil)
      stub_const("ENV", ENV.to_h.except("YOUTUBE_DOWNLOAD_API_TOKEN"))

      get "/api/lectures/pending_downloads", headers: { "Authorization" => "Bearer " }

      expect(response).to have_http_status(:unauthorized)
    end

    it "falls back to YOUTUBE_DOWNLOAD_API_TOKEN when credentials have no token" do
      allow(Rails.application.credentials).to receive(:dig).with(:api, :download_token).and_return(nil)
      stub_const("ENV", ENV.to_h.merge("YOUTUBE_DOWNLOAD_API_TOKEN" => "env-token"))

      get "/api/lectures/pending_downloads", headers: { "Authorization" => "Bearer env-token" }

      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/lectures/pending_downloads" do
    let!(:pending) { create(:lecture, video: nil, youtube_url: "https://www.youtube.com/watch?v=aaaaaaaaaaa") }

    before do
      create(:lecture, youtube_url: "https://www.youtube.com/watch?v=bbbbbbbbbbb")
      create(:lecture, video: nil, youtube_url: nil)
    end

    it "lists lectures with a YouTube URL and no video" do
      get "/api/lectures/pending_downloads", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json).to eq(
        "lectures" => [ { "id" => pending.id, "title" => pending.title, "youtube_url" => pending.youtube_url } ],
        "count" => 1
      )
    end

    it "honours limit" do
      create(:lecture, video: nil, youtube_url: "https://www.youtube.com/watch?v=ccccccccccc")

      get "/api/lectures/pending_downloads", params: { limit: 1 }, headers: auth_headers

      expect(json["count"]).to eq(1)
      expect(json["lectures"].size).to eq(1)
    end
  end

  describe "POST /api/lectures/:id/upload_video" do
    let(:lecture) { create(:lecture, video: nil, youtube_url: "https://www.youtube.com/watch?v=aaaaaaaaaaa") }

    it "attaches the video and thumbnail" do
      post "/api/lectures/#{lecture.id}/upload_video",
           params: { video: video_upload, thumbnail: thumbnail_upload }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json).to eq("success" => true, "lecture_id" => lecture.id, "video_attached" => true)
      lecture.reload
      expect(lecture.video.filename.to_s).to eq("test_video.mp4")
      expect(lecture.thumbnail.filename.to_s).to eq("thumbnail.jpg")
    end

    it "replaces an existing video" do
      lecture.video.attach(io: StringIO.new("old"), filename: "old.mp4", content_type: "video/mp4")

      post "/api/lectures/#{lecture.id}/upload_video", params: { video: video_upload }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(lecture.reload.video.filename.to_s).to eq("test_video.mp4")
    end

    it "removes the lecture from pending downloads" do
      post "/api/lectures/#{lecture.id}/upload_video", params: { video: video_upload }, headers: auth_headers
      get "/api/lectures/pending_downloads", headers: auth_headers

      expect(json["count"]).to eq(0)
    end

    it "rejects a request without a video" do
      post "/api/lectures/#{lecture.id}/upload_video", params: { thumbnail: thumbnail_upload }, headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json).to eq("error" => "No video file provided")
      expect(lecture.reload.video).not_to be_attached
    end

    it "returns 404 for an unknown lecture" do
      post "/api/lectures/0/upload_video", params: { video: video_upload }, headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/lessons/pending_downloads" do
    let!(:pending) { create(:lesson, youtube_url: "https://www.youtube.com/watch?v=aaaaaaaaaaa") }

    before do
      create(:lesson, :with_video, youtube_url: "https://www.youtube.com/watch?v=bbbbbbbbbbb")
      create(:lesson)
    end

    it "lists lessons with a YouTube URL and no video" do
      get "/api/lessons/pending_downloads", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json).to eq(
        "lessons" => [ { "id" => pending.id, "title" => pending.title, "youtube_url" => pending.youtube_url } ],
        "count" => 1
      )
    end

    it "honours limit" do
      create(:lesson, youtube_url: "https://www.youtube.com/watch?v=ccccccccccc")

      get "/api/lessons/pending_downloads", params: { limit: 1 }, headers: auth_headers

      expect(json["lessons"].size).to eq(1)
    end
  end

  describe "POST /api/lessons/:id/upload_video" do
    let(:lesson) { create(:lesson, youtube_url: "https://www.youtube.com/watch?v=aaaaaaaaaaa") }

    it "attaches the video and thumbnail" do
      post "/api/lessons/#{lesson.id}/upload_video",
           params: { video: video_upload, thumbnail: thumbnail_upload }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json).to eq("success" => true, "lesson_id" => lesson.id, "video_attached" => true)
      expect(lesson.reload.video.filename.to_s).to eq("test_video.mp4")
    end

    it "rejects a request without a video" do
      post "/api/lessons/#{lesson.id}/upload_video", headers: auth_headers

      expect(response).to have_http_status(:unprocessable_entity)
      expect(json).to eq("error" => "No video file provided")
    end

    it "returns 404 for an unknown lesson" do
      post "/api/lessons/0/upload_video", params: { video: video_upload }, headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/transcriptions/pending" do
    let(:scholar) { create(:scholar) }
    let(:other_scholar) { create(:scholar) }
    let!(:lecture) { create(:lecture, :with_final_audio, scholar: scholar) }
    let!(:lesson) { create(:lesson, :with_final_audio, series: create(:series, scholar: other_scholar)) }
    let!(:fatwa) do
      create(:fatwa, scholar: scholar).tap do |f|
        f.final_audio.attach(io: File.open(Rails.root.join("spec/files/audio.mp3")), filename: "audio.mp3")
      end
    end

    before do
      create(:lecture, :with_final_audio, transcription_json: { segments: [] }.to_json)
      create(:lecture)
    end

    def pending_ids
      json["pending"].map { |item| [ item["type"], item["id"] ] }
    end

    it "lists untranscribed records with final audio across all types" do
      get "/api/transcriptions/pending", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(pending_ids).to contain_exactly([ "Lecture", lecture.id ], [ "Lesson", lesson.id ], [ "Fatwa", fatwa.id ])
      expect(json["count"]).to eq(3)
    end

    it "returns the public R2 audio URL" do
      get "/api/transcriptions/pending", params: { type: "lecture" }, headers: auth_headers

      expect(json["pending"].first).to eq(
        "id" => lecture.id, "type" => "Lecture", "title" => lecture.title,
        "audio_url" => "https://bucket.3ilm.org/#{lecture.final_audio.blob.key}"
      )
    end

    it "filters by type" do
      get "/api/transcriptions/pending", params: { type: "fatwa" }, headers: auth_headers

      expect(pending_ids).to eq([ [ "Fatwa", fatwa.id ] ])
    end

    it "ignores an unknown type and queries every type" do
      get "/api/transcriptions/pending", params: { type: "book" }, headers: auth_headers

      expect(json["count"]).to eq(3)
    end

    it "filters by scholar, through the series for lessons" do
      get "/api/transcriptions/pending", params: { scholar_id: other_scholar.id }, headers: auth_headers

      expect(pending_ids).to eq([ [ "Lesson", lesson.id ] ])
    end

    it "stops at limit" do
      get "/api/transcriptions/pending", params: { limit: 2 }, headers: auth_headers

      expect(json["count"]).to eq(2)
    end
  end

  describe "POST /api/transcriptions/:type/:id/upload" do
    let(:lecture) { create(:lecture) }
    let(:transcription) { { segments: [ { start: 0, end: 1.5, text: "بسم الله" } ] }.to_json }

    it "stores the transcription" do
      post "/api/transcriptions/lecture/#{lecture.id}/upload",
           params: { transcription_json: transcription }, headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(json).to eq("success" => true, "id" => lecture.id, "type" => "Lecture")
      expect(lecture.reload.transcription_json).to eq(transcription)
    end

    it "accepts lessons and fatwas" do
      lesson = create(:lesson)
      fatwa = create(:fatwa)

      post "/api/transcriptions/lesson/#{lesson.id}/upload", params: { transcription_json: transcription }, headers: auth_headers
      post "/api/transcriptions/fatwa/#{fatwa.id}/upload", params: { transcription_json: transcription }, headers: auth_headers

      expect(lesson.reload.transcription_json).to eq(transcription)
      expect(fatwa.reload.transcription_json).to eq(transcription)
    end

    {
      "an unsupported type" => [ "book", { transcription_json: "{}" }, "Invalid type" ],
      "a missing payload" => [ "lecture", {}, "No transcription data provided" ],
      "malformed JSON" => [ "lecture", { transcription_json: "{not json" }, "Invalid JSON" ],
      "JSON without segments" => [ "lecture", { transcription_json: { text: "x" }.to_json }, "Invalid transcription format" ],
      "non-array segments" => [ "lecture", { transcription_json: { segments: "x" }.to_json }, "Invalid transcription format" ],
      "a JSON array" => [ "lecture", { transcription_json: "[]" }, "Invalid transcription format" ]
    }.each do |description, (type, params, error)|
      it "rejects #{description}" do
        post "/api/transcriptions/#{type}/#{lecture.id}/upload", params: params, headers: auth_headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json).to eq("error" => error)
        expect(lecture.reload.transcription_json).to be_blank
      end
    end

    it "returns 404 for an unknown record" do
      post "/api/transcriptions/lecture/0/upload", params: { transcription_json: transcription }, headers: auth_headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
