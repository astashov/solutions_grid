begin
  require File.dirname(__FILE__) + '/../../../../spec/spec_helper'
rescue LoadError
  puts "You need to install rspec in your base app"
  exit
end

plugin_spec_dir = File.dirname(__FILE__)
ActiveRecord::Base.logger = Logger.new(plugin_spec_dir + "/debug.log")

class CategoryExample; end
class FeedExample; end
class DateExample; end
class SpanDateExample; end
class HABTMExample; end

def set_column_names_and_hashes(mock, all_columns)
  columns_hash = {}
  column_names = []
  all_columns.each do |type, columns|
    columns.each do |column|
      column_mock = mock(column)
      column_mock.stub!(:type).and_return(type)
      columns_hash[column] = column_mock
      column_names << column
    end
  end
  mock.stub!(:column_names).and_return(column_names)
  mock.stub!(:columns_hash).and_return(columns_hash)
end
