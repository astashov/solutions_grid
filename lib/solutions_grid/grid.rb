# Main class of the SolutionGrid plugin. It stores array of records (ActiveRecord 
# objects or simple hashes). It can construct SQL query with different operations with
# these records, such as sorting and filtering. With help of GridHelper it can
# show these records as table with sortable headers, show filters.
class Grid
  include SolutionsGrid::ErrorsHandling  
  attr_accessor :view
  attr_reader :records, :options, :columns, :conditions, :values, :include, :order
  
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
  # 7. <tt>[:conditions]</tt>, <tt>[:values]</tt>, <tt>[:include]</tt>, <tt>[:joins]</tt>
  #    You can pass additional conditions to grid's SQL query. E.g.,
  #    [:conditions] = "user_id = :user_id"
  #    [:values] = { :user_id => "1" }
  #    [:include] = [ :user ]
  #    will select and add to @records only records of user with id = 1.
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
    @options = {}
    @options[:name] = options[:name].to_s if options[:name]
    @options[:model] = options[:model]  
    @options[:modelname] = @options[:model].to_s.underscore
    @options[:actions] = Array(options[:actions]) || []
    @options[:conditions] = options[:conditions]
    @options[:values] = options[:values] || {}
    @options[:include] = Array(options[:include]) || []
    @options[:joins] = options[:joins]
    @options[:paginate] = options[:paginate]
    @options[:template] = options[:template] || 'grid/grid'
    
    options[:columns] ||= {}
    @columns = {}
    @columns[:show] = Array(options[:columns][:show] || [])
    @columns[:sort] = options[:columns][:sort] || @columns[:show].dup
    @columns[:filter] = options[:columns][:filter]
    
    @options[:sorted] = options[:sorted]
    @options[:filtered] = options[:filtered]
    
    check_for_errors
    
    @records = get_records
    @view = {}
  end
  
  
  def get_belonged_model_and_column(column)
    column_with_table = column.match(/(.*)\.(.*)/)
    if column_with_table
      table = column_with_table[1]
      column = column_with_table[2]
      return [ table, column ]
    else
      position_match = column.index('_id')
      if position_match
        model = column[0..position_match - 1]
        model_column = column[(position_match + 4)..-1]
        if !model.blank? && !model_column.blank?
          return [ model.camelize.constantize, model_column ]
        elsif !model.blank? && model_column.blank?
          return [ model.camelize.constantize, 'name' ]
        end
      else
        return [ nil, nil ]
      end
    end
  end


  def get_association(belonged_model)
    belonged_model.to_s.underscore.to_sym
  end
  
  
  def get_date(params)
    return nil if !params || params[:year].blank?
    params[:month] = params[:month].blank? ? 1 : params[:month]
    params[:day] = params[:day].blank? ? 1 : params[:day]
    conditions = [ params[:year].to_i, params[:month].to_i, params[:day].to_i ]
    conditions += [ params[:hour].to_i, params[:minute].to_i ] if params[:hour]
    DateTime.civil(*conditions)
  end
  
  
  private
  
    def get_records
      @include ||= []
      method = @options[:paginate] ? :paginate : :find
      conditions = {}
      conditions.merge!(filter(@options[:filtered]))
      conditions.merge!(sort(@options[:sorted]))
      include_belonged_models_from_show_columns
      @include += @options[:include]
      conditions[:include] = @include
      conditions[:joins] = @options[:joins] if @options[:joins]
      if @options[:paginate]
        method = :paginate
        conditions.merge!(@options[:paginate])
      else
        method = :find
      end
      
      @options[:model].send(method, :all, conditions)
    end
    
    
    def sort(options)
      return {} unless options
      order = (options[:order] == 'asc') ? "ASC" : "DESC"
      table_with_column = get_correct_table_with_column(options[:by_column])
      @order = "#{table_with_column} #{order}"
      { :order => @order }
    end
    
    
    def filter(options)
      @conditions ||= []
      @values ||= {}
      if options
        filter_by_strings
        filter_by_date
      end
      @conditions << "(" + @options[:conditions] + ")" if @options[:conditions]
      @values.merge!(@options[:values])
      @conditions = @conditions.join(" AND ")
      { :conditions => [ @conditions, @values ] }
    end
  
    
    def filter_by_strings
      filters = @options[:filtered].dup
      filter_conditions = []
      filters.each do |name, filter|
        string = filter ? filter[:text] : nil
        next if string.blank?
        conditions = []
        Array(@columns[:filter][name]).each do |column|
          convert_to_belonged_model = filter.has_key?(:convert_id) ? filter[:convert_id] : true
          table_with_column = get_correct_table_with_column(column, convert_to_belonged_model)
          column = column.match(/\.(.*)/)[1] if column.match(/\.(.*)/)
          if filter[:type] == :strict
            conditions << "#{table_with_column} = :#{column}"
            @values[column.to_sym] = string
          else
            conditions << "#{table_with_column} LIKE :#{column}"
            @values[column.to_sym] = "%#{string}%"
          end
        end
        filter_conditions << "(" + conditions.join(" OR ") + ")"
      end
      @conditions << "(" + filter_conditions.join(" AND ") + ")" unless filter_conditions.empty?
    end
    
    
    def filter_by_date
      from_date = @options[:filtered][:from_date]
      from_date = get_date(from_date)
      to_date = @options[:filtered][:to_date]
      to_date = get_date(to_date)
      return unless from_date || to_date
      
      date_conditions = []
      Array(@columns[:filter][:by_date]).each do |column|
        conditions = []
        table_with_column = get_correct_table_with_column(column)
        conditions << "#{table_with_column} >= :#{column}_from_date" if from_date
        conditions << "#{table_with_column} <= :#{column}_to_date" if to_date
        date_conditions << "(" + conditions.join(" AND ") + ")"
        @values["#{column}_from_date".to_sym] = from_date if from_date
        @values["#{column}_to_date".to_sym] = to_date if to_date
      end
      
      Array(@columns[:filter][:by_span_date]).each do |columns|
        conditions = []
        table_with_column_from = get_correct_table_with_column(columns[0])
        table_with_column_to = get_correct_table_with_column(columns[1])
        conditions << "#{table_with_column_from} <= :#{columns[0]}_to_date" if to_date
        conditions << "#{table_with_column_to} >= :#{columns[1]}_from_date" if from_date
        date_conditions << "(" + conditions.join(" AND ") + ")"
        @values["#{columns[0]}_to_date".to_sym] = to_date if to_date
        @values["#{columns[1]}_from_date".to_sym] = from_date if from_date
      end
      
      @conditions << date_conditions.join(" OR ")
    end
  
    
    
    def get_correct_table_with_column(column, convert_to_belonged_model = true)
      belonged_model, belonged_column = get_belonged_model_and_column(column)
          
      if belonged_model && convert_to_belonged_model
        by_column = ActiveRecord::Base.connection.quote_column_name(belonged_column)
        unless belonged_model.is_a?(String)
          association = get_association(belonged_model)
          @include << association unless @include.include?(association)
          return "#{belonged_model.table_name}.#{by_column}"
        else
          by_model = ActiveRecord::Base.connection.quote_column_name(belonged_model)
          return "#{by_model}.#{by_column}"
        end
      else
        by_column = ActiveRecord::Base.connection.quote_column_name(column)
        return "#{@options[:model].table_name}.#{by_column}"
      end
    end
    
    
    def include_belonged_models_from_show_columns
      Array(@columns[:show]).each do |column|
        get_correct_table_with_column(column)
      end
    end
    
end 
