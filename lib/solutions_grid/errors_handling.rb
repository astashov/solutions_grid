module SolutionsGrid::ErrorsHandling
    
  def check_for_errors
    verify_that_model_is_specified
    verify_that_name_is_specified
    verify_that_columns_for_show_are_defined
  end
  

  private

    def verify_that_model_is_specified
      raise ModelIsNotDefined, "You should specify model" unless @options[:model]
    end
  
    def verify_that_name_is_specified
      raise NameIsntSpecified, "You should specify name of the grid" unless @options[:name]
    end

    def verify_that_columns_for_show_are_defined
      unless @options[:columns][:show] || !@options[:columns][:show].empty?
        raise ColumnsForShowAreNotDefined, "You should define columns to show"
      end
    end

    def verify_that_sort_columns_are_included_to_show_columns
      check_column_including(@columns[:sort])
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
