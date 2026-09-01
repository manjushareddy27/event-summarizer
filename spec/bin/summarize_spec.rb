# frozen_string_literal: true

require "json"
require "open3"
require "rbconfig"
require "tempfile"
require "spec_helper"

RSpec.describe "bin/summarize" do
  let(:script) { File.expand_path("../../bin/summarize", __dir__) }

  def run_cli(*args)
    Open3.capture3(RbConfig.ruby, script, *args)
  end

  it "prints an assessment-shaped JSON summary for a valid file" do
    Tempfile.create(["events", ".json"]) do |file|
      file.write(
        JSON.generate(
          [
            { id: "1", timestamp: "2026-09-01T10:00:00Z", type: "click", value: 10 },
            { id: "2", timestamp: "2026-09-01T10:05:00Z", type: "click", value: 20 }
          ]
        )
      )
      file.flush

      stdout, stderr, status = run_cli(file.path)

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(JSON.parse(stdout)).to eq(
        "total" => 2,
        "type" => {
          "click" => { "count" => 2, "aggregate" => 30 }
        }
      )
    end
  end

  it "returns a useful error when the file argument is missing" do
    _stdout, stderr, status = run_cli

    expect(status).not_to be_success
    expect(stderr).to include("Usage: bin/summarize <events.json>")
  end

  it "returns a useful error when the file does not exist" do
    _stdout, stderr, status = run_cli("does-not-exist.json")

    expect(status).not_to be_success
    expect(stderr).to include("File not found: does-not-exist.json")
  end

  it "returns a useful error for malformed JSON" do
    Tempfile.create(["events", ".json"]) do |file|
      file.write("{not-json")
      file.flush

      _stdout, stderr, status = run_cli(file.path)

      expect(status).not_to be_success
      expect(stderr).to include("Invalid JSON:")
    end
  end
end
