require 'rails_helper'

RSpec.describe 'create_table_range_partition procedure' do
  after do
    DBTest::DropTablePartitions.drop('refresh_tokens')
  end

  it 'returns partition name for MINUTE INTERVAL' do
    table_name = 'refresh_tokens'
    interval = '15 MINUTE'
    from = '2024-02-23 09:00:00 UTC'.to_datetime
    to = '2024-02-23 10:00:00 UTC'.to_datetime

    sql = <<~SQL
      CALL create_table_range_partition('#{table_name}'::TEXT,
                                        '#{interval}'::TEXT,
                                        '#{from}'::TIMESTAMP,
                                        '#{to}'::TIMESTAMP)
    SQL

    sql_select_partitions = <<~SQL
      SELECT inhrelid::regclass AS child
      FROM   pg_catalog.pg_inherits
      WHERE  inhparent = '#{table_name}'::regclass
    SQL

    create_partition = -> { ActiveRecord::Base.connection.execute(sql) }

    partitions = -> { ActiveRecord::Base.connection.execute(sql_select_partitions).to_a.map { |el| el['child'] } }

    res = ['refresh_tokens_p20240223_090000',
           'refresh_tokens_p20240223_091500',
           'refresh_tokens_p20240223_093000',
           'refresh_tokens_p20240223_094500',
           'refresh_tokens_p20240223_100000']

    expect { create_partition.call }.to change { partitions.call.sort }.from([]).to(res.sort)
  end
end
