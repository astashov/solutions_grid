module SolutionsGrid::GetGrid
  def get_grid(options)
    name = options[:model].to_s.underscore
    session[:grid] ||= {}
    session[:grid][name] ||= {}
    session[:grid][name][:controller] = params[:controller]
    session[:grid][name][:action] = params[:action]
    Grid.new({
      :view => self.instance_variable_get("@template"),
      :sort_values => session[:sort] ? session[:sort][name.to_sym] : nil,
      :filter_values => session[:filter] ? session[:filter][name.to_sym] : nil,
      :paginate => { :page => params["#{name}_page".to_sym] || (session[:page] ? session[:page][name.to_sym] : 1), :per_page => 20}
   }.merge(options))
  end
end

