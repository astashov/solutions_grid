class Grid
  include SolutionsGrid::ErrorsHandling  
  include SolutionsGrid::Records::Paginate
  include SolutionsGrid::Records::Sphinx

  attr_reader :records, :options, :conditions, :values, :include, :order
  
  # Grid initialization. It constructs SQL query (with sorting and filtering
  # conditions, optionally), then fill @records by result of query. This 
  # array of records you can use in helper, show_grid().
  # 
  # == Options
  # 
  # === Required
  #
  # 1. <tt>[:name]</tt>
  #    Set name of the grid. This parameter will be used for storing sorted and 
  #    filtered info of this grid. 
  # 2. <tt>[:model]</tt> 
  #    Set model. It will be used for constructing SQL query.
  # 3. <tt>[:columns][:show]</tt> 
  #    Columns that you need to show, pass as array, e.g. %w{ name body }
  # 
  # === Optional
  # 
  # 1. <tt>[:columns][:sort]</tt> 
  #    Pass columns you need to allow sorting. Default is columns to show.
  # 2. <tt>[:columns][:filter][something]</tt>
  #    Pass columns you need to allow filtering by string.
  # 3. <tt>[:columns][:filter][:by_date]</tt>
  #    Pass columns you need to allow filtering by date.
  # 4. <tt>[:columns][:filter][:by_span_date]</tt>
  #    Pass columns you need to allow filtering by span of date. You should pass 
  #    columns as array of arrays (format of arrays - [ start_date_column, 
  #    end_date_column ]), e.g. [ [start_date_column, end_date_column] ].
  # 5. <tt>[:actions]</tt>
  #    Pass necessary actions (such as 'edit', 'destroy', 'duplicate'). 
  #    Details about actions see below.
  # 6. <tt>[:sorted]</tt>
  #    Pass column to SQL query that will be sorted and order of sorting. Example:
  #    [:sorted] = { :by_column => "name", :order => "asc" }
  # 6. <tt>[:filtered]</tt>
  #    Pass hash with parameters:
  #     * <tt>[:filtered][:from_date] and [:filtered][:end_date]</tt>
  #       [:columns][:filter][:by_date] should have date that is in range
  #       of these dates (otherwise, it will not be in @records array).
  #       [:columns][:filter][:by_span_date] should have date range that intersects
  #       with range of these dates.
  #     * <tt>[:filtered][something]</tt>
  #       It should contain hash with parameters:
  #       * <tt>[:text]</tt> - text you want to search
  #       * <tt>[:strict] -> :strict or :match. If you specify :strict, it will
  #         construct SQL WHERE query like 'something = 'value', if you specify
  #         :match, it will construct like 'something LIKE '%value%'
  #       * <tt>[:convert_id] -> if set to false, it will not convert columns
  #         like 'content_item_id_body' to SQL WHERE queries like 
  #         'content_items.body = 'value'. Default is true.
  #       Example:
  #         :model => Post
  #         :columns => { :filter => { :by_text => %w{name body}, :by_article => %w{article_id} }
  #         :filtered => { :by_text => { :text => "smthg", :type => :match },
  #                      { :by_article => { :text => "artcl", :type => :strict }
  #       will create SQL query like 
  #       '((`posts`.`name` LIKE '%smthg%' OR `posts`.`body` LIKE '%smthg%') AND (`articles`.`name` = 'artcl')
  #       
  # 7. <tt>[:conditions]</tt>, <tt>[:values]</tt>, <tt>[:include]</tt>, <tt>[:joins]</tt>, <tt>[:select]
  #    You can pass additional conditions to grid's SQL query. E.g.,
  #    [:conditions] = "user_id = :user_id"
  #    [:values] = { :user_id => "1" }
  #    [:include] = [ :user ]
  #    [:select] = "id"
  #    will select and add to @records only ids of records of user with id = 1.
  # 8. <tt>[:paginate]</tt>
  #    If you pass [:paginate] parameter, #paginate method will be used instead of
  #    #find (i.e., you need will_paginate plugin). [:paginate] is a hash:
  #    [:paginate][:page] - page you want to see
  #    [:paginate][:per_page] - number of records per page
  # 9. <tt>[:template]</tt>
  #    What template use for displaying the grid. Default is 'grid/grid'
  # 
  #                                                                                                                                                            
  # == Default values of the options
  # 
  # * <tt>[:columns][:show]</tt> - all columns of the table, except 'id', 'updated_at', 'created_at'.
  # * <tt>[:columns][:sort]</tt> - default is equal [:columns][:show]
  # * <tt>[:columns][:filter][:by_string]</tt> - default is empty array
  # * <tt>[:columns][:filter][:by_date]</tt> - default is empty array
  # * <tt>[:columns][:filter][:by_span_date]</tt> - default is empty array
  # * <tt>[:actions]</tt> - default is empty array
  # * <tt>[:filtered]</tt> - default is empty hash
  # * <tt>[:sorted]</tt> - default is empty hash
  # 
  # 
  # == User-defined display of actions and values
  # 
  # You can create your own rules to display columns (e.g., you need to show 'Yes' if some boolean
  # column is true, and 'No' if it is false). For that, you should add method with name
  # gridname_columnname to SolutionGrid::'GridName'. You should create 'attributes' folder in
  # app/helper and create file with filename gridname.rb. Let's implement example above:
  # 
  # We have grid with name 'feeds' and boolean column 'restricted'. We should write in /app/helpers/attributes/feeds.rb
  # 
  #   module SolutionsGrid::Feeds
  #     def feeds_restricted(record = nil)
  #       value = record ? record.restricted : nil
  #       { :key => "Restricted", :value => value ? "Yes" : "No" }
  #     end
  #   end
  # 
  # Function should take one parameter (default is nil) and return hash with keys
  # <tt>:key</tt> - value will be used for the headers of the table
  # <tt>:value</tt> - value will be user for cells of the table
  # 
  # If such method will not be founded, there are two ways to display values.
  # 
  # * If column looks like 'category_id', the plugin will try to display 'name' column of belonged table 'categories'.
  # * If column looks like 'category_id_something', the plugin will try to display 'something' column of belonged table 'categories'.
  # * If column doesn't look like 'something_id' the plugin just display value of this column.
  #   
  # You should add actions that you plan to use to module SolutionsGrid::Actions by similar way.
  # Example for 'edit' action, file 'app/helpers/attributes/actions.rb':
  # 
  #   module SolutionsGrid::Actions
  #     def action_edit(record = nil)
  #       if record
  #         url = url_for(:controller => record.class.to_s.underscore.pluralize, :action => 'edit')
  #         value = link_to("Edit", url)
  #       else
  #         value = nil
  #       end
  #       { :key => "Edit", :value => value }
  #     end
  #   end
  # 
  # 
  # == Sort and filter
  # 
  # To sort and filter records of the grid you *must* pass options <tt>:filtered</tt> or <tt>:sorted</tt>.
  # 
  # == Examples of using the SolutionGrid
  # 
  # <i>in controller:</i>
  # 
  #   def index
  #     @table = Grid.new(:name => "feeds", :model => Feed, :columns => { :show => %{name body}})
  #   end
  # 
  # <i>in view:</i>
  # 
  #   show_grid(@table)
  #   
  # It will display feeds with 'name' and 'body'. There will be no actions and 
  # filterable columns, all columns will be sortable, but because you don't pass 
  # <tt>:sorted</tt> option, sort will not work.
  # 
  # 
  # <i>in controller:</i>
  #   def index
  #     @table = Grid.new(
  #       :columns => {
  #         :show => %w{name description}, 
  #         :sort => %w{name}
  #       }, 
  #       :sorted => session[:sort] ? session[:sort][:feeds] : nil,
  #       :name => "feeds",
  #       :model => Feed
  #     )
  #   end
  # 
  # <i>in view:</i>
  #   show_grid(@table)
  #   
  # It will display feeds with columns 'name' and 'description'. There will be no actions and 
  # filterable columns, 'name' column will be sortable, sort info is stored in 
  # session[:sort][:feeds][:by_column] (session[:sort][:feeds] hash can be automatically
  # generated by grid_contoller of SolutionsGrid. Just add :sorted => session[:sort][:feeds],
  # and all other work will be done by the SolutionsGrid plugin)
  # 
  # 
  # <i>in controller:</i>
  #   def index
  #     @table = Grid.new(
  #       :columns => {
  #         :show => %w{name description}, 
  #         :filter => { 
  #           :by_string => %w{name}
  #         },
  #       },
  #       :name => "feeds",
  #       :model => Feed
  #       :sorted => session[:sort][:feeds],
  #       :filtered => session[:filter][:feeds],
  #       :actions => %w{edit delete}
  #     )
  #   end
  # 
  # <i>in view:</i>
  #   show_grid(@table, [ :text ])
  #   
  # It will display feeds with columns 'name' and 'description'. These columns will be sortable.
  # There will be actions 'edit' and 'delete' (but remember, you need action methods
  # 'action_edit' and 'action_delete' in SolutionGrid::Actions in 'app/helpers/attributes/actions.rb').
  # There will be filterable column 'name', and it will be filtered by session[:filter][:feed][:by_string] value.
  # (that will be automatically generated by SolutionsGrid's grid_controller
  def initialize(options = {})    
    @options = options 
    check_for_errors

    @options[:name] ||= options[:model].to_s.underscore.pluralize
    @options[:columns][:sort] ||= []
    @options[:columns][:filter] ||= []
    
    @records = get_records
  end


  def filtered?
    # TODO: Maybe try 'any?'?
    @options[:filter_values] && !@options[:filter_values].select do |key, value| 
      if value[:type] == :range
        from = value[:value] && value[:value][:from]
        to = value[:value] && value[:value][:to]
        (from && !from['year'].blank?) || (to && !to['year'].blank?)
      else
        !value[:value].blank?
      end
    end.empty?
  end


  private

    def get_records
      @options[:sphinx] ? get_sphinx_records : get_paginate_records
    end


    # Different helper methods:


    def convert_date_hash_to_integer(date)
      return nil unless date
      date.symbolize_keys!
      unless date[:year].blank?
        year = "%04d" % date[:year].to_i
        month = "%02d" % date[:month].to_i
        day = "%02d" % date[:day].to_i
        date = (year + month + day).to_i
      end
    end


    def get_association_and_column(column)
      case
      when association_with_column_match = column.match(/(.*)\.(.*)/)
        association = association_with_column_match[1].singularize.to_sym
        [ association, association_with_column_match[2] ]
      when association_match = column.match(/(.*)_id/)
        association = association_match[1].to_sym
        [ association, 'name' ]
      else
        [ nil, column ]
      end
    end


    def get_table_and_column(column)
      association, column = get_association_and_column(column)
      table = if association
        if !@include.include?(association) && association.to_s.pluralize != @options[:model].table_name
          @include << association 
        end
        association.to_s.pluralize
      else
        @options[:model].table_name
      end
      [ table, column ]
    end



end 
