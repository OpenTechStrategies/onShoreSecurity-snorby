module SensorsHelper
  def selected_preprocessor_value(role, preprocessor)
    return role.override_attributes["redBorder"]["snort"]["preprocessors"][preprocessor]["mode"] unless role.override_attributes["redBorder"]["snort"]["preprocessors"][preprocessor].nil?
    ""
  end

  def selected_variable_value(role, type, variable)
    return role.override_attributes["redBorder"]["snort"][type][variable] unless role.override_attributes["redBorder"]["snort"][type][variable].nil?
    nil
  end

  def select_role_options(sensor, chef_value_path, options, attributes={})
    select_options = ""
    options.each do |k, v|
      name = k
      if v == "" and sensor.parent and !sensor.parent.role_value(chef_value_path).nil?
        name += " (#{options.key(sensor.parent.role_value(chef_value_path))})"
      end
      content = content_tag(:option, name, :value => v)
      content = content_tag(:option, name, :value => v, :selected => 'selected') if attributes[:selected].to_s == v.to_s
      select_options += content
    end
    select_options = "<option value=''></option>#{select_options}" if attributes[:include_blank]
    select_options.html_safe
  end

  def last_check_in_uptime(sensor) 
    html = ""
    if sensor.virtual_sensor?
      node = sensor.chef_node
      unless node.nil? 
        html = "<span title='Last UPTIME readed: " + (node[:uptime] || "unknown") +"' class='add_tipsy'>" + sensor.last_check_in_msg(node) +"</span>"
      end
    end
    html.html_safe
  end

end