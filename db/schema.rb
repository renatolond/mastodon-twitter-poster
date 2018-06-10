# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180503110516) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"


  create_enum "boost_options", "MASTO_BOOST_DO_NOT_POST", "MASTO_BOOST_POST_AS_LINK"
  create_enum "masto_mention_options", "MASTO_MENTION_DO_NOT_POST"
  create_enum "masto_reply_options", "MASTO_REPLY_DO_NOT_POST", "MASTO_REPLY_POST_SELF"
  create_enum "masto_visibility", "MASTO_PUBLIC", "MASTO_UNLISTED", "MASTO_PRIVATE"
  create_enum "quote_options", "QUOTE_DO_NOT_POST", "QUOTE_POST_AS_LINK", "QUOTE_POST_AS_OLD_RT", "QUOTE_POST_AS_OLD_RT_WITH_LINK"
  create_enum "retweet_options", "RETWEET_DO_NOT_POST", "RETWEET_POST_AS_LINK", "RETWEET_POST_AS_OLD_RT", "RETWEET_POST_AS_OLD_RT_WITH_LINK"
  create_enum "twitter_reply_options", "TWITTER_REPLY_DO_NOT_POST", "TWITTER_REPLY_POST_SELF"
  create_table "authorizations", force: :cascade do |t|
    t.string   "provider"
    t.string   "uid"
    t.integer  "user_id"
    t.string   "token"
    t.string   "secret"
    t.datetime "created_at",         :null=>false
    t.datetime "updated_at",         :null=>false
    t.bigint   "mastodon_client_id"

    t.index ["mastodon_client_id"], :name=>"index_authorizations_on_mastodon_client_id"
    t.index ["provider", "uid"], :name=>"index_authorizations_on_provider_and_uid", :unique=>true
  end

  create_table "mastodon_clients", id: :serial, default: %q{nextval('mastodon_clients_id_seq'::regclass)}, force: :cascade do |t|
    t.string   "domain"
    t.string   "client_id"
    t.string   "client_secret"
    t.datetime "created_at",    :null=>false
    t.datetime "updated_at",    :null=>false

    t.index ["domain"], :name=>"index_mastodon_clients_on_domain", :unique=>true
  end

  create_table "statuses", force: :cascade do |t|
    t.bigint   "mastodon_client_id", :null=>false
    t.bigint   "masto_id",           :null=>false
    t.bigint   "tweet_id",           :null=>false
    t.datetime "created_at",         :null=>false
    t.datetime "updated_at",         :null=>false

    t.index ["mastodon_client_id", "masto_id"], :name=>"index_statuses_on_mastodon_client_id_and_masto_id", :unique=>true
    t.index ["mastodon_client_id"], :name=>"index_statuses_on_mastodon_client_id"
    t.index ["tweet_id"], :name=>"index_statuses_on_tweet_id", :unique=>true
  end

# Could not dump table "users" because of following StandardError
#   Unknown type 'boost_options' for column 'boost_options'


  add_foreign_key "authorizations", "mastodon_clients"
  add_foreign_key "statuses", "mastodon_clients"
end
