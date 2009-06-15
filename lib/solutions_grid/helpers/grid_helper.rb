module SolutionsGrid
  module GridHelper
    
    def grid_paginate(grid, options = {})
      name = grid.options[:name]
      options.merge!(
        :class => "grid_pagination", 
        :id => "#{name}_grid_pagination",
        :param_name => "#{name}_page",
        :params => { :grid => name }
      )
      will_paginate(grid.records, options)
    end
    
    
    def place_date(grid, type, filter)
      name = grid.options[:name]
      default_date = if filter && filter[name.to_sym]
        grid.get_date(filter[name.to_sym][type])
      else
        nil
      end
      prefix = name + "_" + type.to_s
      select_date(default_date, :order => [:year, :month, :day], :prefix => prefix, :include_blank => true)
    end
      
  end
end
