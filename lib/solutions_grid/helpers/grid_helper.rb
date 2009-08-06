require 'pp'
module SolutionsGrid
  module GridHelper
    
    def grid_paginate(grid, options = {})
      name = grid.options[:name]
      options.merge!(
        :class => "grid-pagination", 
        :id => "#{name}_grid_pagination",
        :param_name => "#{name}_page",
        :params => { :grid => name }
      )
      will_paginate(grid.records, options)
    end
    
    
    def place_date(name, type, postfix, options = {})
      date = session[:filter] && session[:filter][name] && session[:filter][name][type] && session[:filter][name][type][postfix]
      date = if date && !date[:year].blank?
        Date.civil(
          date[:year].to_i, 
          (date[:month].blank? ? 1 : date[:month]).to_i, 
          (date[:day].blank? ? 1 : date[:day]).to_i
        ) rescue nil
      else
        nil
      end
      prefix = name.to_s + "_" + type.to_s + "_" + postfix.to_s + "_filter"
      #select_date(date, :order => [:year, :month, :day], :prefix => prefix, :include_blank => true)
      text_field_tag(prefix, date ? date.strftime("%m/%d/%Y") : nil, options)
    end


    def show_grid_header(options, column)
      escaped_column = column.gsub('.', '_')
      header = if self.respond_to?(method = "#{options[:name]}_header_#{escaped_column}")
        send(method)
      elsif self.respond_to?(method = "header_#{escaped_column}")
        send(method)
      else
        h(column).humanize
      end
      
      show_value = header
      if options[:columns][:sort].include?(column)
        path = sort_path(:column => URI.escape(column, "."), :grid_name => options[:name])
        show_value = link_to(show_value, path, :class => "sorted")
        if options[:sort_values] && options[:sort_values][:column] == column
          show_value += options[:sort_values][:order] == 'asc' ? " &#8595;" : " &#8593;"
        end
      end
      show_value
    end


    def show_grid_value(options, column, record)
      escaped_column = column.gsub('.', '_')
      if self.respond_to?(method = "#{options[:name]}_#{escaped_column}")
        send(method, record)
      elsif self.respond_to?(method = "grid_#{escaped_column}")
        send(method, record)
      else
        h(record.send(escaped_column))
      end
    end

      
  end
end
