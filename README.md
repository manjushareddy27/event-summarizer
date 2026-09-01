# Event Summarizer

A Ruby application for validating, ingesting and summarising a collection of events. The public summary deliberately matches the assessment shape while ingestion diagnostics remain available separately.

## Requirements

- Ruby 3.4.x
- Bundler
- Docker (optional)

The repository includes `.ruby-version` with Ruby `3.4.10`.

## Setup

```bash
bundle install
```

Run the full test suite:

```bash
bundle exec rspec
```

SimpleCov starts with RSpec and writes its HTML report to:

```text
coverage/index.html
```

Coverage is used as a feedback mechanism rather than a substitute for meaningful behavioural tests.

## Running the application

A sample input file is included at:

```text
examples/events.json
```

Run it with:

```bash
ruby bin/summarize examples/events.json
```

The script is executable as well:

```bash
./bin/summarize examples/events.json
```

Example output:

```json
{
  "total": 3,
  "type": {
    "click": {
      "count": 2,
      "aggregate": 50
    },
    "purchase": {
      "count": 1,
      "aggregate": 100
    }
  }
}
```

The same library can be called directly from Ruby:

```ruby
require_relative "lib/event_summarizer"

events = [
  {
    id: "event-1",
    timestamp: "2026-09-01T10:00:00Z",
    type: "click",
    value: 20
  }
]

EventSummarizer.summarize(events)
```

### `Result`

Malformed individual events are expected external-data outcomes, so validation failures are represented as data rather than rescue-driven control flow:

```ruby
result.success?
result.failure?
result.value
result.errors
```

The `Result` container itself is frozen. Domain values are responsible for enforcing their own immutability; `Result` deliberately does not freeze arbitrary objects supplied by callers.

## Docker

Build the image:

```bash
docker build -t event-summarizer .
```

Run the tests in Docker:

```bash
docker run --rm event-summarizer
```

The Docker setup is intentionally small because the application has no database or external service dependencies.

## Scale and production considerations

The current API accepts an in-memory Array, so memory usage grows with input size. An arbitrary event-count cap is not introduced because the requirements define no business limit.

For high-volume processing I would change the ingestion boundary to consume a stream or batches and use durable persistence rather than load an entire dataset into one process.

A possible AWS architecture could be:

```text
API Gateway / SQS / S3
          |
          v
      AWS Lambda
          |
          v
   Event Processing
          |
          v
       DynamoDB
```

DynamoDB conditional writes could provide durable idempotency for event IDs, while SQS could provide buffering, retries and asynchronous processing. The `Event` and `Aggregator` domain logic would remain independent of AWS infrastructure.

For a network-facing production API I would additionally apply request-size limits, rate limiting, JSON parsing limits, observability and service-specific security controls at the boundary.

## Key decisions

The solution deliberately:

- separates raw-input handling from aggregation
- treats malformed individual events as expected data rather than exceptions
- keeps invalid application calls as exceptions
- requires timezone-explicit timestamps
- makes duplicate handling explicit and observable
- avoids silently coercing invalid input types
- keeps infrastructure concerns outside the domain logic
- uses SimpleCov as supporting feedback rather than a target metric
