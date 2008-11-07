require "solutions_grid/column/column"

class SolutionsGrid::ActiveRecordColumn < SolutionsGrid::Column
  
  def get_type_of_column
    @options[:model].columns_hash[@name].type
  end
  
  def get_value_of_record(record, name = @name)
    record.send(name)
  end
    
  def does_column_exist?
    condition = respond_to?(@methodname) || @model.column_names.include?(self.name) || @model.instance_methods.include?(self.name)
    condition ||= @example_of_record.respond_to?(self.name) if @example_of_record
    return condition
  end

end
