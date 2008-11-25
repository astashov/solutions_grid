require File.dirname(__FILE__) + '/../spec_helper'

describe Grid do
  
  before do
    @category = mock_model(CategoryExample, :name => "somecategory", :description => "category description")
    @feed = mock_model(FeedExample, :name => "somefeed", :category_id => @category.id, :category => @category, :restricted => false, :description => "Description")
    FeedExample.stub!(:find).and_return([@feed])
    FeedExample.stub!(:table_name).and_return("feeds")
    set_column_names_and_hashes(FeedExample, :string => %w{name category_id restricted description})
    set_column_names_and_hashes(DateExample, :string => %w{description}, :date => %w{date})
    set_column_names_and_hashes(SpanDateExample, :string => %w{description}, :datetime => %w{start_datetime end_datetime})
    set_column_names_and_hashes(HABTMExample, :string => %w{description})
    @columns = %w{name category_id restricted}
  end
  
  describe "common operations"  do

    it "should copy option 'columns to show' to 'columns to sort' if 'columns to sort' is not specified" do
      grid = Grid.new(default_options.merge({ :columns => {:show => @columns.dup}}))
      grid.columns[:sort].all? { |c| @columns.include?(c) }.should be_true
    end
    
    it "should not copy option 'columns to show' to 'columns to sort' or 'columns to filter' if they are specified" do
      grid = Grid.new(default_options({ :columns => {
        :show => @columns.dup, 
        :filter => { :by_string => @columns.dup.delete_if {|column| column == 'category_id'}}, 
        :sort => @columns.dup.delete_if {|column| column == 'restricted'},
      }}))
      grid.columns[:sort].all? { |c| %w{name category_id}.include?(c) }.should be_true
      grid.columns[:filter][:by_string].all? { |c| %w{name restricted}.include?(c) }.should be_true
    end
    
  end
  
  describe "errors handling" do
  
    it "should raise an error if model is not defined" do
      lambda { Grid.new() }.should raise_error(SolutionsGrid::ErrorsHandling::ModelIsNotDefined)
    end

    it "should raise an error if we try to filter by column that not included to 'show'" do
      lambda do 
        Grid.new(default_options.merge({ :columns => { :show => @columns, :filter => { :by_string => @columns + [ 'something' ]}}}))
      end.should raise_error(SolutionsGrid::ErrorsHandling::ColumnIsNotIncludedToShow)
    end

    it "should raise an error if we try to sort by column that not included to 'show'" do
      lambda do 
        Grid.new(default_options.merge({ :columns => { :show => @columns, :sort => @columns + [ 'something' ]}}))
      end.should raise_error(SolutionsGrid::ErrorsHandling::ColumnIsNotIncludedToShow)
    end

    it "should raise an error if we try show unexisted action" do
      lambda do 
        Grid.new(default_options.merge(:actions => %w{unexisted}))
      end.should raise_error(SolutionsGrid::ErrorsHandling::UnexistedAction)
    end
    
    it "should raise an error when we trying to sort by column that forbidden to sort" do
      lambda do
        Grid.new(default_options.merge(:columns => { :show => @columns, :sort => %w{category_id}}, :sorted => { :by_column => "name"}))
      end.should raise_error(SolutionsGrid::ErrorsHandling::UnexistedColumn)
    end
    
#    it "should raise an error when :filter_by_span_date contains not 2 dates" do
#      span_dates = create_ten_span_date_mocks
#      lambda do
#        grid = Grid.new(span_dates, { :columns => { :filter => { :by_span_date => [['start_datetime', 'end_datetime', 'start_datetime']]}}}.merge(default_options))
#      end.should raise_error(SolutionsGrid::ErrorsHandling::IncorrectSpanDate)
#    end
    
