module PartitionServices
  class CreateRefreshToken
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
      # CALL create_table_range_partition('refresh_tokens',
      #                                   '#{interval}'::TEXT,
      #                                   DATE_TRUNC('#{interval_name}', TIMESTAMP '#{from}'),
      #                                   DATE_TRUNC('#{interval_name}', TIMESTAMP '#{to}'));
      <<~SQL
        CALL create_refresh_tokens_table_range_partition('#{interval}'::TEXT,
                                                         DATE_TRUNC('#{interval_name}', '#{from}'::TIMESTAMP),
                                                         DATE_TRUNC('#{interval_name}', '#{to}'::TIMESTAMP));
      SQL
    end

    def interval_name
      @interval_name ||= interval.gsub(/\s+/, ' ').split(' ').last
    end
  end
end
