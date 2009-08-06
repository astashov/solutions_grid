class GridController < ApplicationController
  unloadable
  
  def sort
    raise "You don't specify column to sort" unless params[:column]
    name = params[:grid_name].to_sym
    
    session[:sort] ||= {}
    controller = params[:controller].to_sym
    session[:sort][name] ||= {}
    
    # If we sorted records by this column before, then just change sort order
    column = URI.unescape(params[:column])
    if session[:sort][name][:column] && session[:sort][name][:column] == column
      previous_order = session[:sort][name][:order]
      session[:sort][name][:order] = (previous_order == 'asc') ? 'desc' : 'asc'
    else
      session[:sort][name][:order] = 'asc'
      session[:sort][name][:column] = column
    end
    flash[:notice] = "Data was sorted by #{CGI.escapeHTML(column).humanize}"
    
    respond_to do |format|
      format.html do 
        request.env["HTTP_REFERER"] ||= root_url
        redirect_to :back
      end
      format.js do
        controller = session[:grid][name][:controller]
        action = session[:grid][name][:action]
        redirect_to url_for(:controller => controller, :action => action, :format => 'js', :grid => name)
      end
    end
    
  rescue => msg
    error_handling(msg)
  end
  
  
  
  def filter
    grid_name = params[:grid_name].to_sym
    session[:filter] ||= {}
    session[:filter][grid_name] ||= {}
    session[:page].delete(grid_name) if session[:page]
    if params[:commit] == 'Clear'
      session[:filter][grid_name] = nil
      flash[:notice] = "Filter was cleared"
    else
      params.each do |key, value|
        if match = key.match(/#{grid_name.to_s}_(.*)_(to|from)_filter/)
          filter_name = match[1].to_sym
          range_type = match[2].to_sym
          session[:filter][grid_name][filter_name] ||= {}
          session[:filter][grid_name][filter_name][range_type] = set_date_filters(match, value)
        elsif match = key.match(/#{grid_name.to_s}_(.*)_filter/)
          filter_name = match[1].to_sym 
          session[:filter][grid_name][filter_name] = (value || "") if filter_name
        end
      end
      flash[:notice] = "Data was filtered"
    end
    
    respond_to do |format|
      format.html do 
        request.env["HTTP_REFERER"] ||= root_url
        redirect_to :back
      end
      format.js do
        controller = session[:grid][name][:controller]
        action = session[:grid][name][:action]
        redirect_to url_for(:controller => controller, :action => action, :format => 'js', :grid => name)
      end
    end 

  rescue => msg
    error_handling(msg)
  end
  
  
  private
     
    def error_handling(msg)
      msg = msg.to_s[0..1000] + "..." if msg.to_s.length > 1000
      flash[:error] = CGI.escapeHTML(msg.to_s)
      request.env["HTTP_REFERER"] ||= root_url
      redirect_to :back
    end


    def set_date_filters(match, value)
      date_hash = value.match(/(\d+)\/(\d+)\/(\d+)/)
      if date_hash
        year = date_hash[3]
        year = "20" + year if year.length == 2
        date = Date.civil(year.to_i, date_hash[1].to_i, date_hash[2].to_i) rescue nil
        if date
          {'year' => year, 'month' => date_hash[1], 'day' => date_hash[2]}
        else
          ""
        end
      else
        ""
      end
    end

end
