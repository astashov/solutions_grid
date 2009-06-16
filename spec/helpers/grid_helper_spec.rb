require File.dirname(__FILE__) + '/../spec_helper'
module SolutionsGrid::FeedExamples; end

describe SolutionsGrid::GridHelper do
  
#  before do
#    @category = mock_model(CategoryExample, :name => "somecategory")
#    @feed = mock_model(FeedExample, :name => "somefeed", :category_example_id => @category.id, 
#      :category_example => @category, :restricted => false, :descriptions => "Desc")
#    FeedExample.stub!(:find).and_return([@feed])
#    FeedExample.stub!(:table_name).and_return("feeds")
#    CategoryExample.stub!(:find).and_return([@category])
#    CategoryExample.stub!(:table_name).and_return("category_examples")
#    set_column_names_and_hashes(FeedExample, :string => %w{name category_example_id restricted description})
#    set_column_names_and_hashes(DateExample, :string => %w{description}, :date => %w{date})
#    set_column_names_and_hashes(SpanDateExample, :string => %w{description}, :datetime => %w{start_datetime end_datetime})
#    helper.stub!(:render)
#  end
#  
#  it "should display usual columns of model" do
#    grid = Grid.new({ :columns => {:show => %w{name}}, :name => 'feed_examples', :model => FeedExample})
#    helper.show_grid(grid)
#    grid.view[:headers].should == [ '<a href="http://test.host/grid/feed_examples/sort_by/name" class="sorted">Name</a>' ]
#    grid.view[:records].should == [ [ 'somefeed' ] ]
#  end
#  
#  it "should display user defined columns of model" do
#    SolutionsGrid::FeedExamples.class_eval do
#      define_method(:feed_examples_name) do |record|
#        if record
#          url = url_for(:controller => record.class.to_s.underscore, :action => 'edit', :id => record.id, :only_path => true)
#          value = link_to(h(record.name), url)
#        else
#          value = nil
#        end
#        { :key => "Name", :value => value }
#      end
#    end
#    
#    grid = Grid.new({ :columns => {:show => %w{name category_example_id}}, :name => 'feed_examples', :model => FeedExample})
#    helper.show_grid(grid)
#    grid.view[:headers].should include('<a href="http://test.host/grid/feed_examples/sort_by/name" class="sorted">Name</a>')
#    grid.view[:records][0][0].should match(/a href=\"\/feed_example\/edit\/\d+\">somefeed<\/a>/)
#    
#    SolutionsGrid::FeedExamples.class_eval do
#      remove_method(:feed_examples_name)
#    end
#  end
#  
#  it "should display columns with actions" do
#    SolutionsGrid::Actions.class_eval do
#      define_method(:action_edit) do |record|
#        if record
#          url = url_for(:controller => record.class.to_s.underscore.pluralize, :action => 'edit')
#          value = link_to("Edit", url)
#        else
#          value = nil
#        end
#        { :key => "Edit", :value => value }
#      end
#    end
#    grid = Grid.new({ :columns => {:show => %w{name category_example_id}}, :actions => [ 'edit' ], :name => 'feed_examples', :model => FeedExample})
#    helper.show_grid(grid)
#    grid.view[:headers].should include("Edit")
#    grid.view[:records].should == [["somefeed", "somecategory", "<a href=\"/feed_examples/edit\">Edit</a>"]]
#    
#    SolutionsGrid::Actions.class_eval do
#      remove_method(:action_edit)
#    end
#  end
#
#  it "should display sorting up arrow (&#8595;) if sorted as 'asc'" do
#    grid = Grid.new({ :columns => {:show => %w{name category_example_id}}, :sorted => {:by_column => 'name', :order => 'asc'}, :name => 'feed_examples', :model => FeedExample})
#    helper.show_grid(grid)
#    grid.view[:headers].should include("<a href=\"http://test.host/grid/feed_examples/sort_by/name\" class=\"sorted\">Name</a> &#8595;")
#  end
#  
#  it "should display sorting up arrow (&#8595;) if sorted as 'asc'" do
#    grid = Grid.new({ :columns => {:show => %w{name category_example_id}}, :sorted => {:by_column => 'name'}, :name => 'feed_examples', :model => FeedExample})
#    helper.show_grid(grid)
#    grid.view[:headers].should include("<a href=\"http://test.host/grid/feed_examples/sort_by/name\" class=\"sorted\">Name</a> &#8593;")
#  end
# 
#  
end
