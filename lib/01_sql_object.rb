require_relative 'db_connection'
require 'active_support/inflector'

# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    return @columns if @columns
    columns = DBConnection.execute2(<<-SQL)
    SELECT
    *
    FROM
      #{self.table_name}
    SQL

    @columns = columns.first.map { |header| header.to_sym }
  end

  def self.finalize!
    columns.each do |name| 
      define_method("#{name}=") do |value|
        attributes[name] = value
      end

      define_method("#{name}") do
        attributes[name]
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
    SELECT
    *
    FROM
      #{self.table_name}
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    output = []

    results.each do |result|
      output << self.new(result)
    end

    output
  end

  def self.find(id)
    output = DBConnection.execute(<<-SQL, id)
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      id = ?
    SQL

    self.new(output.first)
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      raise "unknown attribute '#{attr_name}'" unless self.class.columns.include?(attr_name)

      self.send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |column| 
      self.send(:attributes)[column]
    end
  end

  def insert
    col_names = self.class.columns.join(", ")
    question_marks = (["?"] * self.class.columns.count).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO 
      #{self.class.table_name}
    VALUES
      (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    question_marks = (["?"] * (self.class.columns.count)).join(", ")

    set_line = self.class.columns.map do |column|
      "#{column} = ?"
    end.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values, self.id)
    UPDATE
      #{self.class.table_name}
    SET
      #{set_line}
    WHERE
      id = ?
    SQL
  end

  def save
    if self.attribute_values.include?(self.id) & self.id
      update
    else
      insert
    end 
  end
end
