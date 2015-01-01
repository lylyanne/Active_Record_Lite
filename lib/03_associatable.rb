require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    self.foreign_key = options[:foreign_key] || "#{name}_id".to_sym
    self.primary_key = options[:primary_key] || :id
    self.class_name = options[:class_name] || name.camelcase
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    self.foreign_key = options[:foreign_key] || "#{self_class_name.underscore}_id".to_sym
    self.primary_key = options[:primary_key] || :id
    self.class_name = options[:class_name] || name.singularize.camelcase
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name.to_s.singularize, options)
    self.assoc_options[name] = options
    define_method(name) do
      foreign_key = send(options.foreign_key)
      target_model = options.model_class
      target_model.where(id: foreign_key).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name.to_s, self.to_s, options)
    define_method(name) do
      target_model = options.model_class
      target_model.where(options.foreign_key => self.id )
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
    @assoc_options ||= {}
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
