module SolutionsGrid
  module GridHelper
    
    # This helper shows generated grid. It takes two arguments:
    #  * grid - grid's object that you created in controller
    #  * filter - array with filters (need for showing filter forms). It can contain:
    #    * :text - show form with filter by string
    #    * :date - show form with filter by date
    # You should have partial 'grid/grid' in your app/views directory with
    # template of the grid. You can get example of this grid in 
    # files/app/views/grid/_grid.html.haml or .html.erb
    def show_grid(grid, filter = [])
      session[:grid] ||= {}
      name = grid.options[:name].to_sym
      session[:grid][name] ||= {}
      session[:grid][name][:controller] = params[:controller]
      session[:grid][name][:action] = params[:action]
      
      helper_module_name = grid.options[:name].camelize.to_s
      model_helpers_module = "SolutionsGrid::#{helper_module_name}"
      if SolutionsGrid.const_defined?(helper_module_name)
        self.class.send(:include, model_helpers_module.constantize) 
      end
      self.class.send(:include, SolutionsGrid::Actions)
      
      prepare_headers_of_values(grid)
      prepare_headers_of_actions(grid)
      
      prepare_values(grid)

      prepare_paginate(grid)
      
      render :partial => 'grid/grid', :locals => { :grid => grid, :filter => filter }
    end
    
    
    private      
      
      # Showing headers of table, attributes is being taken from
      # /helpers/attributes/'something'.rb too or just humanized.
      def prepare_headers_of_values(grid)
        grid.view[:headers] ||= []
        grid.columns[:show].each do |column|
          
          show_value = case
          when self.class.instance_methods.include?(grid.options[:name] + "_" + column)
            send(grid.options[:name] + "_" + column)[:key]
          when column =~ /_id/
            column.gsub('_id', '').humanize
          else
            column.humanize
          end
          
          show_value = if grid.columns[:sort].include?(column)
            link_to(h(show_value), sort_url(:column => column, :grid_name => grid.options[:name]), :class => "sorted")
          else
            h(show_value)
          end
          
          if grid.options[:sorted] && grid.options[:sorted][:by_column] == column
            show_value += grid.options[:sorted][:order] == 'asc' ? " &#8595;" : " &#8593;"
          end
          
          grid.view[:headers] << show_value
        end
      end
      
      
      def prepare_headers_of_actions(grid)
        grid.view[:headers] ||= []
        grid.options[:actions].each do |action|
          grid.view[:headers] << send("action_" + action)[:key]
        end
      end
    
      
      # Show contents of table, attributes is being taken from
      # /helpers/attributes/'something'.rb too or just escaped.
      def prepare_values(grid)
        grid.view[:records] ||= []
        grid.records.each do |record|
          show_values = []
          
          grid.columns[:show].each do |column|
            name = grid.options[:name]
            method = grid.options[:name] + "_" + column
            show_values << case
            when self.class.instance_methods.include?(method)
              send(grid.options[:name] + "_" + column, record)[:value]
            when column =~ /_id/
              belonged_model, belonged_column = grid.get_belonged_model_and_column(column)
              association = grid.get_association(belonged_model)
              associated_record = record.send(association)
              associated_record.respond_to?(belonged_column) ? h(associated_record.send(belonged_column)) : ""
            else
              h(record.send(column))
            end
          end
          
          grid.options[:actions].each do |action|
            show_values << send("action_" + action, record)[:value]
          end
          
          grid.view[:records] << show_values
        end
      end
      
      
      def prepare_paginate(grid)
        if grid.options[:paginate]
          additional_params = {:class => "grid_pagination", :id => "#{grid.options[:name]}_grid_pagination"}
          additional_params[:param_name] = "#{grid.options[:name]}_page"
          additional_params[:params] = { :grid => grid.options[:name] }
          grid.view[:paginate] = will_paginate(grid.records, additional_params)
        else
          grid.view[:paginate] = ""
        end
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
