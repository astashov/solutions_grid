require "solutions_grid/column/column"

class SolutionsGrid::HashColumn < SolutionsGrid::Column
  
  def get_type_of_column
    @options[:type_of_date_filtering]
  end
  
  def get_value_of_record(record, name = @name)
    record = record.stringify_keys
    record[name]
  end
  
  def does_column_exist?
    return true unless @example_of_record
    keys = @example_of_record.keys.map { |key| key.to_s }
    return respond_to?(@methodname) || keys.include?(self.name)
  end
  
end