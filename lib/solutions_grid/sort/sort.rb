module SolutionsGrid::Sort
  
  # Sort all records of the object. You should pass parameters:
  # * <tt>by_column</tt> - string with name of column you want to sort
  # * <tt>order</tt> - order of the sorting, string, can be 'asc' or 'desc'. Default id 'asc'.
  # 
  # It will raise an exception if you pass column as <tt>by_column</tt> parameter, but it is not included in <tt>columns[:show]</tt>
  def sort(by_column, order = 'asc')
    verify_that_records_are_sorted_by_column_included_to_sort_columns(by_column)
    column = SolutionsGrid::Column.find(by_column, columns[:show])
    @options[:sorted] = { :by_column => by_column, :order => order }
    return @records if @records.size <= 1
    @records.sort! do |a, b|
      a, b = b, a if order == 'desc'
      a_value = column.show_value(a)
      b_value = column.show_value(b)
      a_value.to_s <=> b_value.to_s
    end
  end
  
end