# frozen_string_literal: true

require_relative "event"

module EventSummarizer
  class Aggregator
    class << self
      def call(events, from: nil, to: nil)
        new(events, from: from, to: to).call
      end
    end

    def initialize(events, from: nil, to: nil)
      @events = events
      @from = from
      @to = to

      validate_events!
      validate_date_range!
    end

    def call
      relevant_events = filter_by_date

      {
        total: relevant_events.size,
        type: aggregate_by_type(relevant_events)
      }
    end

    private

    def validate_events!
      raise ArgumentError, "events must be an Array" unless @events.is_a?(Array)

      return if @events.all? { |event| event.is_a?(Event) }

      raise ArgumentError, "events must contain only Event objects"
    end

    def aggregate_by_type(events)
      events.each_with_object({}) do |event, summary|
        summary[event.type] ||= {
          count: 0,
          aggregate: 0
        }

        summary[event.type][:count] += 1
        summary[event.type][:aggregate] += event.value
      end
    end

    def filter_by_date
      return @events if @from.nil? && @to.nil?

      @events.select do |event|
        after_start = @from.nil? || event.timestamp >= @from
        before_end = @to.nil? || event.timestamp <= @to

        after_start && before_end
      end
    end

    def validate_date_range!
      raise ArgumentError, "from must be a Time" if @from && !@from.is_a?(Time)
      raise ArgumentError, "to must be a Time" if @to && !@to.is_a?(Time)

      return unless @from && @to && @from > @to

      raise ArgumentError, "from cannot be later than to"
    end
  end
end
