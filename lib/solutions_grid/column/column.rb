require "solutions_grid/helpers/grid_helper.rb"

class SolutionsGrid::Column
  
  include ActionView::Helpers::UrlHelper  
  include ActionController::UrlWriter
  include SolutionsGrid::GridHelper
  include ERB::Util
  
  attr_reader :name, :modelname
  attr_accessor :type, :default_url_options
  
  def initialize(name, model, record = nil)
    @name = name.to_s
    @model = model
    @modelname = model.to_s.underscore
    @methodname = @modelname + "_" + @name
    @type = :string
    @example_of_record = record
    raise SolutionsGrid::ErrorsHandling::UnexistedColumn, "You try to specify unexisted column '#{self.name}'" unless does_column_exist?
  end
 
  def to_s
    @name
  end

  def change_type(type)
    @type = type    
  end

  def convert_to_date(date)
    if date.is_a?(Date) || date.is_a?(Time) || date.is_a?(DateTime)
      return date
    elsif date.is_a?(Hash)
      case @type
      when :date
        return Date.civil(date['year'].to_i, date['month'].to_i, date['day'].to_i)
      when :datetime
        return DateTime.civil(date['year'].to_i, date['month'].to_i, date['day'].to_i, date['hour'].to_i, date['minute'].to_i)
      end
    else
      raise
    end
  rescue
    return nil
  end
  
  
  # Show header of the column. Header is calculated from the current column such way:
  # 1. At first, the plugin try to find helper method modelname_column (i.e., feed_name). 
  #    If the method exists, header value will be the <tt>:key</tt> of returned value.
  # 2. If the method doesn't exist, the plugin will check column name. If it has format 'something_id',
  #    the plugin will try to find belonged table 'somethings' and display humanized classname of the model, belonged with table.
  # 3. If the table or its column 'name' doesn't exist, the plugin just display humanized name of the column
  def show_header(record = nil)
    if respond_to?(@methodname)
      value = send(@methodname, nil)[:key]
    elsif @methodname.match(/_id$/) && record
      belongs = @methodname.gsub(/(#{self.modelname}_|_id$)/, '')
      value = get_value_of_record(record, belongs).class.to_s.underscore.humanize rescue false
      value = self.name.humanize unless value
    end

    value ||= self.name.humanize
  end
  

  # Show value of the column. Value is calculated from the current column such way:
  # 1. At first, the plugin try to find helper method modelname_column (i.e., feed_name). 
  #    If the method exists, value will be the <tt>:value</tt> of returned value.
  # 2. If the method doesn't exist, the plugin will check column name. If it has format 'something_id',
  #    the plugin will try to find belonged table 'somethings' and display 'somethings.name' value.
  # 3. If the table or its column 'name' doesn't exist, the plugin just display contents of the column.
  def show_value(record)
    record = record.stringify_keys if record.is_a? Hash
    if respond_to?(@methodname)
      value = send(@methodname, record)[:value]
    elsif @methodname.match(/_id$/)
      belongs = @methodname.gsub(/(#{self.modelname}_|_id$)/, '')
      value = get_value_of_record(record, belongs).name rescue false
    end
    value ||= get_value_of_record(record, self.name)
  end
  
  
  def self.drop_unsignificant_columns(columns)
    unsignificant_columns = %w{id updated_at created_at}
    if columns.is_a? Hash
      columns.delete_if { |column, values| unsignificant_columns.include?(column) }
    else
      columns.delete_if { |column| unsignificant_columns.include?(column) }
    end
  end
  
  def self.find(column_name, array)
    column = array.select {|c| c.name == column_name}.first
    raise SolutionsGrid::ErrorsHandling::UnexistedColumn, "There are no columns with name #{column_name} here" unless column
    column
  end
  
end


class Hash

  def stringify_keys
    record_with_stringified_keys = {}
    self.each do |key, value|
      record_with_stringified_keys[key.to_s] = value
    end
    record_with_stringified_keys
  end

end