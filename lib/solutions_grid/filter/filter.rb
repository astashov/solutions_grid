module SolutionsGrid::Filter
  
  # Filter records by string, deleting these records, those values of 'filter by date' columns
  # don't match given string.
  def filter_by_string(by_string)
    filter('string', by_string) do |record, column|
      value = column.show_value(record)
      !(value =~ Regexp.new(by_string))
    end
  end
  
  # Filter records by date and by span of date.
  # * Record will be filtered by date if it lies in span of given dates.
  # * Record will be filtered by span of date if its span of dates overlaps given span of dates.
  def filter_by_dates(from_date, to_date)
    # If type wasn't been specified, raise an error
    verify_that_type_of_date_filtering_is_specified(nil) if @options[:type_of_date_filtering] == :undefined
    filter_by_one_date(from_date, to_date)
    filter_by_span_date(from_date, to_date)
  end
  
  private
  
    def filter(type, target)
      @options[:filtered] ||= {}
      @options[:filtered]["by_#{type}".to_sym] = target
      @records.delete_if do |record|
        should_i_delete_record = false
        columns_to_filter = @columns[:filter]["by_#{type}".to_sym] rescue []
        columns_to_filter.each do |column|
          should_i_delete_record = yield(record, column)
          break unless should_i_delete_record
        end
        should_i_delete_record
      end
    end

    
    def filter_by_one_date(from_date, to_date)
      filter('date', [ from_date, to_date ]) do |record, column|
        from_date = column.convert_to_date(from_date)
        to_date = column.convert_to_date(to_date)
        verify_that_date_from_less_than_date_to(from_date, to_date)

        date = column.get_value_of_record(record)

        conditions = {}
        conditions[:from_date] = from_date ? (date >= from_date) : true
        conditions[:to_date] = to_date ? (date <= to_date) : true
        conditions[:common] = conditions[:from_date] && conditions[:to_date]

        delete_record_by_date?(from_date, to_date, conditions)
      end
    end


    def filter_by_span_date(from_date, to_date)
      filter('span_date', [ from_date, to_date ]) do |record, columns|
        from_date = columns[0].convert_to_date(from_date)
        to_date = columns[1].convert_to_date(to_date)
        verify_that_date_from_less_than_date_to(from_date, to_date)

        start_date = columns[0].get_value_of_record(record).to_datetime
        end_date = columns[1].get_value_of_record(record).to_datetime

        conditions = {}
        conditions[:from_date] = from_date ? (from_date <= end_date) : true
        conditions[:to_date] = to_date ? (to_date >= start_date) : true
        conditions[:common] = (from_date >= start_date && from_date <= end_date) || (to_date >= start_date && to_date <= end_date) if from_date && to_date

        delete_record_by_date?(from_date, to_date, conditions)
      end
    end

    
    def delete_record_by_date?(from_date, to_date, conditions)
      if !to_date && !from_date
        return false
      elsif !to_date
        return false if conditions[:from_date]
      elsif !from_date
        return false if conditions[:to_date]
      else
        return false if conditions[:common]
      end
      return true
    end
  
end