# Included to Application Controller, add get_grid method. You should use this method
# instead of Grid.new, because it hides controller/action parameters, uses current controller/action,
# and makes some filter assignings from session or from user-defined parameters
module SolutionsGrid::GetGrid

  # Returns Grid.new. Options are the same as for Grid.new, but with some exceptions:
  #  * :name - will set to pluralized underscored model by default
  #  * :filter_from_params - if this parameter is given, it will be used instead of session[:filter]
  #  * :per_page - this option will override default value. Also, you can specify :per_page in
  #                :paginate hash (Grid.new option), and :paginate has priority over :per_page
  #  * :sort - if this parameter is given, it will be used instead of session[:sort]
  #  * :filter_values - will be filled by values for filtering by
  def get_grid(options)
    options[:name] ||= options[:model].to_s.underscore.pluralize
    name = options[:name]
    with_session = (options.has_key?(:session) && options[:session] == false ? false : true)
    if with_session
      session[:grid] ||= {}
      session[:grid][name] ||= {}
      session[:grid][name][:controller] = params[:controller]
      session[:grid][name][:action] = params[:action]
    end

    if options[:filter_values] && params[:filter] != "none"
      options[:filter_values].each do |filter_type, filter_options|
        filter_value = if options[:filter_from_params]
          options[:filter_from_params][filter_type]
        elsif with_session
          session[:filter] && session[:filter][name.to_sym] && session[:filter][name.to_sym][filter_type] 
        end
        # Add values for filtering by
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

    page = params["#{name}_page".to_sym]
    page ||= ((session[:page]) ? session[:page][name.to_sym] : 1) if with_session
    per_page = options.delete(:per_page) || 20
    sort_values = options.delete(:sort)
    sort_values ||= (session[:sort] ? session[:sort][name.to_sym] : nil) if with_session

    Grid.new({
      :sort_values => sort_values,
      :paginate => { :page => page.to_i, :per_page => per_page.to_i}
    }.merge(options))
  end
end

