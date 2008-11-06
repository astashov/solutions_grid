class SolutionsGrid::ActiveRecordGrid < SolutionsGrid::CommonGrid
    
  attr_reader :columns, :records, :options
  
  private
  
    def significant_columns
      columns = @options[:model].column_names.dup rescue []
      columns.delete("id")
      columns.delete("updated_at")
      columns.delete("created_at")
      columns
    end
    
    def initialize_show_columns(columns)
      columns.map! { |column| SolutionsGrid::ActiveRecordColumn.new(column, @options[:model], @records.first) }
      columns
    end
    
    def set_type_of_date(option)
      return option if option
      columns = SolutionsGrid::Column.drop_unsignificant_columns(@options[:model].columns_hash)
      type = :undefined      
      
      columns.each do |name, column|
        possible_types = (column.type == :datetime || column.type == :date)
        type = column.type if possible_types
        break if type == :datetime
      end
    
      return type
    end
  
end