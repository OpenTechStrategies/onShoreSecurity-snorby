module ApplicationHelper

  def display_time(time, short=false)
    time_string = '%A, %b %d, %Y at %l:%M:%S %p'
    time_string = '%a, %b %d, %y at %I:%M:%S %p' if short

    time.strftime(time_string)
  end

  def time_range_title(type)

    title = case type.to_sym
    when :last_3_hours
      %{
        #{(@now - 3.hours).strftime('%D %H:%M')}
        -
        #{@now.strftime('%D %H:%M')}
      }  
    when :last_24
      %{
        #{(@now.yesterday.beginning_of_day + @now.yesterday.hour.hours).strftime('%D %H:%M')}
        -
        #{@now.strftime('%D %H:%M')}
      }
    when :today
      "#{@now.strftime('%A, %B %d, %Y')}"
    when :week
      %{
        #{@now.beginning_of_week.strftime('%D')}
        -
        #{@now.end_of_week.strftime('%D')}
      }
    when :last_week
      %{
        #{(@now - 1.week).strftime('%D')}
        -
        #{@now.yesterday.strftime('%D')}
      }
    when :month
      "#{@now.beginning_of_month.strftime('%B')}"
    when :last_month
      %{
        #{(@now - 1.month).strftime('%D')}
        -
        #{@now.yesterday.strftime('%D')}
      }
    when :quarter
      %{
        #{@now.beginning_of_quarter.strftime('%B %Y')}
        -
        #{@now.end_of_quarter.strftime('%B %Y')}
      }
    when :last_quarter
      %{
        #{(@now - 3.months).strftime('%D')}
        -
        #{@now.yesterday.strftime('%D')}
      }
    when :year
      "#{@now.strftime('%Y')}"
    when :last_year
     %{
        #{(@now - 1.year).strftime('%D')}
        -
        #{@now.yesterday.strftime('%D')}
      }
    else
      %{
        #{@start_time.strftime('%D %H:%M')}
        -
        #{@end_time.strftime('%D %H:%M')}
      }
    end

    title
  end

  def event_time(timestamp)
    if Setting.utc?
      return "#{timestamp.utc.strftime('%l:%M %p')}" if Date.today.to_date == timestamp.to_date
      "#{timestamp.utc.strftime('%m/%d/%Y')}"
    else
      return "#{timestamp.strftime('%l:%M %p')}" if Date.today.to_date == timestamp.to_date
      "#{timestamp.strftime('%m/%d/%Y')}"
    end
  end
  
  def geoip?
    return @geoip unless @geoip == nil
    @geoip = Setting.geoip?
  end

  def select_options(options, attributes={})
    select_options = ""
    options.each do |data|
      content = content_tag(:option, data.last, :value => data.first)
      content = content_tag(:option, data.last, :value => data.first, :selected => 'selected') if attributes[:selected].to_s == data.first.to_s
      select_options += content
    end
    select_options = "<option value=''></option>#{select_options}" if attributes[:include_blank]
    select_options.html_safe
  end

  def dropdown_select_tag(collection, value, include_blank=false, custom=[])
    options = include_blank ? "<option></option>" : ""
    custom.collect { |x| options += x }
    collection.collect { |x| options += "<option class='#{x.class == Sensor ? get_option_class(x) : nil}' value='#{x.send(value.to_sym)}'>#{x.class == Sensor ? x.sensor_name : x.name}</option>" }
    options.html_safe
  end

  def pretty_time(time)
    time.strftime('%A, %B %d, %Y %I:%M %p')
  end

  def short_time(time)
    time.strftime('%B %d, %Y %I:%M %p')
  end

  def format_note_body(text)
    return text.sub(/(\B\@[a-zA-Z0-9_%]*\b)/, '<strong>\1</strong>').html_safe
  end

  #
  # Title
  #
  # @param [String] header
  # @param [Block] yield for title-menu items
  #
  # @return [String] title html
  #
  def title(header, title=nil, menu_content=true, &block)
    show_title(title ? title : header)
    title_header = content_tag(:div, header, :id => 'title-header', :class => 'grid_6')
    
    if block_given? and !capture(&block).nil?
      data = capture(&block).gsub("\n|\t", '')
      if menu_content
        menu = content_tag(:ul, "<li>&nbsp;</li>#{capture(&block)}<li>&nbsp;</li>".html_safe, :id => 'title-menu') unless data.blank?
        menu_holder = content_tag(:ul, menu, :id => 'title-menu-holder', :class => '')
        html = title_header + menu_holder
      else
        html = title_header + data.html_safe
      end
    else
      html = title_header
    end

    return content_tag(:div, html, :id => 'title')
  end

  def sec_title(header, content_class="", &block)
    title_header = content_tag(:div, header.html_safe, :id => 'title-header', :class => 'grid_6')

    if block_given?
      data = capture(&block).gsub("\n|\t", '')
      menu = content_tag(:ul, "<li>&nbsp;</li>#{capture(&block)}<li>&nbsp;</li>".html_safe, :id => 'title-menu') unless data.blank?
      menu_holder = content_tag(:ul, menu, :id => 'title-menu-holder', :class => '')
      html = title_header + menu_holder
    else
      html = title_header
    end

    return content_tag(:div, html, :id => 'title', :class => 'sec-title '+content_class)
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction} add_tipsy" : 'add_tipsy'
    direction = column == sort_column && sort_direction == :asc ? :desc : :asc

    link = {
      :sort => column,
      :direction => direction
    }

    if params.has_key?(:search)
      link[:search] = params[:search]
    end

    if params.has_key?(:page)
      link[:page] = params[:page].to_i
    end

    link_to title, link, {
      :class => css_class +" block-ui-but", 
      :title => "Sort `#{title}` #{direction}"}
  end

  #
  # Pager
  #
  # Setup pager and return helper
  # html for view display
  #
  # @param [String] collection
  # @param [String] parent pager path
  # @param [Boolean] fade_content
  #
  def pager(collection, path, fade_content=true)
    if fade_content
      %{<div class='pager main'>#{collection.pager.to_html("#{path}", :size => 9)}</div>}.html_safe
    else
      %{<div class='pager notes-pager'>#{collection.pager.to_html("#{path}", :size => 9)}</div>}.html_safe
    end
  end

  def pager_sensor(size, page, sensor_id)
    n_pages = (size.to_f / current_user.per_page_count.to_f).ceil

    first_page = 1
    last_page = ((n_pages.to_i >= 10)? (page.to_i + 10) : n_pages)
    if (n_pages.to_i >= 10)
      first_page = ((n_pages.to_i <= page.to_i + 10)? (n_pages.to_i - 10) : page.to_i)
      last_page = ((n_pages.to_i >= page.to_i + 10)? (page.to_i + 10) : n_pages)
    end

    html = ''

    html << "<div class=\"pager main\">"
    html << "<ul class=\"pager_sensor\">"

    if page.to_i != 1
      html << content_tag(:li, :class => "first") do
        concat link_to 'First', {:controller => "logs", :action => "show_sensor", :sensor_id => sensor_id, :page => 1, :search =>{:text => @filter_search}},:method => 'get', :remote => true, :class => "click-loading"
      end
      on = (page.to_i <= 1)? 'disabled' : ''
      html << content_tag(:li, :class => "previous_page #{on}") do
        concat link_to 'Previous', {:controller => "logs", :action => "show_sensor", :sensor_id => sensor_id, :page => (page.to_i - 1), :search =>{:text => @filter_search}},:method => 'get', :remote => true, :class => "click-loading"
      end
    end

    first_page.upto(last_page).each do |n|
      on = (n == page.to_i)? 'active' : ''
      html << content_tag(:li, :class => "#{on}") do
        concat link_to "#{n.to_s}", {:controller => "logs", :action => "show_sensor", :sensor_id => sensor_id, :page => n, :search =>{:text => @filter_search}},:method => 'get', :remote => true, :class => "click-loading"
      end
    end

    if page.to_i != n_pages
      html << content_tag(:li, :class => "next jump", :rel => "next") do
        concat link_to 'Next', {:controller => "logs", :action => "show_sensor", :sensor_id => sensor_id, :page => (page.to_i + 1), :search =>{:text => @filter_search}}, :method => 'get', :remote => true, :class => "click-loading"
      end
      html << content_tag(:li, :class => "last") do
        concat link_to 'Last', {:controller => "logs", :action => "show_sensor", :sensor_id => sensor_id, :page => n_pages, :search =>{:text => @filter_search}},:method => 'get', :remote => true, :class => "click-loading"
      end
    end
    
    html << '</ul>'
    html << '</div>'
    html.html_safe
  end

  def drop_down_for(name, icon_path, id, &block)
    html = link_to "#{image_tag(icon_path, :size => '16x16')} #{name}".html_safe, '#', :class => 'has_dropdown right-more', :id => "#{id}"

    if block_given?
      html += content_tag(:dl, "#{capture(&block)}".html_safe, :id => "#{id}", :class => 'drop-down-menu', :style => 'display:none;')
    end

    "<li class='#{id}'>#{html}</li>".html_safe
  end

  def drop_down_item(name, path='#', image_path=nil, options={})
    image = image_path ? "#{image_tag(image_path)} " : ""
    content_tag(:dd, "#{link_to "#{image}#{name}".html_safe, path, options}".html_safe)
  end

  #
  # Menu Item
  #
  # @param [String] name Menu Item Name
  # @param [String] path Men Item Path
  # @param [String] image_path Menu Item Image Path
  # @param [Hash] options Options to padd to content_tag
  #
  # @return [String] HTMl Menu Item
  #
  def menu_item(name, path='#', image_path=nil, options={})
    image = image_path ? "#{image_tag(image_path)} " : ""
    unless path.blank?
      content_tag(:li, "#{link_to "#{image}#{name}".html_safe, path, options}".html_safe)
    end 
  end

  def snorby_box(title, normal_size=true, &block)
    html = content_tag(:div, title, :id => 'box-title')
    
    if normal_size
      html += content_tag(:div, capture(&block), :id => 'box-content')
    else
      html += content_tag(:div, capture(&block), :id => 'box-content-small')
    end

    content_tag(:div, html, :id => 'snorby-box', :class => 'snorby-box')
  end
  
  def snorby_box_footer(&block)
    html = ''
    html = capture(&block) if block
    content_tag(:div, html, :id => 'box-footer')
  end

  def form_actions(content_class="", &block)
    content_tag(:div, capture(&block), :id => 'form-actions', :class => content_class)
  end

  def button(name, options={})
    # <span class="success" style="display:none">✓ saved</span>
    options[:class] = options[:class] ? options[:class] += " default" : "default"
    content_tag(:button, "<span>#{name}</span>".html_safe, options)
  end

  def css_chart(percentage, large=false, margin_top=false)
    html = content_tag(:div, "<span>#{percentage}%</span>".html_safe, :style => "width: #{percentage}%")
    klass = large ? 'progress-container-large' : (margin_top ? 'progress-container-margin_top' : 'progress-container')
    content_tag(:div, html, :class => klass)
  end

  def worker_status(show_image=false)

    validations = [{:check => Snorby::Jobs.sensor_cache?, :enabled => true, :desc => "Sensor Cache Job"},
                   {:check=> Snorby::Jobs.daily_cache?, :enabled => true, :desc => "Daily Cache Job"},
                   {:check => Snorby::Jobs.snmp?, :enabled => true, :desc => "Snmp Job"},
                   #{:check=> Snorby::Jobs.geoip_update?, :enabled => Setting.geoip?, :desc => "GeoIP Update Job"},
                   #{:check=> Snorby::Jobs.rule_update?, :enabled => true, :desc => "Rule Update Job"}
                  ]

    # Just check for enabled jobs              
    items_to_check = validations.select{|h| h[:enabled] == true} 

    if items_to_check.select{|h| h[:check] == true}.count == items_to_check.count
      return content_tag(:span, "OK", :class => 'status ok add_tipsy', :title => 'Success: Everything Looks Good!')
    elsif items_to_check.select{|h| h[:check] == false}.count == items_to_check.count
      return content_tag(:span, "FAIL", :class => 'status fail add_tipsy', :title => 'ERROR: No Jobs Are Running...')
    else
      prbs = items_to_check.select{|h| h[:check] == false}.collect{|h| h[:desc]}
      msg = "Warning: The Job(s) #{prbs.inject { |r, i| r = r + " and " + i}} #{prbs.count > 1 ? "are" : "is"} Not Running..."
      return content_tag(:span, "WARNING", :class => 'status warning add_tipsy', :title => msg)
    end
  end

  #
  # Percentage Helper
  # 
  # Used for generating customized 
  # percentages used in the view and pdf
  # reports. This method will protect
  # impossible percentages.
  #
  # @param [Integer] count Count from total
  # @param [Integer] total The total count
  # @param [Integer] round Rounding Option
  # 
  # @return [Integer] percentage
  # 
  def percentage_for(count, total, round=2)
    begin
      percentage = ((count.to_f / total.to_f) * 100).round(round)
      return 100.round(round) if percentage.round > 100
      percentage
    rescue FloatDomainError
      0
    end
  end


  def clippy(text, bgcolor='#FFFFFF', id=0)
    html = <<-EOF
      <span style="display:none" id="clippy_#{id}" class="ip-copy">#{text}</span>
      <span id="main_clippy_#{id}" class="add_tipsy clippy" 
      original-title="copied!" title="copy to clipboard">
        <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" 
                width="14" 
                height="14" 
                class="clippy" 
                id="clippy">
        <param name="movie" value="/flash/clippy.swf">
        <param name="allowScriptAccess" value="always">
        <param name="quality" value="high">
        <param name="scale" value="noscale">
        <param name="FlashVars" value="id=clippy_#{id}&amp;copied=&amp;copyto=">
        <param name="bgcolor" value="#{bgcolor}">
        <param name="wmode" value="opaque">
        <embed src="/flash/clippy.swf" 
               width="14" 
               height="14" 
               name="clippy" 
               quality="high" 
               allowscriptaccess="always" 
               type="application/x-shockwave-flash" 
               pluginspage="http://www.macromedia.com/go/getflashplayer" 
               flashvars="id=clippy_#{id}&amp;copied=&amp;copyto=" 
               bgcolor="#{bgcolor}" 
               wmode="opaque">
        </object>
      </span>
    EOF

    html.html_safe
  end

  def get_option_class(sensor)
    if sensor.virtual_sensor
      'virtual_sensor'
    else
      'domain'
    end
  end

  def filter_count(filter)
    count = 0

    filter.each do |key, value|
      count += value.size
    end

    count

  end

  def operator(operator)
    
    val = case operator
    when "not", "is_not"
      "!="
    when "gt"
      ">"
    when "gte"
      ">="
    when "lt"
      "<"
    when "lte"
      "<="
    when "isnull"
      "is null"
    when "notnull"
      "is not null"
    else
      ""
    end
    
    val
  
  end

end
