# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/event_summarizer/event_ingestor"

RSpec.describe EventSummarizer::EventIngestor do
  let(:event) do
    {
      id: "event-1",
      timestamp: "2026-09-01T10:00:00Z",
      type: "click",
      value: 20
    }
  end

  describe ".call" do
    it "accepts valid events" do
      report = described_class.call([event])

      expect(report.accepted.size).to eq(1)
      expect(report.rejected).to be_empty
      expect(report.duplicates).to be_empty
      expect(report.total_seen).to eq(1)
    end

    it "records malformed events as rejected data" do
      invalid = event.merge(timestamp: "wrong")

      report = described_class.call([invalid])

      expect(report.accepted).to be_empty
      expect(report.rejected.size).to eq(1)
      expect(report.rejected.first[:index]).to eq(0)
      expect(report.rejected.first[:raw]).to eq(invalid)
      expect(report.rejected.first[:errors].first).to include("ISO 8601")
    end

    it "keeps the first valid occurrence and records later matching ids as duplicates" do
      duplicate = event.merge(value: 999)

      report = described_class.call([event, duplicate])

      expect(report.accepted.map(&:value)).to eq([20])
      expect(report.duplicate_count).to eq(1)
      expect(report.duplicates.first).to eq(index: 1, id: "event-1")
    end

    it "validates an event before classifying it as a duplicate" do
      invalid_duplicate = event.merge(timestamp: "wrong")

      report = described_class.call([event, invalid_duplicate])

      expect(report.accepted_count).to eq(1)
      expect(report.rejected_count).to eq(1)
      expect(report.duplicate_count).to eq(0)
    end

    it "raises for an invalid collection-level argument" do
      expect {
        described_class.call("not-an-array")
      }.to raise_error(ArgumentError, "events must be an Array")
    end
  end
end
