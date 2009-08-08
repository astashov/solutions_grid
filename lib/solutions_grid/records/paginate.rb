module SolutionsGrid::Records::Paginate

  def get_paginate_records
    method = @options[:paginate] ? :paginate : :find
    options = paginate_options
    @options[:filtered] = true unless options[:conditions].blank?
    # Only for Metis - calculating and cache total entries of content items
    if @options[:model].to_s == "ContentItem" && method == :paginate
      options[:total_entries] = @options[:paginate][:limit] || get_total_entries(options) 
    end
    @options[:model].send(method, :all, options)
  end


  private

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
      paginate_options[:group] = @options[:group] if @options[:group]
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
        filter_conditions << "(" + column_conditions.join(" OR ") + ")" unless column_conditions.empty?
        filter_conditions
      end

      conditions << "(" + filter_conditions.join(" AND ") + ")" unless filter_conditions.empty?
      [ conditions, values ]
    end


    def get_conditions_and_values(conditions, values, filter_options, column)
      table, column = get_table_and_column_for_filtering(column)
      quoted_column = ActiveRecord::Base.connection.quote_column_name(column)
      case filter_options[:type]
      when :strict
        conditions << "#{table}.#{quoted_column} = :#{column}"
        values[column.to_sym] = filter_options[:value]
      when :match
        conditions << "#{table}.#{quoted_column} LIKE :#{column}"
        values[column.to_sym] = "%#{filter_options[:value]}%"
      when :range
        date_conditions = []
        if date = convert_date_hash_to_integer(filter_options[:value][:from])
          date_conditions << "#{table}.#{quoted_column} >= :#{column}_from"
          values[(column + "_from").to_sym] = date
        end
        if date = convert_date_hash_to_integer(filter_options[:value][:to])
          date_conditions << "#{table}.#{quoted_column} <= :#{column}_to"
          values[(column + "_to").to_sym] = date
        end
        conditions << date_conditions.join(" AND ") unless date_conditions.empty?
      end
      [ conditions, values ]
    end


    def get_table_and_column_for_filtering(column)
      if table_with_column_match = column.match(/(.*)\.(.*)/)
        table = table_with_column_match[1]
        column = table_with_column_match[2]
      else
        table = @options[:model].table_name
        column = column
      end
      [ table, column ]
    end


    def order_options
      if @options[:sort_values] && !@options[:sort_values].empty?
        order = (@options[:sort_values][:order] == 'asc') ? "ASC" : "DESC"
        table, column = get_table_and_column(@options[:sort_values][:column])
        column = ActiveRecord::Base.connection.quote_column_name(column)
        "#{table}.#{column} #{order}"
      end
    end


    def get_total_entries(options)
      count_options = options.dup.delete_if {|key, value| %w{page per_page total_entries order}.include?(key.to_s) }
      total_entries = nil
      ContentItemsCount.all.each do |content_items_count|
        total_entries = content_items_count.count if content_items_count.options == count_options
      end
      unless total_entries
        total_entries = @options[:model].count(count_options)
        ContentItemsCount.create!(:count => total_entries, :options => count_options)
      end
      total_entries
    end

end
