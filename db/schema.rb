# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_21_001119) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activity_logs", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.text "metadata"
    t.text "reason"
    t.bigint "record_id"
    t.string "record_type", null: false
    t.bigint "user_id"
    t.index ["created_at"], name: "index_activity_logs_on_created_at"
    t.index ["record_type", "record_id"], name: "index_activity_logs_on_record"
    t.index ["user_id"], name: "index_activity_logs_on_user_id"
  end

  create_table "affiliations", force: :cascade do |t|
    t.bigint "conference_id", null: false
    t.datetime "created_at", null: false
    t.bigint "league_id", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["conference_id"], name: "index_affiliations_on_conference_id"
    t.index ["league_id", "conference_id", "team_id"], name: "index_affiliations_uniqueness", unique: true
    t.index ["league_id"], name: "index_affiliations_on_league_id"
    t.index ["team_id"], name: "index_affiliations_on_team_id"
  end

  create_table "colors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hex"
    t.string "name"
    t.boolean "primary"
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_colors_on_team_id"
  end

  create_table "conferences", force: :cascade do |t|
    t.string "abbr", null: false
    t.datetime "created_at", null: false
    t.string "display_name", null: false
    t.bigint "league_id", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["league_id", "abbr"], name: "index_conferences_on_league_id_and_abbr", unique: true
    t.index ["league_id", "name"], name: "index_conferences_on_league_id_and_name", unique: true
    t.index ["league_id"], name: "index_conferences_on_league_id"
  end

  create_table "events", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.datetime "created_at", null: false
    t.date "end_date"
    t.date "start_date"
    t.string "title", null: false
    t.datetime "updated_at", null: false
  end

  create_table "games", force: :cascade do |t|
    t.string "away_style"
    t.bigint "away_team_id", null: false
    t.string "broadcast_network"
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.integer "final_prize", default: 0, null: false
    t.text "grid"
    t.string "home_style"
    t.bigint "home_team_id", null: false
    t.bigint "league_id", null: false
    t.integer "period_prize", default: 0, null: false
    t.string "score_url"
    t.datetime "starts_at"
    t.string "status", default: "upcoming", null: false
    t.string "timezone", default: "America/New_York"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["away_team_id"], name: "index_games_on_away_team_id"
    t.index ["event_id"], name: "index_games_on_event_id"
    t.index ["home_team_id"], name: "index_games_on_home_team_id"
    t.index ["league_id"], name: "index_games_on_league_id"
    t.index ["starts_at"], name: "index_games_on_starts_at"
    t.index ["status"], name: "index_games_on_status"
  end

  create_table "leagues", force: :cascade do |t|
    t.string "abbr"
    t.datetime "created_at", null: false
    t.string "gender"
    t.string "level"
    t.string "name"
    t.integer "periods"
    t.boolean "quarters_score_as_halves", default: false, null: false
    t.string "sport"
    t.datetime "updated_at", null: false
  end

  create_table "players", force: :cascade do |t|
    t.boolean "active", default: false, null: false
    t.integer "chances"
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "email", null: false
    t.integer "family_id"
    t.string "name", null: false
    t.string "type", null: false
    t.datetime "updated_at", null: false
  end

  create_table "posts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_posts_on_event_id"
  end

  create_table "scores", force: :cascade do |t|
    t.integer "away"
    t.integer "away_total"
    t.boolean "complete", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "game_id", null: false
    t.integer "home"
    t.integer "home_total"
    t.boolean "non_scoring", default: false
    t.boolean "ot", default: false, null: false
    t.integer "period", null: false
    t.integer "prize"
    t.datetime "updated_at", null: false
    t.bigint "winner_id"
    t.index ["game_id"], name: "index_scores_on_game_id"
    t.index ["winner_id"], name: "index_scores_on_winner_id"
  end

  create_table "styles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "css", null: false
    t.boolean "default", default: false, null: false
    t.string "name", null: false
    t.bigint "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_styles_on_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "abbr"
    t.string "brand_info"
    t.datetime "created_at", null: false
    t.string "display_location"
    t.string "level", default: "", null: false
    t.string "location"
    t.string "name"
    t.datetime "updated_at", null: false
    t.string "womens_name"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activity_logs", "users"
  add_foreign_key "affiliations", "conferences"
  add_foreign_key "affiliations", "leagues"
  add_foreign_key "affiliations", "teams"
  add_foreign_key "colors", "teams"
  add_foreign_key "conferences", "leagues"
  add_foreign_key "games", "events"
  add_foreign_key "games", "leagues"
  add_foreign_key "games", "teams", column: "away_team_id"
  add_foreign_key "games", "teams", column: "home_team_id"
  add_foreign_key "posts", "events"
  add_foreign_key "scores", "games"
  add_foreign_key "scores", "players", column: "winner_id"
  add_foreign_key "styles", "teams"
end
