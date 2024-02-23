require 'rails_helper'

RSpec.describe ::PartitionServices::DropRefreshToken do
  describe 'when MINUTE interval' do
    after do
      DBTest::DropTablePartitions.drop('refresh_tokens')
    end

    let(:sql_select_partitions) do
      <<~SQL
        SELECT inhrelid::regclass AS child
        FROM   pg_catalog.pg_inherits
        WHERE  inhparent = 'refresh_tokens'::regclass
      SQL
    end

    it 'returns partition name for MINUTE INTERVAL' do
      interval = '15 MINUTE'
      from = '2024-02-23 09:00:10 UTC'.to_datetime
      to = '2024-02-23 10:00:15 UTC'.to_datetime

      drop_from = '2024-02-23 09:15:10 UTC'.to_datetime
      drop_to = '2024-02-23 09:30:10 UTC'.to_datetime

      ::PartitionServices::CreateRefreshToken.call(from:, to:, interval:)

      partitions = -> { ActiveRecord::Base.connection.execute(sql_select_partitions).to_a.map { |el| el['child'] } }

      before_res = ['refresh_tokens_p20240223_090000',
                    'refresh_tokens_p20240223_091500',
                    'refresh_tokens_p20240223_093000',
                    'refresh_tokens_p20240223_094500',
                    'refresh_tokens_p20240223_100000']

      res = ['refresh_tokens_p20240223_090000',
             'refresh_tokens_p20240223_094500',
             'refresh_tokens_p20240223_100000']

      expect { described_class.call(from: drop_from, to: drop_to, interval:) }
        .to change { partitions.call.sort }.from(before_res.sort).to(res.sort)
    end
  end

  describe 'when HOUR interval' do
    after do
      DBTest::DropTablePartitions.drop('refresh_tokens')
    end

    let(:sql_select_partitions) do
      <<~SQL
        SELECT inhrelid::regclass AS child
        FROM   pg_catalog.pg_inherits
        WHERE  inhparent = 'refresh_tokens'::regclass
      SQL
    end

    it 'returns partition name for HOUR INTERVAL' do
      interval = '1 HOUR'
      from = '2024-02-23 09:01:00 UTC'.to_datetime
      to = '2024-02-23 12:15:00 UTC'.to_datetime

      drop_from = '2024-02-23 10:15:10 UTC'.to_datetime
      drop_to = '2024-02-23 11:30:10 UTC'.to_datetime

      ::PartitionServices::CreateRefreshToken.call(from:, to:, interval:)

      partitions = -> { ActiveRecord::Base.connection.execute(sql_select_partitions).to_a.map { |el| el['child'] } }

      before_res = ['refresh_tokens_p20240223_090000',
                    'refresh_tokens_p20240223_100000',
                    'refresh_tokens_p20240223_110000',
                    'refresh_tokens_p20240223_120000']

      res = ['refresh_tokens_p20240223_090000',
             'refresh_tokens_p20240223_120000']

      expect { described_class.call(from: drop_from, to: drop_to, interval:) }
        .to change { partitions.call.sort }.from(before_res.sort).to(res.sort)
    end
  end
end
