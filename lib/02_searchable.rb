require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.map { |key, value| "#{key} = ?" }.join(' AND ')
    param_values = params.values
    results = DBConnection.execute(<<-SQL, *param_values)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_line}
    SQL

    results.map { |result| self.new(result) }
  end
end

class SQLObject
  extend Searchable
end
