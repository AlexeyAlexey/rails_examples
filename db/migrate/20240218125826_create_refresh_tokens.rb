class CreateRefreshTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :refresh_tokens, id: false do |t|
      t.uuid :user_id, null: false

      t.string :token, null: false
      t.string :device, null: false
      t.string :action, null: false
      t.string :reason

      t.datetime :expire_at, null: false

      t.timestamps
    end

    add_index(:refresh_tokens, [:device, :user_id, :created_at], order: { created_at: :desc })
  end
end
