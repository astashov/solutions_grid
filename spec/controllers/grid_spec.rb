require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationController, "SolutionsGrid" do
  integrate_views
  
  before do
    controller.instance_variable_set("@template", ActionView::Base.new([], {}, controller))
    @columns = %w{name category_example_id}
    @category = mock_model(CategoryExample, :name => "somecategory", 
      :description => "category description")
    @feed = mock_model(FeedExample, :name => "somefeed", 
      :category_example_id => @category.id, :category_example => @category, 
      :description => "Description")
    FeedExample.stub!(:table_name).and_return("feeds")
    DateExample.stub!(:table_name).and_return("dates")
  end
  

  describe "errors handling" do
  
    it "should raise an error if model is not defined" do
      lambda { Grid.new() }.should raise_error(SolutionsGrid::ErrorsHandling::ModelIsNotDefined)
    end

  end
  

  describe "sorting by ActiveRecord" do
  
    it "should sort records by usual column (i.e, by feed name)" do
      FeedExample.should_receive(:find).with(:all, :order => "feeds.`name` ASC").and_return([@feed])
      controller.get_grid(default_options.merge(
        :sort_values => { 
          :column => "name", 
          :order => "asc"
        }
      ).merge(options))
    end

    it "should sort records by calculated column (i.e, by feed category)" do
      FeedExample.should_receive(:find).with(
        :all, 
        :order => "category_examples.`name` ASC", 
        :include => [ :category_example ]
      ).and_return([@feed])
      controller.get_grid(default_options.merge(
        :sort_values => { 
          :column => "category_example_id", 
          :order => "asc"
        }
      ).merge(options))
    end
    
    it "should sort by 'desc' if other is not specified" do
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
  

  describe "filtering by ActiveRecord" do
  
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
          :by_category_example_id => { :type => :strict } 
        }
      ))
    end

    it "should filter by table.column if dot is presented" do
      FeedExample.should_receive(:find).with(
        :all, 
        :conditions => [
          "((feeds.`name` LIKE :name) AND (category_examples.`description` = :description))", 
          { :name => "%junk%", :description => "4" }
        ]
      ).and_return([@feed])
      session[:filter] = { :feed_examples => { :by_string => "junk", :description => "4" } }
      controller.get_grid(default_options.merge(
        :columns => {
          :show => @columns,
          :filter => { 
            :by_string => %w{name},
            :description => %w{category_examples.description}
          }
        },
        :filter_values => { 
          :by_string => { :value => "junk", :type => :match }, 
          :description => { :value => "4", :type => :strict } 
        }
      ))
    end

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
            "((dates.`date` >= :date_from AND dates.`date` <= :date_to))", 
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


  describe "sorting by Sphinx" do

    it "should sort records by usual column (i.e, by feed name)" do
      FeedExample.should_receive(:search).with('', :order => :name, :sort_mode => :asc).and_return([@feed])
      controller.get_grid(default_options.merge(
        :sort_values => { 
          :column => "name", 
          :order => "asc"
        },
        :sphinx => true
      ).merge(options))
    end

    it "should sort records by calculated column (i.e, by feed category)" do
      FeedExample.should_receive(:search).with('', :order => :category_example_name, :sort_mode => :asc).and_return([@feed])
      controller.get_grid(default_options.merge(
        :sort_values => { 
          :column => "category_example_id", 
          :order => "asc"
        },
        :sphinx => true
      ).merge(options))
    end
    
    it "should sort by 'desc' if other is not specified" do
      FeedExample.should_receive(:search).with('', :order => :name, :sort_mode => :desc).and_return([@feed])
      grid = controller.get_grid(default_options.merge(
        :sort_values => { :column => "name" },
        :sphinx => true
      ).merge(options))
    end
    
    it "should sort records by reverse order" do
      FeedExample.should_receive(:search).with('', :order => :name, :sort_mode => :desc).and_return([@feed])
      grid = controller.get_grid(default_options.merge(
        :sort_values => { 
          :column => "name", 
          :order => "desc"
        },
        :sphinx => true
      ).merge(options))
    end

  end


  describe "filtering by Sphinx" do

    it "should filter by usual column with match type of search" do
      FeedExample.should_receive(:search).with('', :conditions => { :text => "junk" }).and_return([@feed])
      session[:filter] = { :feed_examples => { :text => "junk" } }
      controller.get_grid(default_options.merge(
        :filter_values => { :text => { :type => :match } },
        :sphinx => true
      ).merge(options))
    end

    it "should filter by usual column with strict type of search" do
      FeedExample.should_receive(:search).with('', :with => { :text => "junk" }).and_return([@feed])
      session[:filter] = { :feed_examples => { :text => "junk" } }
      controller.get_grid(default_options.merge(
        :filter_values => { :text => { :type => :strict } },
        :sphinx => true
      ).merge(options))
    end

    it "should filter by some usual columns" do
      FeedExample.should_receive(:search).with('', 
        :with => { :by_category_example_id => "4" },
        :conditions => { :by_string => "junk" }
      ).and_return([@feed])
      session[:filter] = { :feed_examples => { :by_string => "junk", :by_category_example_id => "4" } }
      controller.get_grid(default_options.merge(
        :filter_values => { 
          :by_string => { :type => :match }, 
          :by_category_example_id => { :type => :strict } 
        },
        :sphinx => true
      ))
    end

    it "should filter with user-defined conditions" do
      FeedExample.should_receive(:search).with('', 
        :with => { :partner_id => "1" }
      ).and_return([@feed])
      controller.get_grid(default_options.merge(
        :with => { :partner_id => "1" },
        :sphinx => true
      ))
    end

    it "should save all records when usual filter is empty" do
      FeedExample.should_receive(:search).with('', {}).and_return([@feed])
      controller.get_grid(default_options.merge(:sphinx => true))
    end

    it "should filter records by date" do
      @date = mock_model(DateExample, :date => 20080101, :description => "date description")
      DateExample.should_receive(:search).with('', 
        :with => { :date => 20080600..20090000 }                                         
      ).and_return([@date])
      session[:filter] = { :date_examples => { :date => { 
        :from => { :year => '2008', :month => '6' }, :to => { :year => '2009' }
      }}}
      controller.get_grid(default_options.merge(
        :model => DateExample,
        :columns => { :show => %w{date description}},
        :filter_values => { :date => { :type => :range }},
        :sphinx => true
      ))
    end

  end


  describe "Paginating" do

    describe "Paginating by ActiveRecord" do

      it "should set page = 1 if page < 1" do
        FeedExample.should_receive(:paginate).with(:all, :page => 1, :per_page => 20, :total_entries => 1).and_return([@feed])
        FeedExample.should_receive(:count).and_return(1)
        controller.get_grid(default_options( :paginate =>  { :page => 0, :per_page => 20 }))
      end

      it "should set last page if page > last page" do
        FeedExample.should_receive(:paginate).with(:all, :page => 5, :per_page => 20, :total_entries => 100).and_return([@feed])
        FeedExample.should_receive(:count).and_return(100)
        controller.get_grid(default_options( :paginate =>  { :page => 6, :per_page => 20 }))
      end


      it "should set page to 1 if total_entries < per_page" do
        FeedExample.should_receive(:paginate).with(:all, :page => 1, :per_page => 20, :total_entries => 10).and_return([@feed])
        FeedExample.should_receive(:count).and_return(10)
        controller.get_grid(default_options( :paginate =>  { :page => 2, :per_page => 20 }))
      end

    end

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

end

