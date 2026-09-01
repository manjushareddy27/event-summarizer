# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/event_summarizer/result"

RSpec.describe EventSummarizer::Result do
  describe ".success" do
    it "returns a successful result containing the value" do
      result = described_class.success("value")

      expect(result).to be_success
      expect(result).not_to be_failure
      expect(result.value).to eq("value")
      expect(result.errors).to be_empty
    end
  end

  describe ".failure" do
    it "returns a failed result with normalized errors" do
      result = described_class.failure("invalid event")

      expect(result).to be_failure
      expect(result).not_to be_success
      expect(result.value).to be_nil
      expect(result.errors).to eq(["invalid event"])
    end
  end
end
