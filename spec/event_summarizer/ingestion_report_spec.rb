# frozen_string_literal: true

require "spec_helper"
require_relative "../../lib/event_summarizer/ingestion_report"

RSpec.describe EventSummarizer::IngestionReport do
  it "reports accepted, rejected, duplicate and total counts" do
    report = described_class.new(
      accepted: %i[a b],
      rejected: [:c],
      duplicates: %i[d e]
    )

    expect(report.accepted_count).to eq(2)
    expect(report.rejected_count).to eq(1)
    expect(report.duplicate_count).to eq(2)
    expect(report.total_seen).to eq(5)
  end
end
