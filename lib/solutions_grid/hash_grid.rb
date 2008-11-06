class SolutionsGrid::HashGrid < SolutionsGrid::CommonGrid
  
  attr_reader :columns, :records, :options

  private
  
    def significant_columns
      @records.first.keys.map { |key| key.to_s }.sort { |a, b| a.to_s <=> b.to_s }
    end
    
    
    def initialize_show_columns(columns)
      columns.map! { |column| SolutionsGrid::HashColumn.new(column, @options[:model], @records.first) }
      columns
    end
    
    
    def set_type_of_date(option)
      option || :undefined
    end
  
end