# frozen_string_literal: true

require "set"

require_relative "event"
require_relative "ingestion_report"

module EventSummarizer
  class EventIngestor
    class << self
      def call(raw_events)
        new(raw_events).call
      end
    end

    def initialize(raw_events)
      raise ArgumentError, "events must be an Array" unless raw_events.is_a?(Array)

      @raw_events = raw_events
    end

    def call
      accepted = []
      rejected = []
      duplicates = []
      seen_ids = Set.new

      @raw_events.each_with_index do |raw, index|
        result = Event.build(raw)

        if result.failure?
          rejected << rejection(index, raw, result.errors)
          next
        end

        event = result.value

        if seen_ids.include?(event.id)
          duplicates << duplicate(index, event.id)
          next
        end

        seen_ids << event.id
        accepted << event
      end

      IngestionReport.new(
        accepted: accepted.freeze,
        rejected: rejected.freeze,
        duplicates: duplicates.freeze
      )
    end

    private

    def rejection(index, raw, errors)
      {
        index: index,
        raw: raw,
        errors: errors
      }.freeze
    end

    def duplicate(index, id)
      {
        index: index,
        id: id
      }.freeze
    end
  end
end
