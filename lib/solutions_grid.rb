module SolutionsGrid
  
  def self.enable
    # Enable main helper
    return if ActionView::Base.instance_methods.include? 'show_table'
    
    # Enable our own display of attributes
    Dir.glob(RAILS_ROOT + "/app/helpers/attributes/*.rb").each do |fullpath|
      require fullpath
    end
    
    ActionController::Base.send(:helper, GridHelper)
    ActionView::Base.send :include, GridHelper
  end
  
end
