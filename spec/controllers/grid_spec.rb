require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationController, "SolutionsGrid" do
  integrate_views
  
  before do
    controller.instance_variable_set("@template", ActionView::Base.new([], {}, controller))
    @category = mock_model(CategoryExample, :name => "somecategory", :description => "category description")
    @feed = mock_model(FeedExample, :name => "somefeed", :category_example_id => @category.id, :category => @category, :restricted => false, :description => "Description")
    FeedExample.stub!(:table_name).and_return("feeds")
    CategoryExample.stub!(:table_name).and_return("categories")
    DateExample.stub!(:table_name).and_return("dates")
    set_column_names_and_hashes(FeedExample, :string => %w{name category_example_id restricted description})
    set_column_names_and_hashes(DateExample, :string => %w{description}, :date => %w{date})
    set_column_names_and_hashes(SpanDateExample, :string => %w{description}, :datetime => %w{start_datetime end_datetime})
    set_column_names_and_hashes(HABTMExample, :string => %w{description})
    @columns = %w{name category_example_id restricted}
  end
  
  describe "errors handling" do
  
    it "should raise an error if model is not defined" do
      lambda { Grid.new() }.should raise_error(SolutionsGrid::ErrorsHandling::ModelIsNotDefined)
    end

  end
  
  describe "sorting" do
  
    it "should sort records by usual column (i.e, by feed name)" do
      FeedExample.should_receive(:find).with(:all, :order => "feeds.`name` ASC").and_return([@feed])
      controller.get_grid(default_options.merge(
        :sort_values => { 
          :column => "name", 
          :order => "asc"
        }
      ).merge(options))
    end

    it "should sort records by calculated column (i.e, by feed category)"# do
#      sort("category_example_id", 'asc') do |grid|
#        grid.order.should == "categories.`name` ASC"
#        grid.include.should include(:category_example)
#      end
#    end
#    
#    it "should sort records by calculated column with specified name (i.e, by feed's category description)" do
#      sort("category_example_id_description", 'asc', { :columns => { :show => @columns + ['category_example_id_description']}}) do |grid|
#        grid.order.should == "categories.`description` ASC"
#        grid.include.should include(:category_example)
#      end
#    end
    
    it "should sort by 'desc' if other is not specified" do
      controller.instance_variable_set("@template", ActionView::Base.new([], {}, controller))
      FeedExample.should_receive(:find).with(:all, :order => "feeds.`name` DESC").and_return([@feed])
      grid = controller.get_grid(default_options.merge(
        :sort_values => { :column => "name" }
      ).merge(options))
    end
    
    it "should sort records by reverse order" do
      FeedExample.should_receive(:find).with(:all, :order => "feeds.`name` DESC").and_return([@feed])
      controller.get_grid(default_options.merge(
        :sort_values => { 
          :column => "name", 
          :order => "desc"
        }
      ).merge(options))
    end
  
  end
  
  describe "filtering" do
  
    it "should filter by usual column with match type of search" do
      FeedExample.should_receive(:find).with(
        :all, 
        :conditions => [
          "((feeds.`name` LIKE :name OR feeds.`category_example_id` LIKE :category_example_id))", 
          { :name => "%junk%", :category_example_id => "%junk%" }
        ]
      ).and_return([@feed])
      session[:filter] = { :feed_examples => { :text => "junk" } }
      controller.get_grid(default_options.merge(
        :filter_values => { :text => { :type => :match } }
      ).merge(options))
    end

    it "should filter by usual column with strict type of search" do
      FeedExample.should_receive(:find).with(
        :all, 
        :conditions => [
          "((feeds.`name` = :name OR feeds.`category_example_id` = :category_example_id))", 
          { :name => "junk", :category_example_id => "junk" }
        ]
      ).and_return([@feed])
      session[:filter] = { :feed_examples => { :text => "junk" } }
      controller.get_grid(default_options.merge(
        :filter_values => { :text => { :type => :strict } }
      ).merge(options))
    end

    
    it "should filter by some usual columns" do
      FeedExample.should_receive(:find).with(
        :all, 
        :conditions => [
          "((feeds.`name` LIKE :name) AND (feeds.`category_example_id` = :category_example_id))", 
          { :name => "%junk%", :category_example_id => "4" }
        ]
      ).and_return([@feed])
      session[:filter] = { :feed_examples => { :by_string => "junk", :by_category_example_id => "4" } }
      controller.get_grid(default_options.merge(
        :columns => {
          :show => @columns,
          :sort => @columns,
          :filter => { 
            :by_string => %w{name},
            :by_category_example_id => %w{category_example_id}
          }
        },
        :filter_values => { 
          :by_string => { :type => :match }, 
          :by_category_example_id => { :type => :strict, :convert_id => false } 
        }
      ))
    end
    
    it "should filter by belonged column that contains _id"# do
