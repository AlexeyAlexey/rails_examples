class GetTableRangePartitionNameFunction < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION get_table_range_partition_name(table_name TEXT,
                                                                p_interval_name TEXT,
                                                                partition_time TIMESTAMP) RETURNS TEXT AS $$
        DECLARE
          interval_name TEXT;
          p_interval_frmt TEXT;
        BEGIN
          SELECT UPPER(SUBSTRING(p_interval_name, '[a-zA-Z]+')) INTO interval_name;

          CASE
          WHEN interval_name = 'HOUR' OR interval_name = 'HOURS' THEN
            SELECT to_char(partition_time, 'YYYYMMDD_HH24MISS') INTO p_interval_frmt;

            return format('%s_p%s', table_name, p_interval_frmt);
          WHEN interval_name = 'MINUTE' OR interval_name = 'MINUTES' THEN
            SELECT to_char(partition_time, 'YYYYMMDD_HH24MISS') INTO p_interval_frmt;

            return format('%s_p%s', table_name, p_interval_frmt);
          WHEN interval_name = 'SECOND' OR interval_name = 'SECONDS' THEN
            SELECT to_char(partition_time, 'YYYYMMDD_HH24MISS') INTO p_interval_frmt;

            return format('%s_p%s', table_name, p_interval_frmt);
          ELSE
            SELECT to_char(partition_time, 'YYYYMMDD') INTO p_interval_frmt;

            return format('%s_p%s', table_name, p_interval_frmt);
          END CASE;
        END;
      $$ LANGUAGE 'plpgsql';
    SQL
  end

  def down
    execute <<~SQL
      DROP FUNCTION IF EXISTS get_table_range_partition_name(TEXT, TEXT, TIMESTAMP);
    SQL
  end
end
