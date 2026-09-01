# frozen_string_literal: true

module EventSummarizer
  IngestionReport = Data.define(:accepted, :rejected, :duplicates) do
    def accepted_count
      accepted.size
    end

    def rejected_count
      rejected.size
    end

    def duplicate_count
      duplicates.size
    end

    def total_seen
      accepted_count + rejected_count + duplicate_count
    end
  end
end
