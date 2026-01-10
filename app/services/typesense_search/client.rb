# frozen_string_literal: true

module TypesenseSearch
  module Client
    @mutex = Mutex.new

    def self.instance
      return @instance if @instance

      @mutex.synchronize do
        @instance ||= ::Typesense::Client.new(::Typesense.configuration)
      end
    end

    def self.multi_search
      instance.multi_search
    end

    def self.reset!
      @mutex.synchronize { @instance = nil }
    end
  end
end
