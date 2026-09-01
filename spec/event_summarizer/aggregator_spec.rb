# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/event_summarizer/aggregator"

RSpec.describe EventSummarizer::Aggregator do
  def build_event(id:, timestamp:, type:, value:)
    EventSummarizer::Event.build(
      id: id,
      timestamp: timestamp,
      type: type,
      value: value
    ).value
  end

  let(:events) do
    [
      build_event(id: "1", timestamp: "2026-09-01T10:00:00Z", type: "click", value: 10),
      build_event(id: "2", timestamp: "2026-09-01T11:00:00Z", type: "click", value: 20),
      build_event(id: "3", timestamp: "2026-09-01T12:00:00Z", type: "purchase", value: 100)
    ]
  end

  describe ".call" do
    it "aggregates count and value by event type" do
      result = described_class.call(events)

      expect(result).to eq(
        total: 3,
        type: {
          "click" => { count: 2, aggregate: 30 },
          "purchase" => { count: 1, aggregate: 100 }
        }
      )
    end

    it "returns an empty summary when there are no events" do
      expect(described_class.call([])).to eq(total: 0, type: {})
    end

    it "preserves fractional numeric aggregation" do
      fractional = [
        build_event(id: "4", timestamp: "2026-09-01T13:00:00Z", type: "purchase", value: 10.5),
        build_event(id: "5", timestamp: "2026-09-01T14:00:00Z", type: "purchase", value: 5)
      ]

      expect(described_class.call(fractional)[:type]["purchase"][:aggregate]).to eq(15.5)
    end

    it "filters inclusively by date range" do
      result = described_class.call(
        events,
        from: Time.iso8601("2026-09-01T11:00:00Z"),
        to: Time.iso8601("2026-09-01T12:00:00Z")
      )

      expect(result[:total]).to eq(2)
      expect(result[:type].keys).to contain_exactly("click", "purchase")
    end

    it "supports a start-only date filter" do
      result = described_class.call(events, from: Time.iso8601("2026-09-01T12:00:00Z"))

      expect(result[:total]).to eq(1)
      expect(result[:type].keys).to eq(["purchase"])
    end

    it "supports an end-only date filter" do
      result = described_class.call(events, to: Time.iso8601("2026-09-01T10:00:00Z"))

      expect(result[:total]).to eq(1)
      expect(result[:type].keys).to eq(["click"])
    end

    it "rejects a non-array collection" do
      expect {
        described_class.call("events")
      }.to raise_error(ArgumentError, "events must be an Array")
    end

    it "rejects collections containing non-Event objects" do
      expect {
        described_class.call([{}])
      }.to raise_error(ArgumentError, "events must contain only Event objects")
    end

    it "rejects a non-Time from value" do
      expect {
        described_class.call(events, from: "2026-09-01")
      }.to raise_error(ArgumentError, "from must be a Time")
    end

    it "rejects a non-Time to value" do
      expect {
        described_class.call(events, to: "2026-09-01")
      }.to raise_error(ArgumentError, "to must be a Time")
    end

    it "rejects a date range where from is later than to" do
      expect {
        described_class.call(
          events,
          from: Time.iso8601("2026-09-02T10:00:00Z"),
          to: Time.iso8601("2026-09-01T10:00:00Z")
        )
      }.to raise_error(ArgumentError, "from cannot be later than to")
    end
  end
end
