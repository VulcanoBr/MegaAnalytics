class CreateImportBatches < ActiveRecord::Migration[8.1]
  def change
    create_table :import_batches do |t|
      t.string :file_name, null: false
      t.string :file_sha256
      t.string :status, null: false, default: "pending"
      t.integer :total_rows, null: false, default: 0
      t.integer :inserted_rows, null: false, default: 0
      t.integer :updated_rows, null: false, default: 0
      t.integer :skipped_rows, null: false, default: 0
      t.integer :error_rows, null: false, default: 0
      t.jsonb :error_details, null: false, default: []
      t.jsonb :validation_report, null: false, default: {}
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end

    add_index :import_batches, :file_sha256
    add_index :import_batches, :status
  end
end
