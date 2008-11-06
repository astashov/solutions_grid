require File.dirname(__FILE__) + '/../spec_helper'

describe SolutionsGrid::GridHelper do
  
  before do
    @category = mock_model(CategoryExample, :name => "somecategory")
    @feed = mock_model(FeedExample, :name => "somefeed", :category_id => @category.id, 
      :category => @category, :restricted => false, :descriptions => "Desc")
    set_column_names_and_hashes(FeedExample, :string => %w{name category_id restricted description})
    set_column_names_and_hashes(DateExample, :string => %w{description}, :date => %w{date})
    set_column_names_and_hashes(SpanDateExample, :string => %w{description}, :datetime => %w{start_datetime end_datetime})
  end
  
  it "should display usual columns of model" do
    grid = Grid.new(@feed, { :columns => {:show => %w{name}}, :name => 'feed'})
    output = helper.show_grid(grid)
    output.should match(/table.*tr.*th.*Name.*td.*somefeed/m)
  end
  
  it "should display calculated columns of model" do
    grid = Grid.new(@feed, { :columns => {:show => %w{category_id}}, :name => 'feed'})
    output = helper.show_grid(grid)
    output.should match(/table.*tr.*th.*Category example.*td.*somecategory/m)
  end
  
  it "should display user defined columns of model" do
    SolutionsGrid::GridHelper.class_eval do
      define_method(:feed_example_restricted) do |model|
        value = model ? model.restricted : nil
        { :key => "Restricted", :value => value ? "Yes" : "No" }
      end
    end
    grid = Grid.new(@feed, { :columns => {:show => %w{restricted}}, :name => 'feed'})
    output = helper.show_grid(grid)
    output.should match(/table.*tr.*th.*Restricted.*td.*No/m)
  end
  
  it "should display columns with actions" do
    SolutionsGrid::GridHelper.class_eval do
      define_method(:action_edit) do |record|
        if record
          url = url_for(:controller => record.class.to_s.underscore.pluralize, :action => 'edit')
          value = link_to("Edit", url)
        else
          value = nil
        end
        { :key => "Edit", :value => value }
      end
    end
    grid = Grid.new(@feed, { :columns => {:show => %w{name category_id}}, 
      :actions => %w{edit delete duplicate}, :name => 'feed'})
    output = helper.show_grid(grid)
    output.should match(/table.*tr.*th.*Name.*Category example.*Edit.*td.*Edit/m)
  end
  
  it "should display sorting up arrow (&#8595;) if sorted as 'asc'" do
    grid = Grid.new(@feed, { :columns => {:show => %w{name category_id restricted}}, :name => 'feed'})
    grid.sort('name', 'asc')
    output = helper.show_grid(grid)
    output.should have_tag("a[href*=/grid/feed/sort_by/name]", "Name")
    output.should include_text("&#8595;")
    output.should have_tag("a[href*=/grid/feed/sort_by/category_id]", "Category example")
  end
  
  it "should display sorting down arrow (&#8593;) if sorted as 'desc'" do
    grid = Grid.new(@feed, { :columns => {:show => %w{name category_id restricted}}, :name => 'feed'})
    grid.sort('name', 'desc')
    output = helper.show_grid(grid)
    output.should have_tag("a[href*=/grid/feed/sort_by/name]", "Name")
    output.should include_text("&#8593;")
    output.should have_tag("a[href*=/grid/feed/sort_by/category_id]", "Category example")
  end
  
  it "should display filter form" do
    grid = Grid.new(@feed, { :columns => {:show => %w{name category_id restricted}}, :filtered => { :by_string => 'some'}, :name => 'feed'})
    output = helper.show_filter(grid)
    output.should match(/form.*\/grid\/feed\/filter.*<input.*value=\"some\".*.*type=\"submit\" value=\"Filter\".*type=\"submit\" value=\"Clear\"/m)
  end
  
  it "should display filter form with date by default" do
    date = mock_model(DateExample, :date => Date.today, :description => "Desc")
    grid = Grid.new(date, { :columns => {:show => %w{date description}}, :name => 'date'})
    output = helper.show_filter(grid, true)
    output.should match(/form.*Date Filter.*from_date_year.*from_date_month.*from_date_day.*Filter"/m)
  end

  it "should display filter form with datetime" do
    date = mock_model(DateExample, :date => Date.today, :description => "Desc")
    grid = Grid.new(date, { :columns => {:show => %w{date description}}, :type_of_date_filtering => :datetime, :name => 'date' })
    output = helper.show_filter(grid, true)
    output.should match(/form.*DateTime Filter/m)
  end
  
  it "should display filter form with date" do
    DateExample.stub!(:column_names).and_return(%w{date description})
    date = mock_model(DateExample, :date => Date.today, :description => "Desc")
    grid = Grid.new(date, { :columns => {:show => %w{date description}, :filter => {:by_date => %w{date}}}, :name => 'date'})
    output = helper.show_filter(grid, true)
    output.should match(/form.*Date Filter.*from_date_year.*from_date_month.*from_date_day.*to_date_year.*to_date_month.*to_date_day.*Filter"/m)
  end
  
  it "should display filter form with datetime for span of dates" do
    SpanDateExample.stub!(:column_names).and_return(%w{start_datetime end_datetime description})
    span_date = mock_model(SpanDateExample, :start_datetime => DateTime.now, :end_datetime => DateTime.now + 2.days, :description => "Desc")
    grid = Grid.new(span_date, { :columns => {:show => %w{start_datetime start_datetime description}, :filter => { :by_span_date => [%w{start_datetime start_datetime}]}}, :name => 'span_date'})
    output = helper.show_filter(grid, true)
    output.should match(/form.*DateTime Filter.*from_date_year.*from_date_minute.*to_date_year.*to_date_minute.*Filter"/m)
  end
  
  it "should display table from hash" do
    dates = []
    3.times do |i|
      dates << { :date => Date.civil(2008, 8, 5) + i.days, :description => "some description" }
    end
    grid = Grid.new(dates, :name => 'date')
    output = helper.show_grid(grid)
    output.should match(/table.*tr.*th.*Date.*th.*Description.*td.*2008-08-05.*td.*some description/m)
  end
  
  it "should display will_paginate helper after the table if WillPaginate is installed" do
    if Object.const_defined? "WillPaginate"
      dates = [:date => 'asdf']
      grid = Grid.new(dates, :paginate => { :enabled => true, :per_page => 5, :page => 2 }, :name => 'date')
      helper.should_receive(:will_paginate).and_return("There will 'will_paginate' work")
      
      output = helper.show_grid(grid)
    end
  end
  
  it "should not display will_paginate if we disable 'will_paginate'" do
    if Object.const_defined? "WillPaginate"
      dates = [:date => 'asdf']
      grid = Grid.new(dates, :paginate => { :enabled => false }, :name => 'date')
      helper.should_not_receive(:will_paginate)
      output = helper.show_grid(grid)
    end
  end
  
end