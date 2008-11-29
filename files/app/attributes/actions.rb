module SolutionsGrid::Actions

  def action_edit(record = nil)
    if record
      url = generate_url(record.class, "edit", record)
      value = link_to("Edit", url)
    else
      value = nil
    end
    { :key => "Edit", :value => value }
  end

  
  def action_destroy(record = nil)
    if record
      url = generate_url(record.class, "confirm_destroy", record)
      value = link_to("Delete", url)
    else
      value = nil
    end
    { :key => "Delete", :value => value }
  end
  
  
  def action_restrict(record = nil)
    if record
      url = generate_url(record.class, "restrict", record)
      value = link_to(record.restricted? ? "Unrestrict" : "Restrict", url)
    else
      value = nil
    end
    { :key => "Restrict", :value => value }
  end

 
end
