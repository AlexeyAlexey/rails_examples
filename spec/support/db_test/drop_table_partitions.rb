module DBTest
  module DropTablePartitions
    def self.drop(table_name)
      sql_select_partitions = <<~SQL
        SELECT inhrelid::regclass AS child
        FROM   pg_catalog.pg_inherits
        WHERE  inhparent = '#{table_name}'::regclass
      SQL

      partitions = ActiveRecord::Base.connection.execute(sql_select_partitions).to_a.map { |el| el['child'] }

      sql_delete_partitions = ""

      partitions.each do |partition_name|
        sql_delete_partitions += " DROP TABLE #{partition_name};"
      end

      ActiveRecord::Base.connection.execute(sql_delete_partitions)
    end
  end
end
