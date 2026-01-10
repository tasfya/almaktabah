# frozen_string_literal: true

require "rails_helper"

RSpec.describe TypesenseSearch::Client do
  after do
    described_class.reset!
  end

  describe ".instance" do
    it "returns a Typesense::Client" do
      expect(described_class.instance).to be_a(::Typesense::Client)
    end

    it "returns the same instance on subsequent calls" do
      first = described_class.instance
      second = described_class.instance

      expect(first).to be(second)
    end
  end

  describe ".multi_search" do
    it "returns the multi_search interface" do
      expect(described_class.multi_search).to be_a(::Typesense::MultiSearch)
    end
  end

  describe ".reset!" do
    it "clears the cached instance" do
      first = described_class.instance
      described_class.reset!
      second = described_class.instance

      expect(first).not_to be(second)
    end
  end
end
