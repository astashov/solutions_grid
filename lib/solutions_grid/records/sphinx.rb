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
      from_date = convert_date_to_integer(filter[:from])
      to_date = convert_date_to_integer(filter[:to])
      (from_date || 0)..(to_date || 100000000)
    end

end
