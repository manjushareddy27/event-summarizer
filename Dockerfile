FROM ruby:3.4.10-slim

WORKDIR /app

COPY Gemfile ./
RUN bundle install

COPY . .

CMD ["bundle", "exec", "rspec"]
