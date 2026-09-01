# frozen_string_literal: true

require "time"

require_relative "result"

module EventSummarizer
  class Event
    REQUIRED_FIELDS = %i[id timestamp type value].freeze
    EXPLICIT_TIMEZONE = /(?:Z|[+-]\d{2}:\d{2})\z/

    attr_reader :id, :timestamp, :type, :value

    class << self
      def build(raw)
        return Result.failure("event must be a Hash") unless raw.is_a?(Hash)

        attrs = symbolize_keys(raw)
        errors = validation_errors(attrs)
        return Result.failure(errors) if errors.any?

        timestamp = parse_timestamp(attrs[:timestamp])

        unless timestamp
          return Result.failure(
            "timestamp must be valid ISO 8601 with an explicit timezone: #{attrs[:timestamp].inspect}"
          )
        end

        Result.success(
          new(
            id: attrs[:id],
            timestamp: timestamp,
            type: attrs[:type],
            value: attrs[:value]
          )
        )
      end

      private

      def symbolize_keys(raw)
        raw.each_with_object({}) do |(key, value), result|
          normalized_key = key.respond_to?(:to_sym) ? key.to_sym : key
          result[normalized_key] = value
        end
      end

      def validation_errors(attrs)
        errors = missing_field_errors(attrs)
        return errors if errors.any?

        errors << "id must be a non-empty String" unless valid_string?(attrs[:id])
        errors << "timestamp must be a String" unless attrs[:timestamp].is_a?(String)
        errors << "type must be a non-empty String" unless valid_string?(attrs[:type])
        errors << "value must be numeric" unless valid_numeric?(attrs[:value])
        errors
      end

      def missing_field_errors(attrs)
        REQUIRED_FIELDS.each_with_object([]) do |field, errors|
          errors << "#{field} is missing" unless attrs.key?(field)
        end
      end

      def valid_string?(value)
        value.is_a?(String) && !value.strip.empty?
      end

      def valid_numeric?(value)
        return false unless value.is_a?(Numeric)
        return false if value.is_a?(Complex)

        !value.respond_to?(:finite?) || value.finite?
      end

      def parse_timestamp(raw)
        return nil unless raw.match?(EXPLICIT_TIMEZONE)

        Time.iso8601(raw)
      rescue ArgumentError
        nil
      end
    end

    def initialize(id:, timestamp:, type:, value:)
      @id = id.dup.freeze
      @timestamp = timestamp.freeze
      @type = type.dup.freeze
      @value = value

      freeze
    end

    private_class_method :new
  end
end
