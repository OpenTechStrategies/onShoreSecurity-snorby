module Snorby

  class PagerIP
  
    attr_reader :total 
    
    attr_reader :per_page 
    
    attr_reader :current_page
    
    attr_reader :previous_page
    
    attr_reader :next_page
    
    attr_reader :total_pages
    
    attr_reader :uri
    
    
    def initialize(ip_hash, uri)
      @total = ip_hash.delete :total
      @per_page = ip_hash.delete :limit
      @current_page = ip_hash.delete :page
      @total_pages = total.quo(per_page).ceil
      @next_page = current_page + 1 unless current_page >= total_pages
      @previous_page = current_page - 1 unless current_page <= 1
      @uri = uri
    end
    
    def to_html options = {}
      return "" unless total_pages > 1
      @options = options
      @size = option :size
      raise ArgumentError, 'invalid :size; must be an odd number' if @size % 2 == 0
      @size /= 2
      [%(<ul class="pager">),
        first_link,
        previous_link,
        more(:before),
        intermediate_links.join("\n"),
        more(:after),
        next_link,
        last_link,
      '</ul>'].join
    end
    
    private
    
    def option key
      @options.fetch key, DataMapper::Pagination.defaults[key]
    end
    
    def link_to page, contents = nil
      %(<a href="#{uri_for(page)}">#{contents || page}</a>)
    end
    
    ##
    # More pages indicator for _position_.
    
    def more position
      return '' if position == :before && (current_page <= 1 || first <= 1)
      return '' if position == :after && (current_page >= total_pages || last >= total_pages)
      li 'more', option(:more_text)
    end
    
    ##
    # Intermediate page links array.
    
    def intermediate_links
      (first..last).map do |page|
        classes = ["page-#{page}"]
        classes << 'active' if current_page == page
        li classes.join(' '), link_to(page)
      end
    end
    
    ##
    # Previous link.
    
    def previous_link
      li 'previous jump', link_to(previous_page, option(:previous_text)) if previous_page
    end
    
    ##
    # Next link.
    
    def next_link
      li 'next jump', link_to(next_page, option(:next_text)) if next_page
    end
    
    ##
    # Last link.
    
    def last_link
      li 'last jump', link_to(total_pages, option(:last_text)) if next_page
    end
    
    ##
    # First link.
    
    def first_link
      li 'first jump', link_to(1, option(:first_text)) if previous_page
    end

    def first
      @first ||= begin
        first = [current_page - @size, 1].max
        if (current_page - total_pages).abs < @size
          first = [first - (@size - (current_page - total_pages).abs), 1].max
        end
        first
      end
    end
    
    def last
      @last ||= begin
        last = [current_page + @size, total_pages].min
        if @size >= current_page
          last = [last + (@size - current_page) + 1, total_pages].min
        end
        last
      end
    end
    
    def li css_class = nil, contents = nil
      "<li#{%( class="#{css_class}") if css_class}>#{contents}</li>\n"
    end

    def uri_for page
      case @uri
      when /page=/ ; @uri.gsub /page=\d+/, "page=#{page}"
      when /\?/    ; @uri += "&page=#{page}"
      else         ; @uri += "?page=#{page}"
      end
    end
    
  end
  
end
