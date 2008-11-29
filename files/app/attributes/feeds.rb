module SolutionsGrid::Feeds
  
  def feeds_restricted(record = nil)
    value = record ? record.restricted : nil
    { :key => "Restricted", :value => value ? "Yes" : "No" }
  end
  
  def feeds_name(record = nil)
    value = record ? link_to(record.name, feed_path(record)) : ""
    { :key => "Name", :value => value }
  end

end
