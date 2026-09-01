# frozen_string_literal: true

require "spec_helper"
require_relative "../lib/event_summarizer"

RSpec.describe EventSummarizer do
  describe ".summarize" do
    it "returns the assessment-shaped summary for valid unique events" do
      events = [
        { id: "1", timestamp: "2026-09-01T10:00:00Z", type: "click", value: 10 },
        { id: "2", timestamp: "2026-09-01T10:05:00Z", type: "click", value: 20 },
        { id: "3", timestamp: "2026-09-01T10:10:00Z", type: "purchase", value: 300 },
        { id: "2", timestamp: "2026-09-01T10:15:00Z", type: "click", value: 999 },
        { id: "4", timestamp: "invalid", type: "click", value: 5 }
      ]

      result = described_class.summarize(events)

      expect(result).to eq(
        total: 3,
        type: {
          "click" => { count: 2, aggregate: 30 },
          "purchase" => { count: 1, aggregate: 300 }
        }
      )
    end
  end

  describe ".ingest" do
    it "exposes the detailed ingestion report when diagnostics are needed" do
      events = [
        { id: "1", timestamp: "2026-09-01T10:00:00Z", type: "click", value: 10 },
        { id: "1", timestamp: "2026-09-01T10:05:00Z", type: "click", value: 20 },
        { id: "2", timestamp: "invalid", type: "purchase", value: 30 }
      ]

      report = described_class.ingest(events)

      expect(report).to be_a(EventSummarizer::IngestionReport)
      expect(report.accepted_count).to eq(1)
      expect(report.rejected_count).to eq(1)
      expect(report.duplicate_count).to eq(1)
      expect(report.total_seen).to eq(3)
    end
  end
end
