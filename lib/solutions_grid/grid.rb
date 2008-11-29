# Main class of the SolutionGrid plugin. It stores array of records (ActiveRecord 
# objects or simple hashes). It can construct SQL query with different operations with
# these records, such as sorting and filtering. With help of GridHelper it can
# show these records as table with sortable headers, show filters.
class Grid
  include SolutionsGrid::ErrorsHandling  
  attr_accessor :view
  attr_reader :records, :options, :columns, :conditions, :values, :include, :order
  
  # To initialize grid, you should pass and +options+ as parameter.
  # 
  # == Options
  # 
  # === Required
  #
  # These options you *must* to set 
  # * <tt>:name</tt> - set name of the grid. This parameter will be used for storing
  #                    sorted and filtered info if there are more than one grid on the page. 
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
  #     @table = Grid.new(@feeds, :name => "feeds")
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
  #         :sorted => session[:sort][:feed],
  #         :name => "feeds"
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
    belonged_column = column.match(/(.*)_id(.*)/)
    if belonged_column && !belonged_column[2].blank?
      column = belonged_column[2].gsub(/^(_)/, '')
      [ belonged_column[1].camelize.constantize, column ]
    elsif belonged_column && !belonged_column[1].blank?
      [ belonged_column[1].camelize.constantize, 'name' ]
    else
      [ nil, nil ]
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
        filter_by_string
        filter_by_date
      end
      @conditions << "(" + @options[:conditions] + ")" if @options[:conditions]
      @values.merge!(@options[:values])
      @conditions = @conditions.join(" AND ")
      { :conditions => [ @conditions, @values ] }
    end
  
    
    def filter_by_string
      string = @options[:filtered] ? @options[:filtered][:by_string] : nil
      return if string.blank?
      conditions = []
      Array(@columns[:filter][:by_string]).each do |column|
        table_with_column = get_correct_table_with_column(column)
        conditions << "#{table_with_column} LIKE :#{column}"
        @values[column.to_sym] = "%#{string}%"
      end
      @conditions << "(" + conditions.join(" OR ") + ")"
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
  
    
    
    def get_correct_table_with_column(column)
      belonged_model, belonged_column = get_belonged_model_and_column(column)
          
      if belonged_model
        by_column = ActiveRecord::Base.connection.quote_column_name(belonged_column)
        association = get_association(belonged_model)
        @include << association unless @include.include?(association)
        return "#{belonged_model.table_name}.#{by_column}"
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
