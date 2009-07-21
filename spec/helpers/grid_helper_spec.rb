require File.dirname(__FILE__) + '/../spec_helper'
module SolutionsGrid::Attributes; end

describe SolutionsGrid::GridHelper do
  
  describe "headers" do
    
    before do
      SolutionsGrid::Attributes.module_eval do
        def header_time; "header_time"; end
        def header_item_time; "header_item_time"; end
        def feed_header_time; "feed_header_time"; end
      end
      @options = {
        :name => 'feed_examples',
        :columns => { :sort => %w{date name} },
        :sort_values => { :column => "date", :order => "desc" },
      }
    end

    it "should show sorted 'desc' header" do
      helper.show_grid_header(@options, 'date').should == "<a href=\"/grid/feed_examples/sort_by/date\" class=\"sorted\">Date</a> &#8593;"
    end

    it "should show sorted 'asc' header" do
      @options[:sort_values][:order] = "asc"
      helper.show_grid_header(@options, 'date').should == "<a href=\"/grid/feed_examples/sort_by/date\" class=\"sorted\">Date</a> &#8595;"
    end

    it "should show unsorted header" do
      helper.show_grid_header(@options, 'name').should == "<a href=\"/grid/feed_examples/sort_by/name\" class=\"sorted\">Name</a>"
    end

    it "should show usual header" do
      helper.show_grid_header(@options, 'description').should == "Description"
    end

    it "should show header from #header_ method" do
      helper.show_grid_header(@options, 'time').should == "header_time"
    end

    it "should escape '.' by '_'" do
      helper.show_grid_header(@options, 'item.time').should == "header_item_time"
    end

    it "should show header from #grid_name_header_ method" do
      @options[:name] = 'feed'
      helper.show_grid_header(@options, 'time').should == "feed_header_time"
    end

  end


  describe "values" do

    before do
     SolutionsGrid::Attributes.module_eval do
        def grid_another_field(item); "grid_time"; end
        def grid_item_another_field(item); "grid_item_time"; end
        def feed_another_field(item); "feed_time"; end
      end
      @item = mock("item", :some_field => "Some Field", :another_field => "Another Field")
      @options = { :name => 'feed_examples' }
    end

    it "should show usual value" do
      helper.show_grid_value(@options, 'some_field', @item).should == "Some Field"
    end

    it "should show value from #grid_ method" do
      helper.show_grid_value(@options, 'another_field', @item).should == "grid_time"
    end

    it "should escape '.' by '_'" do
      helper.show_grid_value(@options, 'item.another_field', @item).should == "grid_item_time"
    end

    it "should show value from #grid_name_ method" do
      @options = { :name => 'feed' }
      helper.show_grid_value(@options, 'another_field', @item).should == "feed_time"
    end

  end


  it "should place default date" do
    helper.place_date('feeds', :date, :from).should == select_date(
      nil, 
      :order => [:year, :month, :day], 
      :prefix => 'feeds_date_from_filter', 
      :include_blank => true
    )
  end

  it "should place filter date" do
    session[:filter] = { 'feeds' => { 'date' => { 'from' => { 
      'year' => '2008',
      'month' => '4',
      'day' => '12'
    }}}}
    helper.place_date('feeds', 'date', 'from').should == select_date(
      Date.civil(2008, 4, 12), 
      :order => [:year, :month, :day], 
      :prefix => 'feeds_date_from_filter', 
      :include_blank => true
    )
  end

end
