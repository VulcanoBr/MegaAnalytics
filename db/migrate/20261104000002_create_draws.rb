class CreateDraws < ActiveRecord::Migration[8.1]
  def change
    create_table :draws do |t|
      t.integer :contest_number, null: false
      t.date :draw_date, null: false
      (1..6).each { |n| t.integer :"number_#{n}", null: false }

      t.integer :winners_sena
      t.decimal :prize_sena, precision: 15, scale: 2
      t.integer :winners_quina
      t.decimal :prize_quina, precision: 15, scale: 2
      t.integer :winners_quadra
      t.decimal :prize_quadra, precision: 15, scale: 2

      t.string :city_uf
      t.decimal :accumulated_sena, precision: 15, scale: 2
      t.decimal :total_revenue, precision: 15, scale: 2
      t.decimal :estimated_prize, precision: 15, scale: 2
      t.decimal :special_draw_accumulated, precision: 15, scale: 2
      t.text :observation

      t.jsonb :source_metadata, null: false, default: {}
      t.bigint :import_batch_id

      t.timestamps

      t.index :contest_number, unique: true
      t.index :draw_date
      t.index :import_batch_id
      t.index :total_revenue

      t.check_constraint "contest_number > 0", name: "draws_contest_number_positive"

      distinct = (1..6).to_a.combination(2).map { |a, b| "number_#{a} <> number_#{b}" }.join(" AND ")
      t.check_constraint distinct, name: "draws_numbers_are_distinct"

      (1..6).each do |n|
        t.check_constraint "number_#{n} >= 1 AND number_#{n} <= 60", name: "draws_number_#{n}_valid"
      end
    end

    add_foreign_key :draws, :import_batches
  end
end
