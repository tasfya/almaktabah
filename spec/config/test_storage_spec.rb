require "rails_helper"

RSpec.describe TestStorage do
  it "points every Disk service the test env uses at this run's own directory" do
    run_root = Rails.root.join("tmp/storage/run-#{Process.pid}").to_s

    expect(described_class.root).to eq(run_root)
    expect(ActiveStorage::Blob.services.fetch(:test).root).to eq(run_root)
    expect(ActiveStorage::Blob.services.fetch(:public_media_aws).root).to eq(run_root)
  end

  describe ".sweep_dead_runs" do
    around do |example|
      Dir.mktmpdir("test-storage", Rails.root.join("tmp")) do |base|
        @base = base
        example.run
      end
    end

    let(:dead_pid) { Process.wait2(Process.spawn("true")).first }

    it "removes run directories whose process is gone and keeps everything else" do
      dead = FileUtils.mkdir_p(File.join(@base, "run-#{dead_pid}")).first
      alive = FileUtils.mkdir_p(File.join(@base, "run-#{Process.ppid}")).first
      own = FileUtils.mkdir_p(File.join(@base, "run-#{Process.pid}")).first
      legacy = FileUtils.mkdir_p(File.join(@base, "ab")).first
      FileUtils.touch(File.join(dead, "upload"))

      described_class.sweep_dead_runs(@base)

      expect(Dir.exist?(dead)).to be(false)
      expect([ alive, own, legacy ]).to all(satisfy { |dir| Dir.exist?(dir) })
    end
  end
end
