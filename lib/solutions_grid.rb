module SolutionsGrid
  
  def self.enable
    # Enable our own display of attributes
    Dir.glob(RAILS_ROOT + "/app/helpers/attributes/*.rb").each do |fullpath|
      require fullpath
    end
    require "solutions_grid/helpers/grid_helper"
    require "solutions_grid/errors_handling"
    require "solutions_grid/grid"
    require "solutions_grid"
    require RAILS_ROOT + "/vendor/plugins/solutions_grid/lib/routes"

    ActionController::Base.send(:helper, GridHelper)
    ActionController::Base.send(:include, SolutionsGrid::GetGrid)
    ActionView::Base.send :include, GridHelper
  end
  
end
