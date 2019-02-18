FROM ruby:2.3.1-alpine

RUN apk add --update \
  build-base \
  bash \
  libxml2-dev \
  libxslt-dev \
  && rm -rf /var/cache/apk/*

RUN bundle config build.nokogiri --use-system-libraries
COPY Gemfile .
COPY Gemfile.lock .
RUN bundle install
RUN apk del build-base && \
  rm -rf /var/cache/apk/*
COPY docker_http_test.rb .
COPY http_blackbox_test_case.rb .
RUN chmod +x docker_http_test.rb
ENTRYPOINT ["./docker_http_test.rb"]