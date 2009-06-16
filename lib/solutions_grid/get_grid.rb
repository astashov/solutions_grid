module SolutionsGrid::GetGrid
  def get_grid(options)
    name = options[:model].to_s.underscore.pluralize
    session[:grid] ||= {}
    session[:grid][name] ||= {}
    session[:grid][name][:controller] = params[:controller]
    session[:grid][name][:action] = params[:action]

    options[:filter_values].each do |filter_type, filter_options|
      filter_text = session[:filter] && session[:filter][name.to_sym] && session[:filter][name.to_sym][filter_type]
      filter_options[:text] = filter_text if filter_text
    end

    Grid.new({
      :view => self.instance_variable_get("@template"),
      :sort_values => session[:sort] ? session[:sort][name.to_sym] : nil,
      :paginate => { :page => (params["#{name}_page".to_sym] || (session[:page]) ? session[:page][name.to_sym] : 1), :per_page => 20}
   }.merge(options))
  end
end

