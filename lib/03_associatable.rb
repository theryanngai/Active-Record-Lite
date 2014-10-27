require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key]
    @class_name = options[:class_name]
    @primary_key = options[:primary_key]

    @foreign_key ||= (name.to_s + '_id').underscore.to_sym
    @class_name ||= (name).to_s.singularize.camelcase
    @primary_key ||= 'id'.to_sym
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key]
    @class_name = options[:class_name]
    @primary_key = options[:primary_key]

    @foreign_key ||= (self_class_name.underscore + '_id').to_sym
    @class_name ||= name.to_s.singularize.camelcase
    @primary_key ||= 'id'.to_sym
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    
    define_method("#{name}") do
      col_name = options.send(:foreign_key)
      foreign_key = self.send(col_name)
      target_class = options.send(:model_class)
      
      output = DBConnection.execute(<<-SQL, foreign_key)
        SELECT
          *
        FROM
          #{target_class.send(:table_name)}
        WHERE
          id = ?
        SQL

      target_class.new(output.first)
    end
  end

  def has_many(name, options = {})
    results = []

    define_method("#{name}") do
      options = HasManyOptions.new(name, self.class.to_s, options)
      col_name = options.send(:foreign_key).to_s
      target_class = options.send(:model_class)
      
      output = DBConnection.execute(<<-SQL)
        SELECT
          *
        FROM
          #{target_class.send(:table_name)}
        WHERE
          #{col_name} = #{self.id}
      SQL

      output.each do |output|
        results << target_class.new(output)
      end

      results

    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
end

