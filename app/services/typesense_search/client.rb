# frozen_string_literal: true

module TypesenseSearch
  module Client
    def self.instance
      @instance ||= ::Typesense::Client.new(::Typesense.configuration)
    end

    def self.multi_search
      instance.multi_search
    end

    def self.reset!
      @instance = nil
    end
  end
end
