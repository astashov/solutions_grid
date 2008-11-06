# Main class of the SolutionGrid plugin. It stores array of records (records can be 
# ActiveRecord objects or simple hashes). It can execute different operations with
# these records, such as sorting and filtering. With help of GridHelper it can
# show these records as table with sortable headers, show filters.
class Grid
  include SolutionsGrid::ErrorsHandling
  # To initialize grid, you should pass +records+ and +options+ as parameters.
  # +Records+ can be ActiveRecord objects or just simple hashes. +Options+ change
  # default options, it is not required parameter.
  # 
  # 
  # == Options
  # * <tt>:name</tt> - set name if there are more than one grid on the page. It's <b>required</b> parameter.
  # * <tt>:model</tt> - set model. It will be used for constructing column names,
  #                     if columns is not specified obviously and there are no records
  #                     specified for displaying. 
  # * <tt>:columns</tt> - sets columns of records to show, filter and sort. Pass columns as arrays.
  # * -> <tt>[:columns][:show]</tt> - pass columns you need to show (as array, do you remember? :))
  # * -> <tt>[:columns][:sort]</tt> - pass columns you need to allow sorting.
  # * -> <tt>[:columns][:filter][:by_string]</tt> - pass columns you need to allow filtering by string.
  # * -> <tt>[:columns][:filter][:by_date]</tt> - pass columns you need to allow filtering by date.
  # * -> <tt>[:columns][:filter][:by_span_date]</tt> - pass columns you need to allow filtering by span of date.
  #                                                   You should pass columns as array of arrays 
  #                                                   (format of arrays - [ start_date_column, end_date_column ])
  # * <tt>:filter_path</tt> - set path to send filter requests. This path should lead to action, 
  #                           that write filter to session. You should pass hash with keys:
  #                           <tt>:controller</tt> - the controller that contains the sort action,
  #                           <tt>:action</tt>
  #                           See details below.
  # * <tt>:sort_path</tt> - set path to send sort requests. This path should lead to action, 
  #                         that write sort column to session. See details below. Syntax is similar to <tt>:filter_path</tt>
  # * <tt>:actions</tt> - pass necessary actions (such as 'edit', 'destroy', 'duplicate'). Details about actions see below.
  # * <tt>:filtered</tt> - pass hash with parameters:
  # * -> <tt>[:filtered][:by_string]</tt> - if you pass string, all 'filtered by string' columns will be filtered by this string
  # * -> <tt>[:filtered][:by_date]</tt> - if you pass date (in Date or DateTime format), all 
  #                                      'filtered by date' columns will be filtered by this date
  # * -> <tt>[:filtered][:by_span_date]</tt> - if you pass array of 2 dates (start date and end date)
  #                                           (in Date or DateTime format), all 'filtered by span of date' 
  #                                           columns will be filtered by this span
  # * <tt>:type_of_date_filtering</tt> - show filter form with date or datetime select boxes. If you display Hashes,
  #                                      it will show Date by default. If you display ActiveRecord objects,
  #                                      there will try to decide about select boxed automatically.
  #                                      You can pass Date or DateTime parameters.
  # 
  #                                                                                     
  # == Default values of the options
  # * <tt>[:columns][:show]</tt> - all columns of the table, except 'id', 'updated_at', 'created_at'.
  # * <tt>[:columns][:sort]</tt> - default is equal [:columns][:show]
  # * <tt>[:columns][:filter][:by_string]</tt> - default is equal [:columns][:show]
  # * <tt>[:columns][:filter][:by_date]</tt> - default is empty array
  # * <tt>[:columns][:filter][:by_span_date]</tt> - default is empty array
  # * <tt>[:actions]</tt> - default is empty array
  # * <tt>[:filtered]</tt> - default is empty hash
  # * <tt>[:sorted]</tt> - default is empty hash
  # 
  # 
  # == About custom display of actions and values
  # You can create your own rules to display columns (i.e., you need to show 'Yes' if some boolean
  # column is true, and 'No' if it is false). For that, you should add method with name
  # modelname_columnname to SolutionGrid::GridHelper. You should create 'attributes' folder in
  # app/helper and create file with filename modelname.rb. Let's implement example above:
  # 
  # We have model Feed with boolean column 'restricted'. We should write in /app/helpers/attributes/feed.rb
  # 
  #   module SolutionsGrid::GridHelper
  #     def feed_restricted(record = nil)
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
  # * If column looks like 'category_id', the plugin will try to display 'name' column of belonging table 'categories'.
  # * If column doesn't look like 'something_id' or there is no column 'name' of belonging table, or there is no 
  #   belonging table, the plugin just display value of this column.
  #   
  # You should add actions that you plan to use to module SolutionsGrid::GridHelper by similar way.
  # Example for 'edit' action, file 'app/helpers/attributes/actions.rb':
  # 
  #   module SolutionsGrid::GridHelper
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
  # To sort and filter records of the grid you MUST pass options <tt>:filtered</tt> or <tt>:sorted</tt>. This parameters contain:
  # * <tt>[:sorted][:by_column]</tt> - you should pass column you want to sort
  # * <tt>[:sorted][:order]</tt> - you can pass order of sorting ('asc' or 'desc'). Default is 'asc'.
  # * <tt>[:filtered][:by_string] - you can pass string, and columns you described in [:column][:filter][:by_string] will be filtered by this string.
  # * <tt>[:filtered][:by_date] - you can pass date, and columns you described in [:column][:filter][:by_date] will be filtered by this date.
  # * <tt>[:filtered][:by_span_date] - you can pass array [ start_date, end_date ], and columns you described in [:column][:filter][:by_span_date] will be filtered by overlapping this span.
  # 
  # == Examples of use the SolutionGrid
  # <i>in controller:</i>
  # 
  #   def index
  #     @feeds = Feed.find(:all)
  #     @table = Grid.new(@feeds)
  #   end
  # 
  # <i>in view:</i>
  # 
  #   show_grid(@table)
  #   
  # It will display feeds with all columns defined in Feed model, except 'id', 'updated_at'
  # and 'created_at'. There will be no actions and filterable columns, all columns will be sortable, 
  # but because you don't pass <tt>:sorted</tt> option, sort will not work.
  # 
  # 
  # <i>in controller:</i>
  #   def index
  #     @feeds = Feed.find(:all)
  #     @table = Grid.new(
  #       @feeds, {
  #         :columns => {
  #           :show => %w{name description}, 
  #           :sort => %w{name}
  #         }, 
  #         :sorted => session[:sort][:feed]
  #       }
  #     )
  #   end
  # 
  # <i>in view:</i>
  #   show_grid(@table)
  #   
  # It will display feeds with columns 'name' and 'description'. There will be no actions and 
  # filterable columns, 'name' column will be sortable, column to sort stores in session[:sort][:feed][:by_column].
  # 
  # 
  # <i>in controller:</i>
  #   def index
  #     @feeds = Feed.find(:all)
  #     @table = Grid.new(
  #       @feeds, {
  #         :columns => {
  #           :show => %w{name description}, 
  #           :filter => { 
  #             :by_string => %w{name}
  #           },
  #         }, 
  #         :sorted => session[:sort][:feed],
  #         :filtered => session[:filter][:feed],
  #         :actions => %w{edit delete}
  #       }
  #     )
  #   end
  # 
  # <i>in view:</i>
  #   show_grid(@table)
  #   
  # It will display feeds with columns 'name' and 'description'. These columns will be sortable.
  # There will be actions 'edit' and 'delete' (but remember, you need action methods
  # 'action_edit' and 'action_delete' in SolutionGrid::GridHelper in 'app/helpers/attributes/actions.rb').
  # There will be filterable column 'name', and it will be filtered by session[:filter][:feed][:by_string] value.
  def initialize(records = [], options = {})
    # BTW, This is just proxy for true grid object
    
    options[:model] = try_to_define_model(options[:model], Array(records).first)
    @grid = case 
      when options[:model] == Hash
        SolutionsGrid::HashGrid.new(records, options)
      else
        SolutionsGrid::ActiveRecordGrid.new(records, options)
      end
      
    
  end
  
  private
  
    def try_to_define_model(model, record)
      return model if model
      return record.class if record
      raise ModelIsNotDefined, "You should define model" unless model
    end
  
    def method_missing(name, *args)
      args.empty? ? @grid.send(name) : @grid.send(name, *args)
    end

