require "fileutils"

# Each rspec process uploads into its own tmp/storage/run-<pid> and removes it
# when the suite ends, so runs overlapping in one worktree never delete each
# other's files. config/storage.yml reads the root from ACTIVE_STORAGE_TEST_ROOT,
# which rails_helper sets before the app boots.
module TestStorage
  BASE = File.expand_path("../../tmp/storage", __dir__)
  RUN_DIR = /\Arun-(\d+)\z/

  def self.root
    File.join(BASE, "run-#{Process.pid}")
  end

  # A run killed before after(:suite) leaves its directory behind.
  def self.sweep_dead_runs(base = BASE)
    Dir.children(base).each do |name|
      pid = name[RUN_DIR, 1]&.to_i
      FileUtils.rm_rf(File.join(base, name)) if pid && !alive?(pid)
    end
  rescue Errno::ENOENT
    nil
  end

  def self.alive?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH
    false
  rescue Errno::EPERM
    true
  end
end

RSpec.configure do |config|
  config.before(:suite) { TestStorage.sweep_dead_runs }
  config.after(:suite) { FileUtils.rm_rf(TestStorage.root) }
end
