FROM node:12-alpine as node
FROM ruby:3.1.0-alpine

LABEL maintainer="https://github.com/renatolond/mastodon-twitter-poster" \
      description="Crossposter to post statuses between Mastodon and Twitter"

ARG UID=991
ARG GID=991

ENV PATH=/crossposter/bin:$PATH \
    RAILS_SERVE_STATIC_FILES=true \
    RAILS_ENV=production \
    NODE_ENV=production \
    RAILS_LOG_TO_STDOUT=enabled

EXPOSE 3000 4000

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/bin/npm /usr/local/bin/npm
COPY --from=node /opt/yarn-* /opt/yarn

RUN apk add --no-cache -t build-dependencies \
    cmake \
    build-base \
    postgresql-dev \
    postgresql-client \
    python3 \
    file-dev \
    binutils \
    libxml2-dev \
    libidn-dev \
    shared-mime-info \
    ca-certificates \
    git \
    tzdata \
 && update-ca-certificates \
 && ln -s /opt/yarn/bin/yarn /usr/local/bin/yarn \
 && ln -s /opt/yarn/bin/yarnpkg /usr/local/bin/yarnpkg \
 && mkdir -p /opt \
 && gem install bundler:2.3.3 \
 && rm -rf /tmp/*

WORKDIR /crossposter
COPY Gemfile Gemfile.lock package.json yarn.lock .yarnclean /crossposter/

RUN addgroup -g ${GID} crossposter && adduser -h /crossposter -s /bin/sh -D -G crossposter -u ${UID} crossposter \
 && mkdir -p /crossposter/public/system /crossposter/public/assets /crossposter/public/packs \
 && chown -R crossposter:crossposter /crossposter/public

USER crossposter

RUN bundle config set deployment 'true' && bundle config set without 'test development' && bundle config build.nokogiri --with-iconv-lib=/usr/local/lib --with-iconv-include=/usr/local/include && \
    bundle install && \
    yarn install --pure-lockfile --ignore-engines && yarn cache clean

COPY . /crossposter

USER root

RUN chown -R crossposter:crossposter /crossposter

VOLUME /crossposter/public/system

USER crossposter

RUN bundle exec rake assets:precompile \
  TWITTER_CLIENT_SECRET=precompile_placeholder \
  TWITTER_CLIENT_ID=precompile_placeholder \
  SECRET_KEY_BASE=precompile_placeholder \
  CROSSPOSTER_DOMAIN=precompile_placeholder \
  CROSSPOSTER_ADMIN_FEDI_ADDRESS=precompile_placeholder \
  CROSSPOSTER_ADMIN_FEDI_AT=precompile_placeholder

# Start the main process.
CMD ["bundle","exec","puma","-C","config/puma.rb"]
