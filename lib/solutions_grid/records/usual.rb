module SolutionsGrid::Records::Usual

  def get_paginate_records
    @options[:model].paginate(:all, paginate_options)
  end


  def paginate_options
    paginate_options = {}
    paginate_options[:conditions] = filter_options
    paginate_options[:order] = order_options
    paginate_options[:include] = @options[:include] if @options[:include]
    paginate_options[:joins] = @options[:joins] if @options[:joins]
    paginate_options[:select] = @options[:select] if @options[:select]
    paginate_options[:paginate] = @options[:paginate]
    paginate_options
  end
  

  def filter_options
    conditions, values = columns_filters(conditions, values)
    conditions << "(" + options[:conditions] + ")" if options[:conditions]
    values.merge!(options[:values])

    conditions = conditions.join(" AND ")
    [ conditions, values ]
  end


  def columns_filters(conditions, values)
    @options[:filter_values].each do |filter, options|
      # Skip all not-text filters
      next if options[:text].blank? 
      column_conditions = Array(@options[:columns][:filter][filter]).inject([]) do |cond, column|
        quoted_column = ActiveRecord::Base.connection.quote_column_name(column)
        case filter[:type]
        when :strict
          cond << "#{@options[:model].table_name}.#{quoted_column} = :#{column}"
          values[column.to_sym] = filter[:text]
        when :match
          cond << "#{@options[:model].table_name}.#{quoted_column} LIKE :#{column}"
          values[column.to_sym] = "%#{filter[:text]}%"
        when :range
          if get_date(options[:from])
            cond << "#{@options[:model].table_name}.#{quoted_column} >= :#{column}_from"
            values[(column + "_from").to_sym] = options[:from]
          end
          if get_date(options[:to])
            cond << "#{@options[:model].table_name}.#{quoted_column} <= :#{column}_to"
            values[(column + "_to").to_sym] = options[:to]
          end
        end
      end
      filter_conditions << "(" + column_conditions.join(" OR ") + ")"
    end
    conditions << "(" + filter_conditions.join(" AND ") + ")" unless filter_conditions.empty?
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
    return nil if @options[:sort_values] && !@options[:sort_values].empty?
    order = (@options[:sort_values][:order] == 'asc') ? "ASC" : "DESC"
    column = ActiveRecord::Base.connection.quote_column_name(@options[:sort_values][:column])
    { :order => "#{@options[:model].table_name}.#{column} #{order}" }
  end

end
