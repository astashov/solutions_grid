module SolutionsGrid::Records::Paginate

  def get_paginate_records
    method = @options[:paginate] ? :paginate : :find
    options = paginate_options
    @options[:filtered] = true unless options[:conditions].blank?
    @options[:model].send(method, :all, options)
  end


  def paginate_options
    paginate_options = {}
    # If some operation need additional association (sorting or filtering, for example),
    # it will add the association to this array
    @include = []
    paginate_options[:conditions] = filter_options if filter_options
    paginate_options[:order] = order_options if order_options
    paginate_options[:include] = @include unless @include.empty?
    paginate_options[:include] += @options[:include] if @options[:include] && paginate_options[:include]
    paginate_options[:include].uniq! if paginate_options[:include]
    paginate_options[:joins] = @options[:joins] if @options[:joins]
    paginate_options[:select] = @options[:select] if @options[:select]
    paginate_options.merge!(@options[:paginate]) if @options[:paginate]
    paginate_options
  end
  

  def filter_options
    conditions = []
    values = {}

    conditions, values = columns_filters(conditions, values) if @options[:filter_values]

    conditions << "(" + @options[:conditions] + ")" if @options[:conditions]
    values.merge!(@options[:values]) if options[:values]

    conditions = conditions.join(" AND ")
    conditions.blank? ? nil : [ conditions, values ]
  end


  def columns_filters(conditions, values)
    not_empty_filters = @options[:filter_values].select{ |filter, options| !options[:value].blank? }

    filter_conditions = not_empty_filters.inject([]) do |filter_conditions, filter_values|
      filter, options = filter_values
      column_conditions = Array(@options[:columns][:filter][filter]).inject([]) do |column_conditions, column|
        column_conditions, values = get_conditions_and_values(column_conditions, values, options, column)
        column_conditions
      end
      filter_conditions << "(" + column_conditions.join(" OR ") + ")"
    end

    conditions << "(" + filter_conditions.join(" AND ") + ")" unless filter_conditions.empty?
    [ conditions, values ]
  end


  def get_conditions_and_values(conditions, values, filter_options, column)
    quoted_column = ActiveRecord::Base.connection.quote_column_name(column)
    case filter_options[:type]
    when :strict
      conditions << "#{@options[:model].table_name}.#{quoted_column} = :#{column}"
      values[column.to_sym] = filter_options[:value]
    when :match
      conditions << "#{@options[:model].table_name}.#{quoted_column} LIKE :#{column}"
      values[column.to_sym] = "%#{filter_options[:value]}%"
    when :range
      if date = convert_date_hash_to_integer(filter_options[:value][:from])
        conditions << "#{@options[:model].table_name}.#{quoted_column} >= :#{column}_from"
        values[(column + "_from").to_sym] = date
      end
      if date = convert_date_hash_to_integer(filter_options[:value][:to])
        conditions << "#{@options[:model].table_name}.#{quoted_column} <= :#{column}_to"
        values[(column + "_to").to_sym] = date
      end
    end
    [ conditions, values ]
  end


  def order_options
    if @options[:sort_values] && !@options[:sort_values].empty?
      order = (@options[:sort_values][:order] == 'asc') ? "ASC" : "DESC"
      table, column = get_table_and_column(@options[:sort_values][:column])
      column = ActiveRecord::Base.connection.quote_column_name(column)
      "#{table}.#{column} #{order}"
    end
  end

end
