FROM ruby:2.6.1-alpine

COPY Gemfile .
COPY Gemfile.lock .

RUN apk add --update --virtual \
  build-base \
  bash \
  ruby-nokogiri \
  && bundle install \
  && apk del build-base \
  && rm -rf /var/cache/apk/*
COPY docker_http_test.rb .
COPY http_blackbox_executer.rb .
COPY validation_error.rb .
COPY execution_error.rb .
RUN chmod +x docker_http_test.rb
ENTRYPOINT ["./docker_http_test.rb"]
#--deployment -j4 --retry 3 \

