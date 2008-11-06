module SolutionsGrid::Routing
  def grid_routes
    map = self # to make 'map' available within the plugin route file
    
    map.sort "grid/:grid_name/sort_by/:column", :controller => 'grid', :action => 'sort'
    map.connect "grid/:grid_name/sort_by/:column.:format", :controller => 'grid', :action => 'sort'

    map.filter "grid/:grid_name/filter", :controller => 'grid', :action => 'filter'
    map.connect "grid/:grid_name/filter.:format", :controller => 'grid', :action => 'filter'
    
    map.connect "grid/test", :controller => 'grid', :action => "test"
    map.connect "grid/test.:format", :controller => 'grid', :action => "test"
  end
end

  
module ::ActionController #:nodoc:
  module Routing #:nodoc:
    class RouteSet #:nodoc:
      class Mapper #:nodoc:
        include SolutionsGrid::Routing
      end
    end
  end
end