#      grid = Grid.new(default_options(
#        :columns => {
#          :show => @columns + [ "category_example_id_description_id" ],
#          :filter => { 
#            :by_string => %w{name},
#            :by_category_example_id => %w{category_example_id_description_id}
#          }
#        },
#        :filtered => { :by_string => { :text => "junk", :type => :match }, :by_category_example_id => { :text => "4", :type => :strict } }
#      ))
#      grid.conditions.should == "((feeds.`name` LIKE :name) AND (categories.`description_id` = :category_example_id_description_id))"
#      grid.values.keys.all? {|k| [ :name, :category_example_id, :category_example_id_description_id ].include?(k) }.should be_true
#      grid.values[:name].should == '%junk%'
#      grid.values[:category_example_id_description_id].should == '4'
#      grid.include.should == [ :category_example ]
#    end
#    
#    it "should filter by table.column if dot is presented" do
#      grid = Grid.new(default_options(
#        :columns => {
#          :show => @columns + [ "category_example_id" ],
#          :filter => { 
#            :by_string => %w{name},
#            :by_category_example_id => %w{category_examples.description_id}
#          }
#        },
#        :filtered => { :by_string => { :text => "junk", :type => :match }, :by_category_example_id => { :text => "4", :type => :strict } }
#      ))
#      grid.conditions.should == "((feeds.`name` LIKE :name) AND (`category_examples`.`description_id` = :description_id))"
#      grid.values.keys.all? {|k| [ :name, :description_id ].include?(k) }.should be_true
#      grid.values[:name].should == '%junk%'
#      grid.values[:description_id].should == '4'
#      grid.include.should == [ :category_example ]
#    end
#    
    it "should filter with user-defined conditions" do
      FeedExample.should_receive(:find).with(
        :all, 
        :conditions => ["(partner_id = :partner_id)", { :partner_id => 1}]
      ).and_return([@feed])
      controller.get_grid(default_options.merge(
        :conditions => "partner_id = :partner_id",
        :values => { :partner_id => 1 }
      ))
    end

    it "should save all records when usual filter is empty" do
      FeedExample.should_receive(:find).with(:all, {}).and_return([@feed])
      controller.get_grid(default_options)
    end

    it "should filter records by date" do
      @date = mock_model(DateExample, :date => 20080101, :description => "date description")
      DateExample.should_receive(:find).with(:all, {
        :conditions => 
          [
            "((dates.`date` >= :date_from OR dates.`date` <= :date_to))", 
            { :date_from => 20080600, :date_to => 20090000 }
          ]
      }).and_return([@date])
      session[:filter] = { :date_examples => { :date => { 
        :from => { :year => '2008', :month => '6' }, :to => { :year => '2009' }
      }}}
      controller.get_grid(default_options.merge(
        :model => DateExample,
        :columns => { :show => %w{date description}, :filter => { :date => %w{date} }},
        :filter_values => { :date => { :type => :range }}
      ))
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
        :show => @columns + [ "category_example_id_description" ],
        :filter => { :by_string => %w{name category_example_id category_example_id_description} }
      },
      :filtered => { :by_string => { :value => by_string, :type => :match } }
    ))
    yield(grid)
  end
  
  def default_options(options = {})
    {
      :model => FeedExample,
      :columns => {
        :show => %w{name category_example_id},
        :sort => %w{name category_example_id},
        :filter => {:text => %w{name category_example_id}}
      },
      :paginate => nil
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
