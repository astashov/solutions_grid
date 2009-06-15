module SolutionsGrid::View

  def get_view
    include_user_specific_helpers
    view = {}
    view[:headers] = get_headers_of_values_and_actions
    view[:values] = get_values_and_actions
    view
  end
  

  private      

    def include_user_specific_helpers
      helper_module_name = @options[:name].camelize.to_s
      model_helpers_module = "SolutionsGrid::#{helper_module_name}"
      if SolutionsGrid.const_defined?(helper_module_name)
        self.class.send(:include, model_helpers_module.constantize) 
      end
      self.class.send(:include, SolutionsGrid::Actions)
    end
    

    def get_headers_of_values_and_actions
      headers_of_values = @options[:columns][:show].inject([]) do |headers, column|
        helper_method = @options[:name] + "_" + column
        show_value = case
        when self.class.instance_methods.include?(helper_method)
          send(helper_method)[:key]
        when column =~ /_id/
          column.gsub('_id', '').humanize
        else
          CGI::escapeHTML(column.humanize)
        end
        da = @options[:view]
        
        if @options[:columns][:sort].include?(column)
          path = sort_path(:column => column, :grid_name => @options[:name])
          show_value = link_to(show_value, path, :class => "sorted")
        end

        if @options[:sort_values] && @options[:sort_values][:column] == column
          show_value += @options[:sort_values][:order] == 'asc' ? " &#8595;" : " &#8593;"
        end
        
        headers << show_value
      end

      headers_of_actions = @options[:actions].inject([]) do |headers, action|
        headers << send("action_" + action)[:key]
      end

      headers_of_values + headers_of_actions
    end
    

    def get_values_and_actions
      @records.inject([]) do |values_and_actions, record|
        values = @options[:columns][:show].map do |column|
          method = @options[:name] + "_" + column
          case
          when self.class.instance_methods.include?(method)
            send(method, record)[:value]
          #when column =~ /_id/
          #  belonged_model, belonged_column = grid.get_belonged_model_and_column(column)
          #  association = grid.get_association(belonged_model)
          #  associated_record = record.send(association)
          #  associated_record.respond_to?(belonged_column) ? h(associated_record.send(belonged_column)) : ""
          else
            CGI::escapeHTML(record.send(column).to_s)
          end
        end

        actions = @options[:actions].inject([]) do |actions, action|
          actions << send("action_" + action, record)[:value]
        end

        values_and_actions << (values + actions)
      end
    end


    # By this trick, we can use helper methods in our class
    def method_missing(method, *args)
      @options[:view].send(method, *args)
    end
    
end
