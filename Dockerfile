FROM ruby:3.3.1-alpine
RUN apk add --no-cache build-base libxml2-dev libxslt-dev tzdata postgresql-dev postgresql-client
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN gem install bundler -v 2.5.9
RUN bundle install
COPY . .
EXPOSE 3000
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
