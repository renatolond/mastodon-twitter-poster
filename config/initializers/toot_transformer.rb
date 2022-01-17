# frozen_string_literal: true

require_relative "../../app/objects/toot_transformer"

# These values are constants on Twitter's side and used
# to come from an endpoint for configuration. It is no
# longer the case (https://twittercommunity.com/t/retiring-the-1-1-configuration-endpoint/153319)
# if those values change, they need to be changed here.
TootTransformer.twitter_short_url_length = 23
TootTransformer.twitter_short_url_length_https = 23
