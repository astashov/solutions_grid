require 'active_support'

def require_files(path = nil)
  Dir.glob(path + "/*").each { |fullpath| require(fullpath) }
end

SOLUTIONS_GRID_PATH = RAILS_ROOT + "/vendor/plugins/solutions_grid/lib/solutions_grid"
require "solutions_grid"
require RAILS_ROOT + "/vendor/plugins/solutions_grid/lib/routes"
require_files(SOLUTIONS_GRID_PATH + "/column")
require_files(SOLUTIONS_GRID_PATH + "/sort")
require_files(SOLUTIONS_GRID_PATH + "/filter")
require_files("solutions_grid/helpers")
require "solutions_grid/errors_handling"
require "solutions_grid/grid"
require "solutions_grid/hash_grid"
require "solutions_grid/active_record_grid"

# Enable our grid_controller
controller_path = RAILS_ROOT + '/vendor/plugins/solutions_grid/lib/solutions_grid/controllers'
$LOAD_PATH << controller_path
Dependencies.load_paths << controller_path
config.controller_paths << controller_path

SolutionsGrid.enable