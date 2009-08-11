class Grid
  include SolutionsGrid::ErrorsHandling  
  include SolutionsGrid::Records::Paginate
  include SolutionsGrid::Records::Sphinx

  attr_reader :records, :options, :conditions, :values, :include, :order
  
  # Grid initialization. It constructs SQL query (with sorting and filtering
  # conditions, optionally), then fill @records by result of query. 
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
  #    Pass columns you need to allow sorting. Default is none.
  #
  # 2. <tt>[:columns][:filter]</tt>
  #    Pass hashes by format: {
  #      :date => %w{ date date2 },
  #      :sign => %w{ sign },
  #      :body => %w{ body }
  #    }
  #    Default is none.
  #
  # 3. <tt>[:sort_values]</tt>
  #    Pass column to SQL query that will be sorted and order of sorting. Example:
  #    [:sort_values] = { :column => "name", :order => "asc" }.
  #    It adds to SQL query "ORDER BY name ASC"
  #
  # 4. <tt>[:filter_values]</tt>
  #    Pass hash with format: {
  #      :date => { :type => :range, :from => { :year => '2008', :month => '1', :day => '1' }, :to => { :year => '2008', :month => '1', :day => '3' } },
  #      :sign => { :type => :strict, :value => 0 },
  #      :body => { :type => :match, :value => "bla" }
  #    }
  #    :type can be :range, :strict or :match. If it is:
  #      * :range, it filters by date range. It should contain :from and :to date hashes for filtering by these values.
  #      * :strict, it filter by equal value. It should contain :value for filtering. 
  #      * :match, it filter by matching by value. It should contain :value for filtering.
  #    If :value, :from or :to is missed, it will not be filtered by these values. (if only :from or only :to
  #    is presented, only items with date >= :from or date <= :to will be filtered).
  #
  #    SQL query conditions will look like:
  #      ((date >= 20080101 AND date <= 20080103) OR (date2 >= 20080101 AND date <= 20080103)) AND sign = 0 AND body LIKE '%bla%'
  #
  # 5. <tt>[:conditions]</tt>, <tt>[:values]</tt>, <tt>[:include]</tt>, <tt>[:joins]</tt>, <tt>[:select]</tt>, <tt>[:group]</tt>
  #    You can pass additional conditions to grid's SQL query. E.g.,
  #    [:conditions] = "user_id = :user_id"
  #    [:values] = { :user_id => "1" }
  #    [:include] = [ :user ]
  #    [:joins] = "INNER JOIN users ON users.id = content_items.user_id"
  #    [:select] = "id"
  #    [:group] = "sign"
  #    These options will be added to :find or :paginate methods.
  #
  # 6. <tt>[:paginate]</tt>
  #    If you pass [:paginate] parameter, #paginate method will be used instead of
  #    #find (i.e., you need will_paginate plugin). [:paginate] is a hash:
  #    [:paginate][:page] - page you want to see
  #    [:paginate][:per_page] - number of records per page
  #
  # 7. <tt>[:sphinx]</tt> 
  #    If you want to use Grid with Sphinx, set it to true
  def initialize(options = {})    
    @options = options 
    check_for_errors

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
      return nil if date.blank?
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
