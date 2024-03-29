require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
  	where_line = params.keys.map { |key| "#{key} = ?" }.join(" AND ")
  	values = params.values


  	output = DBConnection.execute(<<-SQL, *values)
	SELECT
		*
    FROM
     	#{self.table_name}
    WHERE
    	#{where_line}
    SQL

    parse_all(output)
  end
end

class SQLObject
	extend Searchable
end
