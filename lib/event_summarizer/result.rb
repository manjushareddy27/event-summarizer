# frozen_string_literal: true

module EventSummarizer
  class Result
    attr_reader :value, :errors

    class << self
      def success(value)
        new(success: true, value: value)
      end

      def failure(errors)
        new(success: false, errors: Array(errors))
      end
    end

    def initialize(success:, value: nil, errors: [])
      @success = success
      @value = value
      @errors = errors.freeze

      freeze
    end

    def success?
      @success
    end

    def failure?
      !success?
    end

    private_class_method :new
  end
end
