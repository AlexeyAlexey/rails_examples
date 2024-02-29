class CreateRefreshTokensTableRangePartitionProc < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE OR REPLACE PROCEDURE create_refresh_tokens_table_range_partition(IN p_partition_interval TEXT,
                                                                              IN p_from TIMESTAMP,
                                                                              IN p_to TIMESTAMP) AS $$
        DECLARE
          partition_time TIMESTAMP;
          table_range_partition_name TEXT;
          index_name TEXT;
          interval_name TEXT;
        BEGIN
          SELECT UPPER(SUBSTRING(p_partition_interval, '[a-zA-Z]+')) INTO interval_name;

          FOR partition_time IN SELECT generate_series(DATE_TRUNC(interval_name, p_from),
                                                       DATE_TRUNC(interval_name, p_to),
                                                       p_partition_interval::INTERVAL)::TIMESTAMP
          LOOP
            table_range_partition_name := get_table_range_partition_name('refresh_tokens',
                                                                         p_partition_interval,
                                                                         partition_time);

            CALL create_table_range_partition('refresh_tokens',
                                              p_partition_interval,
                                              partition_time,
                                              partition_time);

            index_name := get_table_range_partition_name('inx_refresh_tokens_on_dev_usr_id_created_at',
                                                         interval_name::TEXT,
                                                         partition_time);
            -- maximum name length is 63 characters
            -- To create an index without locking out writes to the table
            -- CREATE INDEX CONCURRENTLY cannot be executed from a function
            EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %I USING BTREE (user_id, created_at DESC)',
                            index_name,
                            table_range_partition_name);
          END LOOP;
        END;
      $$ LANGUAGE 'plpgsql';
    SQL
  end

  def down
    execute <<~SQL
      DROP PROCEDURE IF EXISTS create_refresh_tokens_table_range_partition(TEXT, TIMESTAMP, TIMESTAMP);
    SQL
  end
end
