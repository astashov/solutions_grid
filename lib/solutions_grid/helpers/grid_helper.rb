module SolutionsGrid
  module GridHelper
    
    def show_grid(grid)
      prefix = set_name_prefix(grid)
      session[:grid] ||= {}
      name = grid.options[:name].to_sym
      session[:grid][name] ||= {}
      session[:grid][name][:controller] = params[:controller]
      session[:grid][name][:action] = params[:action]
      output = "<div id='#{prefix}spinner'>&nbsp;</div>\n"
      output += "<div id='#{prefix}grid'>\n"
      output += show_table(grid)
      output += "</div>\n"
    end
    
    def show_table(grid)
      output = ""
      output += "<table class='grid' border=\"1\">\n"
      output += show_headers(grid)
      output += show_values(grid)
      output += "</table>\n"
      output += show_paginate(grid) if grid.options[:paginate][:enabled]
      output
    end
    
    
    def show_filter(grid, show_date = false)
      prefix = set_name_prefix(grid)
      output = ""
      url = filter_url(:grid_name => grid.options[:name])
      output += "<form action=\"#{url}\" method=\"get\" id=\"#{prefix}filter\">"
      output += "<input type=\"hidden\" name=\"grid_name\" class=\"grid_name\" value=\"#{grid.options[:name]}\" />"
      output += add_select_tags(grid) if show_date
      output += "<label for=\"#{prefix}string_filter\">Filter:</label> "
      output += text_field_tag("#{prefix}string_filter", grid.options[:filtered] ? grid.options[:filtered][:by_string] : '', :size => 20, :maxlength => 200) + " "
      output += submit_tag('Filter', :class => "filter_button") + " "
      output += submit_tag('Clear')
      output += "</form>"
      output += "<div id=\"#{prefix}filter_indicator\">" + (grid.options[:filtered] ? 'Filtered' : '') + '</div>'
      output
    end
    
    
    private
    
      def show_headers(grid)
        output = "<tr>\n"
        output += show_headers_of_values(grid)
        output += show_headers_of_actions(grid)
        output += "\n</tr>\n"
      end
      
      
      def show_headers_of_values(grid)
        output = ""
        # Showing headers of table, attributes is being taken from
        # /helpers/attributes/'something'.rb too or just humanized.
        grid.columns[:show].each do |column|
          show_value = column.show_header(grid.records.first)
          show_value = if grid.columns[:sort].include?(column)
            link_to(h(show_value), sort_url(:column => column, :grid_name => grid.options[:name]), :class => "sorted")
          else
            h(show_value)
          end
          if grid.options[:sorted] && grid.options[:sorted][:by_column] == column.name
            show_value += grid.options[:sorted][:order] == 'asc' ? " &#8595;" : " &#8593;"
          end
          output += "<th>#{show_value}</th>" 
        end
        output
      end
      
      
      def show_headers_of_actions(grid)
        grid.options[:actions].inject("") { |output, action| output + "<th>#{send("action_" + action, nil)[:key]}</th>" }
      end
    
      
      def show_values(grid)
        output = ""
        # Show contents of table, attributes is being taken from
        # /helpers/attributes/'something'.rb too or just escaped.
        grid.records.each do |record|
          output += "<tr>\n"

          grid.columns[:show].each do |column|
            show_value = column.show_value(record)
            output += "<td>#{show_value}</td>"
          end
          # Adding headers for actions
          grid.options[:actions].each { |action| output += "<td>#{send("action_" + action, record)[:value]}</td>" }

          output += "\n</tr>\n"
        end
        output
      end
      
      
      def show_paginate(grid)
        additional_params = {:class => "grid_pagination", :id => "#{grid.options[:name]}_grid_pagination"}
        additional_params[:param_name] = "#{grid.options[:name]}_page"
        will_paginate(grid.records, additional_params) || ""
      end
      
      
      def add_select_tags(grid)
        prefix = set_name_prefix(grid)
        type = grid.options[:type_of_date_filtering]
        klass = (type == :datetime) ? DateTime : type.to_s.camelize.constantize
        output = "<label for=\"date_filter\">#{klass.to_s} Filter:</label><br />"
        now = klass.today rescue klass.now
        
        from_date = grid.convert_to_date(grid.options[:filtered][:from_date], type) rescue now
        to_date = grid.convert_to_date(grid.options[:filtered][:to_date], type) rescue now
        helper_name = "select_#{type}".to_sym
        
        output += send(helper_name, from_date, :prefix => "#{prefix}from_date") + "<br />"
        output += send(helper_name, to_date, :prefix => "#{prefix}to_date") + "<br />"
        output
      end
      
      def set_name_prefix(grid)
        grid.options[:name] + "_"
      end
  end
end
