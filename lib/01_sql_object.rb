require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    results = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
      SQL

    results[0].map { |col| col.to_sym }
  end

  def self.finalize!
    columns.each do |col|
      define_method("#{col}=") do |value|
        self.attributes[col] = value
      end

      define_method("#{col}") do
        self.attributes[col]
      end
    end
  end

  def self.table_name=(table_name)
    instance_variable_set("@table_name", table_name)
  end

  def self.table_name
    @table_name ||= self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    parse_all(results)
  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)
    results = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{table_name}.id = ?
      SQL

    parse_all(results).first
  end

  def initialize(params = {})
    params.each do |attr_name, value|
      unless self.class.columns.include?(attr_name.to_sym)
        raise "unknown attribute '#{attr_name}'"
      end
      send("#{attr_name.to_sym}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map { |col| self.send(col) }
  end

  def insert
    col_names = self.class.columns.map { |col| col.to_s }.join(', ')
    question_marks = (["?"] * self.class.columns.length).join(', ')

    results = DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_text = self.class.columns.map { |col| "#{col} = ?" }.join(", ")
    results = DBConnection.execute(<<-SQL, *attribute_values)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_text}
      WHERE
        #{self.class.table_name}.id = #{self.id}
      SQL

    DBConnection.last_insert_row_id
  end

  def save
    self.id == nil ? insert : update
  end
end
