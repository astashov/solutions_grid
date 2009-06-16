module SolutionsGrid::Records::Sphinx

  def get_sphinx_records
    @options[:model].search('', sphinx_options)
  end


  private

    def sphinx_options
      sphinx_options = @options[:filter_values].inject({}) do |options, values|
        key = values[0]
        filter = values[1]

        with = get_with(filter)
        conditions = get_conditions(filter)
        order = get_order(@options[:sort_values])
        paginate = @options[:paginate]

        if with
          options[:with] ||= {}
          options[:with][key] = with
        end
        if conditions
          options[:conditions] ||= {}
          options[:conditions][key] = conditions
        end
        options
      end
      sphinx_options.merge!(order) if order
      sphinx_options.merge!(@options[:paginate]) if @options[:paginate]
      sphinx_options
    end

    def get_with(filter)
      if !filter[:from].blank? || !filter[:to].blank?
        date_options(filter)
      elsif filter[:type] == :strict && !filter[:text].blank?
        filter[:text]
      end
    end

    def get_conditions(filter)
      filter[:text] if filter[:type] == :match && !filter[:text].blank?
    end

    def get_order(sorted)
      if sorted
        {
          :order => sorted[:column].to_sym, 
          :sort_mode => (sorted[:order] == 'asc' ? :asc : :desc)
        }
      end
    end

    def date_options(filter)
      unless filter[:from]['year'].blank?
        from_year = "%04d" % filter[:from]['year'].to_i
        from_month = "%02d" % filter[:from]['month'].to_i
        from_day = "%02d" % filter[:from]['day'].to_i
        from_date = (from_year + from_month + from_day).to_i
      end
      unless filter[:to]['year'].blank?
        to_year = "%04d" % filter[:to]['year'].to_i
        to_month = "%02d" % filter[:to]['month'].to_i
        to_day = "%02d" % filter[:to]['day'].to_i
        to_date = (to_year + to_month + to_day).to_i
      end
      (from_date || 0)..(to_date || 100000000)
    end

end
