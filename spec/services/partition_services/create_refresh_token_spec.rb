require 'rails_helper'

RSpec.describe ::PartitionServices::CreateRefreshToken do
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

      partitions = -> { ActiveRecord::Base.connection.execute(sql_select_partitions).to_a.map { |el| el['child'] } }

      res = ['refresh_tokens_p20240223_090000',
             'refresh_tokens_p20240223_091500',
             'refresh_tokens_p20240223_093000',
             'refresh_tokens_p20240223_094500',
             'refresh_tokens_p20240223_100000']

      expect { described_class.call(from:, to:, interval:) }.to change { partitions.call.sort }.from([]).to(res.sort)
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
      to = '2024-02-23 10:15:00 UTC'.to_datetime

      partitions = -> { ActiveRecord::Base.connection.execute(sql_select_partitions).to_a.map { |el| el['child'] } }

      res = ['refresh_tokens_p20240223_090000',
             'refresh_tokens_p20240223_100000']

      expect { described_class.call(from:, to:, interval:) }.to change { partitions.call.sort }.from([]).to(res.sort)
    end
  end

  describe 'indexes' do
    after do
      DBTest::DropTablePartitions.drop('refresh_tokens')
    end

    let(:sql_select_partitions_indexes) do
      <<~SQL
        SELECT tablename, indexname, indexdef
        FROM pg_indexes
        WHERE tablename = 'refresh_tokens_p20240223_090000';
      SQL
    end

    it 'creates user_id, created_at DESC index' do
      interval = '1 HOUR'
      from = '2024-02-23 09:01:00 UTC'.to_datetime
      to = '2024-02-23 10:15:00 UTC'.to_datetime

      indexname = 'inx_refresh_tokens_on_dev_usr_id_created_at_p20240223_090000'
      tablename = 'refresh_tokens_p20240223_090000'

      indexdef = "CREATE INDEX #{indexname} ON public.#{tablename} USING btree (user_id, created_at DESC)"

      described_class.call(from:, to:, interval:)

      res = ActiveRecord::Base.connection.execute(sql_select_partitions_indexes).to_a.first

      expect(res['indexname']).to eq(indexname)
      expect(res['indexdef']).to eq(indexdef)
    end
  end
end
