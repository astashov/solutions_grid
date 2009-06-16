module SolutionsGrid::ErrorsHandling
    
  def check_for_errors
    verify_that_model_is_specified
  end
  

  private

    def verify_that_model_is_specified
      raise ModelIsNotDefined, "You should specify model" unless @options[:model]
    end

    # Exception will be raised when model or show_columns are not defined.
    class ModelIsNotDefined < StandardError; end;


end
