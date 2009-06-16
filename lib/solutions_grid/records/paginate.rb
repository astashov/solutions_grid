module SolutionsGrid::Records::Paginate

  def get_paginate_records
    method = @options[:paginate] ? :paginate : :find
    @options[:model].send(method, :all, paginate_options)
  end


  def paginate_options
    paginate_options = {}
    paginate_options[:conditions] = filter_options
    paginate_options[:order] = order_options
    paginate_options[:include] = @options[:include] if @options[:include]
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
    [ conditions, values ]
  end


  def columns_filters(conditions, values)
    not_empty_filters = @options[:filter_values].select{ |filter, options| !options[:text].blank? }
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
      values[column.to_sym] = filter_options[:text]
    when :match
      conditions << "#{@options[:model].table_name}.#{quoted_column} LIKE :#{column}"
      values[column.to_sym] = "%#{filter_options[:text]}%"
    when :range
      if get_date(options[:from])
        conditions << "#{@options[:model].table_name}.#{quoted_column} >= :#{column}_from"
        values[(column + "_from").to_sym] = filter_options[:from]
      end
      if get_date(options[:to])
        conditions << "#{@options[:model].table_name}.#{quoted_column} <= :#{column}_to"
        values[(column + "_to").to_sym] = filter_options[:to]
      end
    end
    [ conditions, values ]
  end


  def get_date(params)
    return nil if !params || params[:year].blank?
    params[:month] = params[:month].blank? ? 1 : params[:month]
    params[:day] = params[:day].blank? ? 1 : params[:day]
    conditions = [ params[:year].to_i, params[:month].to_i, params[:day].to_i ]
    conditions += [ params[:hour].to_i, params[:minute].to_i ] if params[:hour]
    DateTime.civil(*conditions) rescue nil
  end
  
  
  def order_options
    return nil if !@options[:sort_values] || @options[:sort_values].empty?
    order = (@options[:sort_values][:order] == 'asc') ? "ASC" : "DESC"
    column = ActiveRecord::Base.connection.quote_column_name(@options[:sort_values][:column])
    "#{@options[:model].table_name}.#{column} #{order}"
  end

end
