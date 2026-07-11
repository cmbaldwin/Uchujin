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

ActiveRecord::Schema[8.1].define(version: 2026_07_11_000001) do
  create_table "uchujin_check_ins", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "expected_every_seconds"
    t.datetime "last_seen_at"
    t.json "metadata", default: {}
    t.string "name", null: false
    t.integer "ping_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index [ "name" ], name: "index_uchujin_check_ins_on_name", unique: true
  end

  create_table "uchujin_comments", force: :cascade do |t|
    t.bigint "author_id"
    t.string "author_name"
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "fault_id", null: false
    t.datetime "updated_at", null: false
    t.index [ "fault_id" ], name: "index_uchujin_comments_on_fault_id"
  end

  create_table "uchujin_deployments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deployed_at", null: false
    t.string "environment", null: false
    t.json "metadata", default: {}
    t.string "repository"
    t.string "sha", null: false
    t.datetime "updated_at", null: false
    t.string "user"
    t.index [ "environment", "deployed_at" ], name: "index_uchujin_deployments_on_environment_and_deployed_at"
  end

  create_table "uchujin_faults", force: :cascade do |t|
    t.bigint "assignee_id"
    t.string "class_name", null: false
    t.string "component", default: "web", null: false
    t.datetime "created_at", null: false
    t.string "environment", null: false
    t.string "fingerprint", null: false
    t.datetime "first_seen_at"
    t.datetime "last_notified_at"
    t.datetime "last_seen_at"
    t.text "message"
    t.integer "occurrences_count", default: 0, null: false
    t.datetime "resolved_at"
    t.string "revision"
    t.json "sample_context", default: {}
    t.string "status", default: "unresolved", null: false
    t.json "tags", default: []
    t.datetime "updated_at", null: false
    t.index [ "class_name" ], name: "index_uchujin_faults_on_class_name"
    t.index [ "component" ], name: "index_uchujin_faults_on_component"
    t.index [ "environment" ], name: "index_uchujin_faults_on_environment"
    t.index [ "fingerprint" ], name: "index_uchujin_faults_on_fingerprint", unique: true
    t.index [ "last_seen_at" ], name: "index_uchujin_faults_on_last_seen_at"
    t.index [ "status" ], name: "index_uchujin_faults_on_status"
  end

  create_table "uchujin_notifications", force: :cascade do |t|
    t.string "channel", null: false
    t.datetime "created_at", null: false
    t.integer "fault_id"
    t.json "payload", default: {}
    t.datetime "sent_at"
    t.string "status", default: "sent"
    t.datetime "updated_at", null: false
    t.index [ "fault_id" ], name: "index_uchujin_notifications_on_fault_id"
  end

  create_table "uchujin_occurrences", force: :cascade do |t|
    t.json "backtrace", default: []
    t.json "backtrace_app", default: []
    t.json "breadcrumbs", default: []
    t.json "cause"
    t.json "client_info", default: {}
    t.string "component"
    t.json "context", default: {}
    t.datetime "created_at", null: false
    t.string "environment"
    t.integer "fault_id", null: false
    t.text "message"
    t.datetime "occurred_at", null: false
    t.json "params", default: {}
    t.json "request_metadata", default: {}
    t.string "revision"
    t.json "server_stats", default: {}
    t.json "source_context_lines", default: []
    t.datetime "updated_at", null: false
    t.index [ "fault_id" ], name: "index_uchujin_occurrences_on_fault_id"
    t.index [ "occurred_at" ], name: "index_uchujin_occurrences_on_occurred_at"
  end

  create_table "uchujin_uptime_checks", force: :cascade do |t|
    t.datetime "checked_at", null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.integer "response_time_ms"
    t.string "status", default: "unknown", null: false
    t.integer "status_code"
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index [ "url", "checked_at" ], name: "index_uchujin_uptime_checks_on_url_and_checked_at"
  end

  add_foreign_key "uchujin_comments", "uchujin_faults", column: "fault_id"
  add_foreign_key "uchujin_notifications", "uchujin_faults", column: "fault_id"
  add_foreign_key "uchujin_occurrences", "uchujin_faults", column: "fault_id"
end
