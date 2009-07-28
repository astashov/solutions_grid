module SolutionsGrid::GetGrid
  def get_grid(options)
    name = options[:name] || options[:model].to_s.underscore.pluralize
    session[:grid] ||= {}
    session[:grid][name] ||= {}
    session[:grid][name][:controller] = params[:controller]
    session[:grid][name][:action] = params[:action]

    if options[:filter_values]
      options[:filter_values].each do |filter_type, filter_options|
        filter_value = session[:filter] && session[:filter][name.to_sym] && session[:filter][name.to_sym][filter_type] 
        if filter_value
          if filter_options[:type] == :range
            filter_options[:value] = {
              :to => filter_value[:to],
              :from => filter_value[:from]
            }
          else
            filter_options[:value] = filter_value
          end
        end
      end
    end

    page = params["#{name}_page".to_sym] || ((session[:page]) ? session[:page][name.to_sym] : 1)
    sort_values = options.delete(:sort)

    Grid.new({
      :view => self.instance_variable_get("@template"),
      :sort_values => sort_values || (session[:sort] ? session[:sort][name.to_sym] : nil),
      :paginate => { :page => page, :per_page => 20}
    }.merge(options))
  end
end

