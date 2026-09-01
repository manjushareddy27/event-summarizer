# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/event_summarizer/event"

RSpec.describe EventSummarizer::Event do
  describe ".build" do
    let(:valid_event) do
      {
        id: "event-1",
        timestamp: "2026-09-01T10:00:00Z",
        type: "click",
        value: 20
      }
    end

    it "builds a valid immutable event" do
      result = described_class.build(valid_event)
      event = result.value

      expect(result).to be_success
      expect(event.id).to eq("event-1")
      expect(event.type).to eq("click")
      expect(event.value).to eq(20)
      expect(event.timestamp).to eq(Time.iso8601("2026-09-01T10:00:00Z"))
      expect(event).to be_frozen
      expect(event.id).to be_frozen
      expect(event.type).to be_frozen
    end

    it "accepts hashes with string keys" do
      result = described_class.build(valid_event.transform_keys(&:to_s))

      expect(result).to be_success
      expect(result.value.id).to eq("event-1")
    end

    it "accepts ISO 8601 timestamps with an explicit UTC offset" do
      result = described_class.build(valid_event.merge(timestamp: "2026-09-01T11:00:00+01:00"))

      expect(result).to be_success
    end

    it "rejects a non-hash event" do
      result = described_class.build("not-a-hash")

      expect(result).to be_failure
      expect(result.errors).to eq(["event must be a Hash"])
    end

    it "reports missing required fields" do
      raw = valid_event.reject { |key, _| %i[id type].include?(key) }

      result = described_class.build(raw)

      expect(result).to be_failure
      expect(result.errors).to contain_exactly("id is missing", "type is missing")
    end

    it "rejects a blank id" do
      result = described_class.build(valid_event.merge(id: "  "))

      expect(result.errors).to include("id must be a non-empty String")
    end

    it "rejects a non-string type" do
      result = described_class.build(valid_event.merge(type: 123))

      expect(result.errors).to include("type must be a non-empty String")
    end

    it "rejects a non-string timestamp" do
      result = described_class.build(valid_event.merge(timestamp: Time.now))

      expect(result.errors).to include("timestamp must be a String")
    end

    it "rejects an invalid ISO 8601 timestamp" do
      result = described_class.build(valid_event.merge(timestamp: "not-a-date"))

      expect(result).to be_failure
      expect(result.errors.first).to include("ISO 8601")
    end

    it "rejects an ISO 8601 timestamp without an explicit timezone" do
      result = described_class.build(valid_event.merge(timestamp: "2026-09-01T10:00:00"))

      expect(result).to be_failure
      expect(result.errors.first).to include("explicit timezone")
    end

    it "rejects a numeric string rather than coercing it" do
      result = described_class.build(valid_event.merge(value: "20"))

      expect(result.errors).to include("value must be numeric")
    end

    it "rejects non-finite numeric values" do
      result = described_class.build(valid_event.merge(value: Float::NAN))

      expect(result.errors).to include("value must be numeric")
    end
  end
end
