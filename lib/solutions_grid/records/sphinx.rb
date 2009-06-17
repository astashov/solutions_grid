module SolutionsGrid::Records::Sphinx

  def get_sphinx_records
    options = sphinx_options
    @options[:model].search('', options)
  end


  private

    def sphinx_options
      sphinx_options = @options[:filter_values].inject({}) do |options, values|
        key = values[0]
        filter = values[1]

        with = get_with(filter)
        conditions = get_conditions(filter)

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

      if @options[:with]
        sphinx_options[:with] ||= {}
        sphinx_options[:with].reverse_merge!(@options[:with])
      end

      order = get_order(@options[:sort_values])
      sphinx_options.merge!(order) if order
      sphinx_options.merge!(@options[:paginate]) if @options[:paginate]
      sphinx_options
    end

    def get_with(filter)
      if filter[:type] == :range && filter[:value] && (!filter[:value][:from].blank? || !filter[:value][:to].blank?)
        date_options(filter[:value])
      elsif filter[:type] == :strict && !filter[:value].blank?
        filter[:value]
      end
    end

    def get_conditions(filter)
      filter[:value] if filter[:type] == :match && !filter[:value].blank?
    end

    def get_order(sorted)
      if sorted
        {
          :order => column_for_sorting(sorted[:column]).to_sym, 
          :sort_mode => (sorted[:order] == 'asc' ? :asc : :desc)
        }
      end
    end

    def column_for_sorting(column)
      case
      when match = column.match(/(.*)_id$/)
        match[1] + '_name'
      else
        column
      end
    end

    def date_options(filter)
      from_date = convert_date_hash_to_integer(filter[:from])
      to_date = convert_date_hash_to_integer(filter[:to])
      (from_date || 0)..(to_date || 100000000)
    end

end
