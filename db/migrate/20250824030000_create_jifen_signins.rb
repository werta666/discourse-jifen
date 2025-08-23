# frozen_string_literal: true

class CreateJifenSignins < ActiveRecord::Migration[6.1]
  def change
    create_table :jifen_signins do |t|
      t.integer :user_id, null: false
      t.date :date, null: false
      t.datetime :signed_at, null: false
      t.boolean :makeup, null: false, default: false
      t.integer :points, null: false, default: 0
      t.integer :streak_count, null: false, default: 1
      t.timestamps null: false
    end

    add_index :jifen_signins, [:user_id, :date], unique: true, name: "idx_jifen_signins_uid_date"
    add_index :jifen_signins, [:user_id, :created_at], name: "idx_jifen_signins_uid_created"
  end
end