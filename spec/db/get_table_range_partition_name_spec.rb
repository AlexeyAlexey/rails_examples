require 'rails_helper'

RSpec.describe 'get_table_range_partition_name function' do
  describe "when 'number INTEVAL' format" do
    it 'returns partition name for MINUTE INTERVAL' do
      table_name = 'refresh_tokens'
      interval = '15 MINUTE'
      partition_time = '2024-02-23 09:15:00 UTC'.to_datetime

      sql = <<~SQL
        SELECT get_table_range_partition_name('#{table_name}'::TEXT,
                                              '#{interval}'::TEXT,
                                              '#{partition_time}'::TIMESTAMP);
      SQL

      res = ActiveRecord::Base.connection.execute(sql).to_a.first.fetch('get_table_range_partition_name', nil)

      expect(res).to eq('refresh_tokens_p20240223_091500')
    end

    it 'returns partition name for MINUTES INTERVAL' do
      table_name = 'refresh_tokens'
      interval = '15 MINUTES'
      partition_time = '2024-02-23 09:15:00 UTC'.to_datetime

      sql = <<~SQL
        SELECT get_table_range_partition_name('#{table_name}'::TEXT,
                                              '#{interval}'::TEXT,
                                              '#{partition_time}'::TIMESTAMP);
      SQL

      res = ActiveRecord::Base.connection.execute(sql).to_a.first.fetch('get_table_range_partition_name', nil)

      expect(res).to eq('refresh_tokens_p20240223_091500')
    end

    it 'returns partition name for SECOND INTERVAL' do
      table_name = 'refresh_tokens'
      interval = '15 SECOND'
      partition_time = '2024-02-23 09:15:01 UTC'.to_datetime

      sql = <<~SQL
        SELECT get_table_range_partition_name('#{table_name}'::TEXT,
                                              '#{interval}'::TEXT,
                                              '#{partition_time}'::TIMESTAMP);
      SQL

      res = ActiveRecord::Base.connection.execute(sql).to_a.first.fetch('get_table_range_partition_name', nil)

      expect(res).to eq('refresh_tokens_p20240223_091501')
    end

    it 'returns partition name for HOUR INTERVALS' do
      table_name = 'refresh_tokens'
      interval = '15 HOUR'
      partition_time = '2024-02-23 09:00:00 UTC'.to_datetime

      sql = <<~SQL
        SELECT get_table_range_partition_name('#{table_name}'::TEXT,
                                              '#{interval}'::TEXT,
                                              '#{partition_time}'::TIMESTAMP);
      SQL

      res = ActiveRecord::Base.connection.execute(sql).to_a.first.fetch('get_table_range_partition_name', nil)

      expect(res).to eq('refresh_tokens_p20240223_090000')
    end

    it 'returns partition name for other INTERVALS' do
      table_name = 'refresh_tokens'
      interval = '15 DAY'
      partition_time = '2024-02-23 09:15:01 UTC'.to_datetime

      sql = <<~SQL
        SELECT get_table_range_partition_name('#{table_name}'::TEXT,
                                              '#{interval}'::TEXT,
                                              '#{partition_time}'::TIMESTAMP);
      SQL

      res = ActiveRecord::Base.connection.execute(sql).to_a.first.fetch('get_table_range_partition_name', nil)

      expect(res).to eq('refresh_tokens_p20240223')
    end
  end

  describe "when 'INTEVAL' name format" do
    it 'returns partition name for MINUTE INTERVAL' do
      table_name = 'refresh_tokens'
      interval = 'MINUTE'
      partition_time = '2024-02-23 09:15:00 UTC'.to_datetime

      sql = <<~SQL
        SELECT get_table_range_partition_name('#{table_name}'::TEXT,
                                              '#{interval}'::TEXT,
                                              '#{partition_time}'::TIMESTAMP);
      SQL

      res = ActiveRecord::Base.connection.execute(sql).to_a.first.fetch('get_table_range_partition_name', nil)

      expect(res).to eq('refresh_tokens_p20240223_091500')
    end

    it 'returns partition name for SECOND INTERVAL' do
      table_name = 'refresh_tokens'
      interval = 'SECOND'
      partition_time = '2024-02-23 09:15:01 UTC'.to_datetime

      sql = <<~SQL
        SELECT get_table_range_partition_name('#{table_name}'::TEXT,
                                              '#{interval}'::TEXT,
                                              '#{partition_time}'::TIMESTAMP);
      SQL

      res = ActiveRecord::Base.connection.execute(sql).to_a.first.fetch('get_table_range_partition_name', nil)

      expect(res).to eq('refresh_tokens_p20240223_091501')
    end

    it 'returns partition name for other INTERVALS' do
      table_name = 'refresh_tokens'
      interval = 'DAY'
      partition_time = '2024-02-23 09:15:01 UTC'.to_datetime

      sql = <<~SQL
        SELECT get_table_range_partition_name('#{table_name}'::TEXT,
                                              '#{interval}'::TEXT,
                                              '#{partition_time}'::TIMESTAMP);
      SQL

      res = ActiveRecord::Base.connection.execute(sql).to_a.first.fetch('get_table_range_partition_name', nil)

      expect(res).to eq('refresh_tokens_p20240223')
    end
  end
end