#    it "should raise an error if Date To < Date From" do
#      grid = Grid.new(default_options.merge({ 
#        :columns => { 
#          :show => @columns, 
#          :filter => { :by_date => %w{date} }
#        },
#        :filtered => { :from_date => }
#          }))
#      lambda do 
#        grid.filter_by_dates({'year' => default_date.year, 'month' => default_date.month, 'day' => default_date.day + 2},
#          {'year' => default_date.year, 'month' => default_date.month, 'day' => default_date.day})
#      end.should raise_error(SolutionsGrid::ErrorsHandling::IncorrectDate)
#    end

    it "should raise an error if user didn't give a name to the grid." do
      lambda { Grid.new(:model => FeedExample) }.should raise_error(SolutionsGrid::ErrorsHandling::NameIsntSpecified)
    end

  end
  
  describe "sorting" do
  
    it "should sort records by usual column (i.e, by feed name)" do
      sort("name", 'asc') do |grid|
        grid.order.should == "feeds.`name` ASC"
      end
    end

    it "should sort records by calculated column (i.e, by feed category)" do
      sort("category_id", 'asc') do |grid|
        grid.order.should == "categories.`name` ASC"
        grid.include.should include(:category)
      end
    end
    
    it "should sort records by calculated column with specified name (i.e, by feed's category description)" do
      sort("category_id_description", 'asc', { :columns => { :show => @columns + ['category_id_description']}}) do |grid|
        grid.order.should == "categories.`description` ASC"
        grid.include.should include(:category)
      end
    end
    
    it "should sort records by calculated column (i.e, by feed category)" do
      sort("category_id", 'asc') do |grid|
        grid.order.should == "categories.`name` ASC"
        grid.include.should include(:category)
      end
    end

    it "should sort by 'desc' if other is not specified" do
      sort("name") do |grid|
        grid.order.should == "feeds.`name` DESC"
      end
    end
    
    it "should sort records by reverse order" do
      sort("name", 'desc') do |grid|
        grid.order.should == "feeds.`name` DESC"
      end
    end
  
  end
  
  describe "filtering" do
  
    it "should filter by usual column" do
      usual_filter('junk') do |grid|
        grid.conditions.should == '(feeds.`name` LIKE :name OR categories.`name` LIKE :category_id OR categories.`description` LIKE :category_id_description)'
        grid.values.keys.all? {|k| [ :name, :category_id, :category_id_description ].include?(k) }.should be_true
        grid.values[:name].should == '%junk%'
        grid.include.should == [ :category ]
      end
    end
    
    it "should filter with user-defined conditions" do
      grid = Grid.new(default_options(
        :columns => {
          :show => @columns,
          :filter => { :by_string => %w{name category_id} }
        },
        :filtered => { :by_string => 'smt' }, 
        :conditions => "feeds_partners.partner_id = :partner_id",
        :values => { :partner_id => 1 },
        :include => [ :partners ]
      ))
      grid.conditions.should == '(feeds.`name` LIKE :name OR categories.`name` LIKE :category_id) AND (feeds_partners.partner_id = :partner_id)'
      grid.values.keys.all? {|k| [ :name, :category_id, :partner_id ].include?(k) }.should be_true
      grid.values[:partner_id].should == 1
      grid.include.should == [ :category, :partners ]
    end

    it "should save all records when usual filter is empty" do
      usual_filter('') do |grid|
        grid.conditions.should == ''
        grid.values.should == {}
        grid.include.should == [:category]
      end
    end

    it "should filter records by date" do
      filter_date_example_expectations
      grid = Grid.new(default_options.merge(
          :model => DateExample,
          :columns => { :show => %w{date description}, :filter => { :by_date => %w{date} }},
          :filtered => { :from_date => { :year => "2006" }, :to_date => { :year => "2008", :month => "12" }}
      ))
      grid.conditions.should == '(date_examples.`date` >= :date_from_date AND date_examples.`date` <= :date_to_date)'
      grid.values.keys.all? {|k| [ :date_from_date, :date_to_date ].include?(k) }.should be_true
      grid.values[:date_from_date].should == DateTime.civil(2006, 1, 1)
      grid.include.should == [ ]
    end

    it "should filter records with overlapping span of date" do
      filter_date_example_expectations
      grid = Grid.new(default_options.merge(
          :model => DateExample,
          :columns => { :show => %w{start_date end_date description}, :filter => { :by_span_date => [ %w{start_date end_date} ] }},
          :filtered => { :from_date => { :year => "2006", :day => "12" }, :to_date => { :year => "2008", :month => "12", :day => "15" }}
      ))
      grid.conditions.should == "(date_examples.`start_date` <= :start_date_to_date AND date_examples.`end_date` >= :end_date_from_date)"
      grid.values.keys.all? {|k| [ :start_date_to_date, :end_date_from_date ].include?(k) }.should be_true
      grid.values[:end_date_from_date].should == DateTime.civil(2006, 1, 12)
      grid.include.should == [ ]
    end
    
    it "should filter records with overlapping span of date without start date" do
      filter_date_example_expectations
      grid = Grid.new(default_options.merge(
          :model => DateExample,
          :columns => { :show => %w{start_date end_date description}, :filter => { :by_span_date => [ %w{start_date end_date} ] }},
          :filtered => { :from_date => { :day => "12" }, :to_date => { :year => "2008", :month => "12", :day => "15" }}
      ))
      grid.conditions.should == "(date_examples.`start_date` <= :start_date_to_date)"
      grid.values.keys.should == [ :start_date_to_date ]
      grid.values[:start_date_to_date].should == DateTime.civil(2008, 12, 15)
      grid.include.should == [ ]
    end
    
    it "should filter records with overlapping span of date without end date" do
      filter_date_example_expectations
      grid = Grid.new(default_options.merge(
          :model => DateExample,
          :columns => { :show => %w{start_date end_date description}, :filter => { :by_span_date => [ %w{start_date end_date} ] }},
          :filtered => { :from_date => { :year => "2008", :day => "12" } }
      ))
      grid.conditions.should == "(date_examples.`end_date` >= :end_date_from_date)"
      grid.values.keys.should == [ :end_date_from_date ]
      grid.values[:end_date_from_date].should == DateTime.civil(2008, 1, 12)
      grid.include.should == [ ]
    end
    
    it "should filter records with overlapping span of date with string" do
      filter_date_example_expectations
      grid = Grid.new(default_options.merge(
          :model => DateExample,
          :columns => { :show => %w{start_date end_date description}, :filter => { :by_string => [ 'description' ], :by_span_date => [ %w{start_date end_date} ] }},
          :filtered => { :by_string => "text", :from_date => { :year => "2008", :day => "12" }, :to_date => { :year => "2008", :day => "16" } }
      ))
      grid.conditions.should == "(date_examples.`description` LIKE :description) AND (date_examples.`start_date` <= :start_date_to_date AND date_examples.`end_date` >= :end_date_from_date)"
      grid.values.keys.all? {|k| [:end_date_from_date, :description, :start_date_to_date].include?(k) }.should be_true
      grid.values[:end_date_from_date].should == DateTime.civil(2008, 1, 12)
      grid.include.should == [ ]
    end
    
  end
    
  
  def sort(by_column, order = nil, options = {})
    raise "Block should be given" unless block_given?
    grid = Grid.new(default_options.merge(:sorted => { :by_column => by_column, :order => order}).merge(options))
    yield(grid)
  end
  
  def usual_filter(by_string)
    raise "Block should be given" unless block_given?
    grid = Grid.new(default_options(
      :columns => {
        :show => @columns + [ "category_id_description" ],
        :filter => { :by_string => %w{name category_id category_id_description} }
      },
      :filtered => { :by_string => by_string }
    ))
    yield(grid)
  end
  
  def default_options(options = {})
    {
      :name => 'feed',
      :model => FeedExample,
      :columns => {
        :show => @columns.dup,
        :sort => %w{name category_id},
        :filter => {:by_string => %w{name category_id}}
      }
    }.merge(options)
  end
  
  def default_date
    Date.civil(2008, 10, 5)
  end
  
  def default_datetime
    DateTime.civil(2008, 10, 5, 15, 15, 0)
  end
  
  
  def filter_date_example_expectations
    date = mock_model(DateExample, :start_date => default_date, :end_date => default_date + 3.months, :description => "Desc")
    DateExample.should_receive(:find).and_return([date])
    DateExample.stub!(:table_name).and_return("date_examples")
  end
  
end