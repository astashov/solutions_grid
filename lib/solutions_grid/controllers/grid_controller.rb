class GridController < ApplicationController
  
  def sort
    raise "You don't specify column to sort" unless params[:column]
    name = params[:grid_name].to_sym
    
    session[:sort] ||= {}
    controller = params[:controller].to_sym
    session[:sort][name] ||= {}
    
    # If we sorted records by this column before, then just change sort order
    if session[:sort][name][:by_column] && session[:sort][name][:by_column] == params[:column]
      previous_order = session[:sort][name][:order]
      session[:sort][name][:order] = (previous_order == 'asc') ? 'desc' : 'asc'
    else
      session[:sort][name][:order] = 'asc'
      session[:sort][name][:by_column] = params[:column]
    end
    flash[:notice] = "Data was sorted by #{CGI.escapeHTML(params[:column]).humanize}"
    
    respond_to do |format|
      format.html do 
        request.env["HTTP_REFERER"] ||= root_url
        redirect_to :back
      end
      format.js do
        controller = session[:grid][name][:controller]
        action = session[:grid][name][:action]
        redirect_to url_for(:controller => controller, :action => action, :format => 'js')
      end
    end
    
  rescue => msg
    error_handling(msg)
  end
  
  
  
  def filter
    name = params[:grid_name].to_sym
    session[:filter] ||= {}
    session[:filter][name] ||= {}
    if params[:commit] == 'Clear'
      session[:filter][name] = nil
      flash[:notice] = "Filter was cleared"
    else
      from_date = params[(name.to_s + '_from_date').to_sym]
      to_date = params[(name.to_s + '_to_date').to_sym]
      by_string = params[(name.to_s + '_string_filter').to_sym] || ""
      session[:filter][name][:from_date] = from_date
      session[:filter][name][:to_date] = to_date
      session[:filter][name][:by_string] = by_string
      flash[:notice] = "Data was filtered by #{CGI.escapeHTML(by_string).humanize}"
    end
    
    respond_to do |format|
      format.html do 
        request.env["HTTP_REFERER"] ||= root_url
        redirect_to :back
      end
      format.js do
        controller = session[:grid][name][:controller]
        action = session[:grid][name][:action]
        redirect_to url_for(:controller => controller, :action => action, :format => 'js')
      end
    end 

  rescue => msg
    error_handling(msg)
  end
  
  
  private
  
    def grid_parameters(page = nil)
      { 
        :columns => { :filter => {:by_string => [], :by_date => %w{date}}},
        :sorted => session[:sort] ? session[:sort][:grid_example] : nil,
        :filtered => session[:filter] ? session[:filter][:grid_example] : nil,
        :paginate => { :enabled => true, :page => page, :per_page => 20 },
        :name => 'grid_example',
        :type_of_date_filtering => :date
      }
    end
    
    def error_handling(msg)
      msg = msg.to_s[0..1000] + "..." if msg.to_s.length > 1000
      flash[:error] = CGI.escapeHTML(msg.to_s)
      request.env["HTTP_REFERER"] ||= root_url
      redirect_to :back
    end

end