module SolutionsGrid::ErrorsHandling
    
  def check_for_errors
    verify_that_name_is_specified
    verify_that_columns_for_show_are_defined
    verify_that_all_records_are_same_type
    verify_that_there_are_no_unexisted_actions
    verify_that_records_can_be_paginated
  end

  private

    def verify_that_name_is_specified
      raise NameIsntSpecified, "You should specify name of the grid" unless @options[:name]
    end

    def verify_that_columns_for_show_are_defined
      raise ColumnsForShowAreNotDefined, "You should define columns to show" unless @columns[:show]
    end
    

    def verify_that_given_column_is_included_to_show_columns(column)
      unless @columns[:show].map { |show_column| show_column.name }.include?(column)
        raise ColumnIsNotIncludedToShow, "Column #{column} is not included to show columns"
      end
    end
    
    def verify_that_array_contains_date_from_and_date_to(from_and_to_date_columns)
      unless from_and_to_date_columns.size == 2
        raise IncorrectSpanDate, "You should specify array of two elements as column - from_date and to_date"
      end
    end
    
    def verify_that_type_of_date_filtering_is_specified(option)
      unless option
        raise DateTypeIsNotSpecified, "You should specify date type, especially if you are using hashes (by :type_of_date_filtering option)"
      end
    end


    def verify_that_all_records_are_same_type
      @records.each do |record| 
        unless record.is_a?(@options[:model])
          raise DifferentTypesOfRecords, "All records of the displayed array must have same type"
        end
      end
    end


    def verify_that_there_are_no_unexisted_actions
      @options[:actions].each do |action|
        unless respond_to?('action_' + action)
          raise UnexistedAction, "You are trying to show unexisted action '#{action}'"
        end
      end
    end

    def verify_that_records_can_be_paginated
      if !@records.empty? && @options[:paginate][:enabled]
        unless Object.const_defined? "WillPaginate"
          raise WillPaginateIsNotInstalled, "You are trying to paginate, but 'will_paginate' plugin is not installed"
        end
      end
    end


    def verify_that_there_are_no_columns_that_not_inluded_to_show_columns(action, column)
      unless @columns[:show].include?(column.to_s)
        raise ColumnIsNotIncludedToShow, "You are trying to #{action} column '#{column}'. " +
          "This column is not included to show, you can't do this."
      end
    end


    def verify_that_records_are_sorted_by_column_included_to_sort_columns(by_column)
      raise UnexistedColumn, "You trying to sort records by incorrect column" unless @columns[:sort].map{ |c| c.name }.include?(by_column)
    end


    def verify_that_date_from_less_than_date_to(from_date, to_date)
      if from_date && to_date && (from_date > to_date)
        raise IncorrectDate, "Date From must be less than Date To"
      end
    end

    # Exception will be raised when +@records+ has records of different classes
    class DifferentTypesOfRecords < StandardError; end;

    # Exception will be raised when filter or sort columns contain columns not included to show
    class ColumnIsNotIncludedToShow < StandardError; end;

    # Exception will be raised when there is no proper method of action in SolutionsGrid::GridHelper
    class UnexistedAction < StandardError; end;

    # Exception will be raised when some column doesn't exist.
    class UnexistedColumn < StandardError; end;
    
    # Exception will be raised when date type is not specified.
    class DateTypeIsNotSpecified < StandardError; end;
    
    # Exception will be raised when something wrong with date.
    class IncorrectDate < StandardError; end;

    # Exception will be raised when span of date doesn't consist of 2 array elements
    class IncorrectSpanDate < StandardError; end;

    # Exception will be raised when show_columns are not defined.
    class ColumnsForShowAreNotDefined < StandardError; end;

    # Exception will be raised when model or show_columns are not defined.
    class ModelIsNotDefined < StandardError; end;
    
    # Exception will be raised when 'will_paginate' plugin is not installed, but user try to paginate records.
    class WillPaginateIsNotInstalled < StandardError; end;

    # Exception will be raised when user didn't give a name to the grid.
    class NameIsntSpecified < StandardError; end;

end