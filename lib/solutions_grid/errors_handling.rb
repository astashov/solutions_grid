module SolutionsGrid::ErrorsHandling
    
  def check_for_errors
    verify_that_model_is_specified
    verify_that_name_is_specified
    verify_that_columns_for_show_are_defined
    verify_that_sort_columns_are_included_to_show_columns
    verify_that_there_are_no_unexisted_actions
    verify_that_column_to_sort_is_included_to_sort_columns
    
#    if @options[:filtered] && @options[:filtered][:from_date] && @options[:filtered][:to_date]
#      verify_that_date_from_less_than_date_to(@options[:filtered][:from_date], @options[:filtered][:to_date])
#    end
    
  end
  

  private

    def verify_that_model_is_specified
      raise ModelIsNotDefined, "You should specify model" unless @options[:model]
    end
  
    def verify_that_name_is_specified
      raise NameIsntSpecified, "You should specify name of the grid" unless @options[:name]
    end

    def verify_that_columns_for_show_are_defined
      raise ColumnsForShowAreNotDefined, "You should define columns to show" unless @columns[:show] || !@columns[:show].empty?
    end

    def verify_that_sort_columns_are_included_to_show_columns
      check_column_including(@columns[:sort])
    end

    def verify_that_there_are_no_unexisted_actions
      @options[:actions].each do |action|
        unless SolutionsGrid::Actions.instance_methods.include?("action_" + action)
          raise UnexistedAction, "You are trying to show unexisted action '#{h(action)}'"
        end
      end
    end

    def verify_that_date_from_less_than_date_to(from_date, to_date)
      if from_date && to_date && (from_date > to_date)
        raise IncorrectDate, "Date From must be less than Date To"
      end
    end
    
    def verify_that_column_to_sort_is_included_to_sort_columns
      if @options[:sorted] && !@options[:sorted][:by_column].blank?
        unless @columns[:sort].include?(@options[:sorted][:by_column])
          raise UnexistedColumn, "You can't sort by column #{h(@options[:sorted][:by_column])}"
        end
      end
    end
    
    def verify_that_type_of_date_filtering_is_specified(option)
      unless option
        raise DateTypeIsNotSpecified, "You should specify date type, especially if you are using hashes (by :type_of_date_filtering option)"
      end
    end

    def verify_that_array_contains_date_from_and_date_to(from_and_to_date_columns)
      unless from_and_to_date_columns.size == 2
        raise IncorrectSpanDate, "You should specify array of two elements as column - from_date and to_date"
      end
    end
    
    
    def check_column_including(given_columns)
      given_columns.each do |columns|
        columns = Array(columns)
        columns.each do |column|
          unless @columns[:show].include?(column)
            raise ColumnIsNotIncludedToShow, "Column #{h(column)} is not included to show columns"
          end
        end
      end
    end
    
    def h(msg)
      CGI.escapeHTML(msg.to_s)
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