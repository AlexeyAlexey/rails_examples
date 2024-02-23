class CreateTableRangePartitionProcedure < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE OR REPLACE PROCEDURE create_table_range_partition(IN table_name TEXT,
                                                               IN p_partition_interval TEXT,
                                                               IN p_from TIMESTAMP,
                                                               IN p_to TIMESTAMP) AS $$
            DECLARE
              partition_interval INTERVAL;
              table_range_partition_name TEXT;
              partition_time TIMESTAMP;
            BEGIN

              SELECT CAST(p_partition_interval AS INTERVAL) INTO partition_interval;


              FOR partition_time IN SELECT generate_series(p_from, p_to, partition_interval)::TIMESTAMP LOOP

               table_range_partition_name := get_table_range_partition_name(table_name,
                                                                            p_partition_interval,
                                                                            partition_time);

               EXECUTE format('CREATE TABLE IF NOT EXISTS %I PARTITION OF %I
                               FOR VALUES FROM (%L) TO (%L);',
                               table_range_partition_name,
                               table_name,
                               partition_time,
                               partition_time + partition_interval);
             END LOOP;


            END;
      $$ LANGUAGE 'plpgsql';
    SQL
  end

  def down
    execute <<~SQL
      DROP PROCEDURE IF EXISTS create_table_range_partition(TEXT, TEXT, TIMESTAMP, TIMESTAMP);
    SQL
  end
end
