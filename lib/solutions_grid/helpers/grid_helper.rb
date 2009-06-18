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
    
    
    def place_date(grid, type, postfix)
      name = grid.options[:name].to_sym
      date = session[:filter] && session[:filter][name] && session[:filter][name][type] && session[:filter][name][type][postfix]
      date = if date && !date['year'].blank?
        Date.civil(
          date['year'].to_i, 
          (date['month'].blank? ? 1 : date['month']).to_i, 
          (date['day'].blank? ? 1 : date['day']).to_i
        ) rescue nil
      else
        nil
      end
      prefix = name.to_s + "_" + type.to_s + "_" + postfix.to_s + "_filter"
      select_date(date, :order => [:year, :month, :day], :prefix => prefix, :include_blank => true)
    end
      
  end
end
