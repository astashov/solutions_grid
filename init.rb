# Enable our grid_controller
controller_path = RAILS_ROOT + '/vendor/plugins/solutions_grid/lib/solutions_grid/controllers'
$LOAD_PATH << controller_path
Dependencies.load_paths << controller_path
config.controller_paths << controller_path

SolutionsGrid.enable