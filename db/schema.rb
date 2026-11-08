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

ActiveRecord::Schema[8.1].define(version: 2026_11_04_000002) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "draws", force: :cascade do |t|
    t.integer "contest_number", null: false
    t.date "draw_date", null: false
    t.integer "number_1", null: false
    t.integer "number_2", null: false
    t.integer "number_3", null: false
    t.integer "number_4", null: false
    t.integer "number_5", null: false
    t.integer "number_6", null: false
    t.integer "winners_sena"
    t.decimal "prize_sena", precision: 15, scale: 2
    t.integer "winners_quina"
    t.decimal "prize_quina", precision: 15, scale: 2
    t.integer "winners_quadra"
    t.decimal "prize_quadra", precision: 15, scale: 2
    t.string "city_uf"
    t.decimal "accumulated_sena", precision: 15, scale: 2
    t.decimal "total_revenue", precision: 15, scale: 2
    t.decimal "estimated_prize", precision: 15, scale: 2
    t.decimal "special_draw_accumulated", precision: 15, scale: 2
    t.text "observation"
    t.jsonb "source_metadata", default: {}, null: false
    t.bigint "import_batch_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contest_number"], name: "index_draws_on_contest_number", unique: true
    t.index ["draw_date"], name: "index_draws_on_draw_date"
    t.index ["import_batch_id"], name: "index_draws_on_import_batch_id"
    t.index ["total_revenue"], name: "index_draws_on_total_revenue"
    t.check_constraint "contest_number > 0", name: "draws_contest_number_positive"
    t.check_constraint "number_1 <> number_2 AND number_1 <> number_3 AND number_1 <> number_4 AND number_1 <> number_5 AND number_1 <> number_6 AND number_2 <> number_3 AND number_2 <> number_4 AND number_2 <> number_5 AND number_2 <> number_6 AND number_3 <> number_4 AND number_3 <> number_5 AND number_3 <> number_6 AND number_4 <> number_5 AND number_4 <> number_6 AND number_5 <> number_6", name: "draws_numbers_are_distinct"
    t.check_constraint "number_1 >= 1 AND number_1 <= 60", name: "draws_number_1_valid"
    t.check_constraint "number_2 >= 1 AND number_2 <= 60", name: "draws_number_2_valid"
    t.check_constraint "number_3 >= 1 AND number_3 <= 60", name: "draws_number_3_valid"
    t.check_constraint "number_4 >= 1 AND number_4 <= 60", name: "draws_number_4_valid"
    t.check_constraint "number_5 >= 1 AND number_5 <= 60", name: "draws_number_5_valid"
    t.check_constraint "number_6 >= 1 AND number_6 <= 60", name: "draws_number_6_valid"
  end

  create_table "import_batches", force: :cascade do |t|
    t.string "file_name", null: false
    t.string "file_sha256"
    t.string "status", default: "pending", null: false
    t.integer "total_rows", default: 0, null: false
    t.integer "inserted_rows", default: 0, null: false
    t.integer "updated_rows", default: 0, null: false
    t.integer "skipped_rows", default: 0, null: false
    t.integer "error_rows", default: 0, null: false
    t.jsonb "error_details", default: [], null: false
    t.jsonb "validation_report", default: {}, null: false
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["file_sha256"], name: "index_import_batches_on_file_sha256"
    t.index ["status"], name: "index_import_batches_on_status"
  end

  add_foreign_key "draws", "import_batches"
end