end


class SolutionsGrid::CommonGrid
  
  include SolutionsGrid::ErrorsHandling
  include SolutionsGrid::GridHelper
  include SolutionsGrid::Sort
  include SolutionsGrid::Filter

  def initialize(records = [], options = {})
    @records = Array(records)
    
    # Initialization of options
    @options = {}
    
    @options[:name] = options[:name].to_s if options[:name]
    @options[:model] = options[:model]
    @options[:model] ||= @records[0].class unless @records.empty?    
    @options[:modelname] = @options[:model].to_s.underscore
    @options[:actions] = Array(options[:actions]) || []
    @options[:type_of_date_filtering] = set_type_of_date(options[:type_of_date_filtering])
    
    @options[:filtered] = options[:filtered]
    @options[:sorted] = options[:sorted]
    
    initialize_pagination(options[:paginate])

    options[:columns] ||= {}
    options[:columns][:filter] ||= {}
    
    initialize_columns(options[:columns])

    check_for_errors

    # Filtering...
    if @options[:filtered].is_a?(Hash)
      filter_by_string(@options[:filtered][:by_string]) if @options[:filtered][:by_string]
      filter_by_dates(@options[:filtered][:from_date], @options[:filtered][:to_date]) if @options[:filtered][:from_date] || @options[:filtered][:to_date]
    end
    
    # Sorting...
    if @options[:sorted].is_a?(Hash)
      sort(@options[:sorted][:by_column], @options[:sorted][:order]) 
    end
		
    # Paginating...
    if @options[:paginate][:enabled]
      @records = @records.paginate(
        :page => @options[:paginate][:page] || 1, 
        :per_page => @options[:paginate][:per_page] || 20
      )
    end
  end
  
  private
  
    def initialize_pagination(options_paginate)
      unless options_paginate
        @options[:paginate] = { :enabled => Object.const_defined?("WillPaginate") }
      else
        @options[:paginate] = {
          :enabled => options_paginate[:enabled],
          :page => options_paginate[:page],
          :per_page => options_paginate[:per_page]
        }
      end
    end
  
    def initialize_columns(columns)
      @columns = {}
      @columns[:show] = initialize_show_columns(columns[:show] || significant_columns)
      @columns[:sort] = initialize_sort_or_filter_by_string_columns(columns[:sort])
      @columns[:filter] = {}
      @columns[:filter][:by_string] = initialize_sort_or_filter_by_string_columns(columns[:filter][:by_string])
      @columns[:filter][:by_date] = initialize_filter_columns_by_date(columns[:filter][:by_date])
      @columns[:filter][:by_span_date] = initialize_filter_by_span_date(columns[:filter][:by_span_date])
    end

    def initialize_sort_or_filter_by_string_columns(column_names)
      return @columns[:show].dup unless column_names
      columns = []
      Array(column_names).each do |column_name|
        verify_that_given_column_is_included_to_show_columns(column_name)
        columns << @columns[:show].select { |column| column.name == column_name }.first
      end
      columns
    end

    def initialize_filter_columns_by_date(column_names)
      return [] unless column_names
      columns = []
      Array(column_names).each do |column_name|
        verify_that_given_column_is_included_to_show_columns(column_name)
        delete_column_from_filter_by_string_columns(column_name)
        column = @columns[:show].select { |column| column.name == column_name }.first
        column.type = @options[:type_of_date_filtering]
        columns << column
      end
      columns
    end

    def initialize_filter_by_span_date(column_names)
      return [] unless column_names
      columns = []
      Array(column_names).each do |from_and_to_date_columns|
        date_columns = []
        verify_that_array_contains_date_from_and_date_to(from_and_to_date_columns)
        from_and_to_date_columns.each do |column_name|
          verify_that_given_column_is_included_to_show_columns(column_name)
          delete_column_from_filter_by_string_columns(column_name)
          column = @columns[:show].select { |column| column.name == column_name }.first
          column.type = @options[:type_of_date_filtering]
          date_columns << column
        end
        columns << date_columns
      end
      columns
    end

    def delete_column_from_filter_by_string_columns(column_name)
      if @columns[:filter][:by_string]
        @columns[:filter][:by_string].delete_if { |column| column.name == column_name}
      end
    end
  
end 