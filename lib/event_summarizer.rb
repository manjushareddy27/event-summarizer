# frozen_string_literal: true

require_relative "event_summarizer/result"
require_relative "event_summarizer/event"
require_relative "event_summarizer/ingestion_report"
require_relative "event_summarizer/event_ingestor"
require_relative "event_summarizer/aggregator"

module EventSummarizer
  class << self
    def summarize(raw_events, from: nil, to: nil)
      report = EventIngestor.call(raw_events)

      Aggregator.call(
        report.accepted,
        from: from,
        to: to
      )
    end

    def ingest(raw_events)
      EventIngestor.call(raw_events)
    end
  end
end
