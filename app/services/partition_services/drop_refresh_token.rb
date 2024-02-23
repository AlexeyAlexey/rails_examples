module PartitionServices
  class DropRefreshToken
    prepend ::ApplicationService

    def initialize(from:, to:, interval:)
      @from = from.to_datetime.utc
      @to = to.to_datetime.utc
      @interval = interval
    end

    def call
      ActiveRecord::Base.connection.execute(sql)
    end

    private

    attr_reader :from, :to, :interval

    def sql
      <<~SQL
        DO $$
          DECLARE
            partition_time TIMESTAMP;
            table_range_partition_name TEXT;
          BEGIN
            FOR partition_time IN SELECT generate_series(DATE_TRUNC('#{interval_name}', TIMESTAMP '#{from}')::TIMESTAMP,
                                                         DATE_TRUNC('#{interval_name}', TIMESTAMP '#{to}')::TIMESTAMP,
                                                         '#{interval}'::interval)::TIMESTAMP
            LOOP
              table_range_partition_name := get_table_range_partition_name('refresh_tokens',
                                                                           '#{interval}'::TEXT,
                                                                           partition_time);

              EXECUTE format('DROP TABLE %I;', table_range_partition_name);

            END LOOP;
          END;
        $$;
      SQL
    end

    def interval_name
      @interval_name ||= interval.gsub(/\s+/, ' ').split(' ').last
    end
  end
end
