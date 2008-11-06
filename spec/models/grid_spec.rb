require File.dirname(__FILE__) + '/../spec_helper'

describe Grid do
  
  before do
    @category = mock_model(CategoryExample, :name => "somecategory")
    @feed = mock_model(FeedExample, :name => "somefeed", :category_id => @category.id, :category => @category, :restricted => false, :description => "Description")
    set_column_names_and_hashes(FeedExample, :string => %w{name category_id restricted description})
    set_column_names_and_hashes(DateExample, :string => %w{description}, :date => %w{date})
    set_column_names_and_hashes(SpanDateExample, :string => %w{description}, :datetime => %w{start_datetime end_datetime})
    set_column_names_and_hashes(HABTMExample, :string => %w{description})
    @columns = %w{name category_id restricted}
  end
  
  describe "common operations"  do
  
    it "should initialize grid even if columns are not specified" do
      grid = Grid.new(@feed, default_options)
      grid.records.should == [ @feed ]
    end    
   
    it "should copy option 'columns to show' to 'columns to filter' if 'columns to filter' is not specified" do
      grid = Grid.new(@feed, { :columns => {:show => @columns.dup}}.merge(default_options))
      grid.columns[:filter][:by_string].all? do |c| 
        @columns.include?(c.name)
      end.should be_true
    end

    it "should copy option 'columns to show' to 'columns to sort' if 'columns to sort' is not specified" do
      grid = Grid.new(@feed, { :columns => {:show => @columns.dup}}.merge(default_options))
      grid.columns[:sort].all? { |c| @columns.include?(c.name) }.should be_true
    end
  
    it "should get correct significant columns" do
      grid = Grid.new(@feed, default_options)
      grid.columns[:show].all? { |c| %w{name category_id description restricted}.include?(c.name) }.should be_true
    end
    
    it "should not copy option 'columns to show' to 'columns to sort' or 'columns to filter' if they are specified" do
      grid = Grid.new(@feed, { :columns => {
        :show => @columns.dup, 
        :filter => { :by_string => @columns.dup.delete_if {|column| column == 'category_id'}}, 
        :sort => @columns.dup.delete_if {|column| column == 'restricted'},
      }}.merge(default_options))
      grid.columns[:sort].all? { |c| %w{name category_id}.include?(c.name) }.should be_true
      grid.columns[:filter][:by_string].all? { |c| %w{name restricted}.include?(c.name) }.should be_true
    end
    
    it "should drop filtered by date columns from filtered by string columns" do
      date = mock_model(DateExample, :date => default_date, :description => "Desc")
      grid = Grid.new(date, {:columns => { :filter => { :by_date => 'date'}}}.merge(default_options))
      grid.columns[:filter][:by_date].all? { |c| %w{date}.include?(c.name) }.should be_true
      grid.columns[:filter][:by_string].all? { |c| %w{description}.include?(c.name) }.should be_true
    end
		
    it "should set columns to show correctly if there is no records and methods to display column " do
      grid = Grid.new([], { :model => FeedExample }.merge(default_options))
      grid.columns[:show].all? { |c| %w{name category_id restricted description}.include?(c.name) }.should be_true
    end
    
    it "should set columns to show correctly if records are in hash" do
      dates = [{ :date => default_date, :description => "some description" }]
      grid = Grid.new(dates, default_options)
      grid.columns[:show].all? { |c| [ 'date', 'description' ].include?(c.name) }.should be_true
    end
		
    it "should paginate ActiveRecord objects with default parameters if there is 'will paginate' plugin is installed" do
      if Object.const_defined? "WillPaginate"
        dates = []
        25.times do |i|
          dates << mock_model(DateExample, :date => default_date + i.days, :description => "Desc")
        end
        grid = Grid.new(dates, default_options)
        grid.records.size.should == 20
      end
    end
		
    it "should paginate hash correctly (with params - per_page: 5, page: 2)" do
      if Object.const_defined? "WillPaginate"
        dates = []
        15.times do |i|
          dates << { :date => default_date + i.days, :description => "some description" }
        end
        grid = Grid.new(dates, { :paginate => { :enabled => true, :per_page => 5, :page => 2 } }.merge(default_options))
        grid.records.should == dates[5..9]
      end
    end
    
  end
  
  describe "errors handling" do
  
    it "should raise an error if model is not defined" do
      lambda { Grid.new(nil, default_options) }.should raise_error(SolutionsGrid::ErrorsHandling::ModelIsNotDefined)
    end
    
    it "should raise an error if we don't have all records same type" do
      lambda { Grid.new([@feed, @category], default_options) }.should raise_error(SolutionsGrid::ErrorsHandling::DifferentTypesOfRecords)
    end  
  
    it "should raise an error if we try to show unexisted column" do
      lambda do 
        Grid.new(@feed, { :columns => {:show => @columns + [ 'something' ]} }.merge(default_options))
      end.should raise_error(SolutionsGrid::ErrorsHandling::UnexistedColumn)
    end

    it "should raise an error if we try to filter by column that not included to 'show'" do
      lambda do 
        Grid.new(@feed, { :columns => {:show => @columns, :filter => { :by_string => @columns + [ 'something' ]}}}.merge(default_options))
      end.should raise_error(SolutionsGrid::ErrorsHandling::ColumnIsNotIncludedToShow)
    end

    it "should raise an error if we try to sort by column that not included to 'show'" do
      lambda do 
        Grid.new(@feed, { :columns => {
          :show => @columns.dup.delete_if {|column| column == 'category_id'}, 
          :sort => @columns
        } }.merge(default_options))
      end.should raise_error(SolutionsGrid::ErrorsHandling::ColumnIsNotIncludedToShow)
    end

    it "should raise an error if we try show unexisted action" do
      lambda do 
        Grid.new(@feed, { :columns => { :show => @columns }, :actions => %w{unexisted}}.merge(default_options))
      end.should raise_error(SolutionsGrid::ErrorsHandling::UnexistedAction)
    end
    
    it "should raise an error when we trying to sort by column that forbidden to sort" do
      grid = Grid.new(@feed, { :columns => { :show => @columns, :sort => %w{category_id}}}.merge(default_options))
      lambda { grid.sort('name', 'asc') }.should raise_error(SolutionsGrid::ErrorsHandling::UnexistedColumn)
    end
    
    it "should raise an error when :filter_by_span_date contains not 2 dates" do
      span_dates = create_ten_span_date_mocks
      lambda do
        grid = Grid.new(span_dates, { :columns => { :filter => { :by_span_date => [['start_datetime', 'end_datetime', 'start_datetime']]}}}.merge(default_options))
      end.should raise_error(SolutionsGrid::ErrorsHandling::IncorrectSpanDate)
    end
    
    it "should raise an error if Date To < Date From" do
      date = mock_model(DateExample, :date => default_date, :description => "Desc")
      grid = Grid.new(date, { :columns => { :filter => { :by_date => %w{date} }}}.merge(default_options))
      lambda do 
        grid.filter_by_dates({'year' => default_date.year, 'month' => default_date.month, 'day' => default_date.day + 2},
          {'year' => default_date.year, 'month' => default_date.month, 'day' => default_date.day})
      end.should raise_error(SolutionsGrid::ErrorsHandling::IncorrectDate)
    end
		
    it "should raise an error if options[:paginate] is setted, but there is no 'will paginate' plugin" do
      Object.should_receive(:const_defined?).with("WillPaginate").and_return(false)
      lambda do 
        grid = Grid.new(@feed, { :paginate => { :enabled => true } }.merge(default_options))
      end.should raise_error(SolutionsGrid::ErrorsHandling::WillPaginateIsNotInstalled)
    end
    
    it "should raise an error if user didn't give a name to the grid." do
      lambda { Grid.new(@feed, :controller => 'feed_example', :action => 'index') }.should raise_error(SolutionsGrid::ErrorsHandling::NameIsntSpecified)
    end

  end
  
  describe "sorting" do
  
    it "should sort records by usual column (i.e, by feed name)" do
      sort("name", 'asc') do |feeds|
        feeds.sort {|a, b| a.name <=> b.name}
      end
    end

    it "should sort records by calculated column (i.e, by feed category)" do
      sort("category_id", 'asc') do |feeds|
        feeds.sort {|a, b| a.category.name <=> b.category.name}
      end
    end

    it "should sort records by column without helper method (i.e, by feed description)" do
      sort("description", 'asc') do |feeds|
        feeds.sort {|a, b| a.description.to_s <=> b.description.to_s}
      end
    end


    it "should sort by 'asc' if other is not specified" do
      sort("name") do |feeds|
        feeds.sort {|a, b| a.name <=> b.name}
      end
    end
    
    it "should sort records by reverse order" do
      sort("name", 'desc') do |feeds|
        feeds.sort {|a, b| b.name <=> a.name}
      end
    end

    it "should remember sorted column after sort" do
      grid = Grid.new(@feed, { :columns => { :show => @columns }}.merge(default_options))
      grid.sort('name', 'asc')
      grid.options[:sorted][:by_column].should == 'name'
      grid.options[:sorted][:order].should == 'asc'
    end

    it "should sort while initialize if :sorted parameter is given" do
      feeds = create_ten_feed_mocks
      grid = Grid.new(feeds, { :columns => { :show => @columns }, :sorted => {:by_column => 'name', :order => 'asc'}}.merge(default_options))
      feeds_sorted = feeds.sort {|a, b| a.name <=> b.name}
      grid.records.map { |r| r.name }.should == feeds_sorted.map { |r| r.name }
    end
  
  end
  
  describe "filtering" do
  
    it "should filter by usual column" do
      usual_filter('junk', 3, %w{name description}) do |r|
        r.name.include?('junk') || r.description.include?('junk')
      end
    end

    it "should save all records when usual filter is empty" do
      usual_filter('', 10, %w{name description}) { |r| true }
    end

    it "should filter by usual column with RegExps" do
      usual_filter('j[nu]+k', 3, %w{name description}) do |r|
        r.name.include?('junk') || r.description.include?('junk')
      end
    end

    it "should filter by some column with id (i.e., category_id)" do
      usual_filter('Daily', 2, %w{name category_id description}) do |r|
        r.category.name.include?('Daily')
      end
    end

    it "should filter by some calculated column (i.e., restricted)" do
      SolutionsGrid::GridHelper.class_eval do
        define_method(:feed_example_restricted) do |record|
          value = record ? record.restricted : nil
          { :key => "Name", :value => value ? "Yes" : "No" }
        end
      end
      usual_filter('Yes', 3, %w{name restricted description}) do |r|
        r.restricted.should be_true
      end
    end

    it "should filter while initialize if :filtered parameter is given" do
      feeds = create_ten_feed_mocks
      grid = Grid.new(feeds, { :columns => { :filter => { :by_string => %w{name description} }}, :filtered => { :by_string => 'junk' }}.merge(default_options))
      grid.records.size.should == 3
    end

    it "should filter records by date" do
      dates = create_ten_date_mocks
      grid = Grid.new(dates, { :columns => { :filter => { :by_date => %w{date} }}}.merge(default_options))
      grid.filter_by_dates(default_date, default_date + 2)
      grid.records.size.should == 3
      grid.records.each do |record|
        verify = record.date >= default_date && record.date <= default_date + 2
        verify.should be_true
      end
    end

    it "should filter records by date if date transmitted as Hash" do
      dates = create_ten_date_mocks
      grid = Grid.new(dates, { :columns => { :filter => { :by_date => %w{date} }} }.merge(default_options))
      grid.filter_by_dates({'year' => default_date.year, 'month' => default_date.month, 'day' => default_date.day},
                          {'year' => default_date.year, 'month' => default_date.month, 'day' => default_date.day + 2})
      grid.records.size.should == 3
      grid.records.each do |record|
        verify = record.date >= default_date && record.date <= default_date + 2
        verify.should be_true
      end
    end

    it "should filter records with overlapping span of date" do
      span_dates = create_ten_span_date_mocks
      grid = Grid.new(span_dates, { :columns => { :filter => { :by_span_date => [['start_datetime', 'end_datetime']]}} }.merge(default_options))
      grid.filter_by_dates(default_datetime + 4.minutes, default_datetime + 5.minutes)
      grid.records.size.should == 6
      grid.records.each do |record|
        verify = (default_datetime + 4.minutes >= record.start_datetime && default_datetime + 4.minutes <= record.end_datetime) || 
                 (default_datetime + 5.minutes >= record.start_datetime && default_datetime + 5.minutes <= record.end_datetime)
        verify.should be_true
      end
    end
    
    it "should leave all records alone if we trying to filter with incorrect format of start and end dates" do
      dates = create_ten_date_mocks
      grid = Grid.new(dates, { :columns => { :filter => { :by_date => %w{date} }}}.merge(default_options))
      grid.filter_by_dates('some', 'format')
      grid.records.size.should == 10
    end
    
    it "should filter all records by date with date more than from_date if we trying to filter only with from_date" do
      dates = create_ten_date_mocks
      grid = Grid.new(dates, { :columns => { :filter => { :by_date => %w{date} }}}.merge(default_options))
      grid.filter_by_dates(default_date + 7.days, nil)
      grid.records.size.should == 3
    end
    
    it "should filter all records by date with date less than to_date if we trying to filter only with to_date" do
      dates = create_ten_date_mocks
      grid = Grid.new(dates, { :columns => { :filter => { :by_date => %w{date} }}}.merge(default_options))
      grid.filter_by_dates(nil, default_date + 3.days)
      grid.records.size.should == 4
    end
    
    it "should filter all records by span of date only with from_date" do
      span_dates = create_ten_span_date_mocks
      grid = Grid.new(span_dates, { :columns => { :filter => { :by_span_date => [['start_datetime', 'end_datetime']]}}}.merge(default_options))
      grid.filter_by_dates(default_datetime + 3.minutes, nil)
      grid.records.size.should == 7
      grid.records.each do |record|
        (default_datetime + 3.minutes >= record.start_datetime).should be_true
      end
    end
    
    it "should filter all records by span of date only with to_date" do
      span_dates = create_ten_span_date_mocks
      grid = Grid.new(span_dates, { :columns => { :filter => { :by_span_date => [['start_datetime', 'end_datetime']]}}}.merge(default_options))
      grid.filter_by_dates(nil, default_datetime - 4.minutes)
      grid.records.size.should == 7
      grid.records.each do |record|
        (default_datetime - 4.minutes <= record.end_datetime).should be_true
      end
    end
  end
  
  
  def sort(by_column, order = nil)
    raise "Block should be given" unless block_given?
    feeds = create_ten_feed_mocks
    grid = Grid.new(feeds, default_options)
    grid.sort(by_column, order)
    feeds_sorted = yield(feeds)
    grid.records.map { |r| r.send(by_column) }.should == feeds_sorted.map { |r| r.send(by_column) }
  end
  
  def usual_filter(by_column, expected_count, filter_columns)
    feeds = create_ten_feed_mocks
    grid = Grid.new(feeds, { :columns => { :filter => { :by_string => filter_columns}}}.merge(default_options))
    grid.filter_by_string(by_column)
    grid.records.size.should == expected_count
    verify = true
    grid.records.each do |r|
      verify = yield(r)
      break unless verify
    end
    verify.should be_true
  end
  
  def create_ten_feed_mocks
    feeds = [ @feed ]
    category_daily = mock_model(CategoryExample, :name => "Daily")
    category_nightly = mock_model(CategoryExample, :name => "Nightly")
    feeds << create_feed_mock("feed one", "aweome", false, category_daily)
    feeds << create_feed_mock("feed two", "desc some", false, category_daily)
    feeds << create_feed_mock("junk three", "description junk", false, category_nightly)
    feeds << create_feed_mock("junk four", "just feed", true)
    feeds << create_feed_mock("another five", "trash", true)
    feeds << create_feed_mock("somefeed six", "junk", false, category_nightly)
    feeds << create_feed_mock("somefeed seven", "description something")
    feeds << create_feed_mock("trash eight", "good thing", true, category_nightly)
    feeds << create_feed_mock("just nine", "description feed")
    feeds
  end
  
  def create_ten_date_mocks
    dates = []
    10.times do |i|
      dates << mock_model(DateExample, :date => default_date + i.days, :description => "Desc")
    end
    dates
  end
  
  def create_ten_span_date_mocks
    span_dates = []
    10.times do |i|
      span_dates << mock_model(SpanDateExample, :start_datetime => default_datetime - 10.minutes + i.minutes, 
        :end_datetime => default_datetime + i.minutes, :description => "Desc")
    end
    span_dates
  end
  
  def create_feed_mock(name, description, restricted = false, category = @category)
    mock_model(FeedExample, :name => name, :category_id => category.id, 
      :category => category, :description => description, :restricted => restricted)
  end
  
  def default_options
    {
      :name => 'feed'
    }
  end
  
  def default_date
    Date.civil(2008, 10, 5)
  end
  
  def default_datetime
    DateTime.civil(2008, 10, 5, 15, 15, 0)
  end
  
end