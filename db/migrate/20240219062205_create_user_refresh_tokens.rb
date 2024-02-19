class CreateUserRefreshTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :user_refresh_tokens, id: false do |t|
      t.uuid :user_id, null: false

      # https://www.postgresql.org/docs/15/hash-intro.html
      # Hash indexes support only single-column indexes and do not allow uniqueness checking
      # You can use btree index to use uniqueness checking
      t.string :token, null: false, index: { using: 'hash' }
      t.string :device, null: false, index: { using: 'hash' }
      # t.string :refresh_token_group_id, null: false

      t.timestamps
    end
  end
end
