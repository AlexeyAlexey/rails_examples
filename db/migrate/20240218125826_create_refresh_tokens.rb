class CreateRefreshTokens < ActiveRecord::Migration[7.1]
  def up
    # create_table :refresh_tokens, id: false do |t|
    #   t.uuid :user_id, null: false

    #   t.string :token, null: false
    #   t.string :device, null: false
    #   t.string :action, null: false
    #   t.string :reason

    #   t.datetime :expire_at, null: false

    #   t.datetime :created_at, null: false
    # end

    execute <<~SQL
      CREATE TABLE refresh_tokens (
        user_id UUID,
        token TEXT,
        device TEXT,
        action TEXT,
        reason TEXT,
        expire_at TIMESTAMP WITHOUT TIME ZONE,
        created_at TIMESTAMP WITHOUT TIME ZONE
      ) PARTITION BY RANGE (created_at);

      -- Do not use the default partition, since it causes additional locking
      DROP TABLE IF EXISTS public.refresh_tokens_default;
    SQL

    # add_index(:refresh_tokens, [:user_id, :created_at], order: { created_at: :desc })
  end

  def down
    drop_table :refresh_tokens
  end
end
