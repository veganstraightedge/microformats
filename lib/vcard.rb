class Microformats::Vcard
  include Microformats::FormattingHelpers

  def initialize(template)
    @template = template
    @default_tag = :span
  end

  def run(opts = {}, &block)
    opts[:class] = ['vcard', opts[:class]].flatten.compact.sort.join(' ')
    opts[:itemscope] = 'itemscope'
    opts[:itemtype] = 'http://data-vocabulary.org/Person'
    opts[:tag] ||= :div
    concat_tag(opts) do
      block.call(self)
    end
  end

  def name(str, opts = {})
    content_tag(str, merge_html_attrs({:class => 'fn', :itemprop => 'name'}, opts))
  end

  def company(str, opts = {})
    classes = opts.delete(:is_company) ? 'fn org' : 'org'
    content_tag(str, merge_html_attrs({:class => classes, :itemprop => 'affiliation'}, opts))
  end
  alias_method :organization, :company

  def url(str, opts = {})
    if opts[:href]
      content_tag(str, merge_html_attrs({:tag => :a, :class => 'url', :itemprop => 'url'}, opts))
    elsif opts[:tag]
      content_tag(str, merge_html_attrs({:class => 'url', :itemprop => 'url'}, opts))
    else
      content_tag(str, merge_html_attrs({:tag => :a, :class => 'url', :href => str, :itemprop => 'url'}, opts))
    end
  end

  def photo(str, opts = {})
    if size = opts.delete(:size)
      opts[:width], opts[:height] = size.split('x')
    end
    content_tag(nil, merge_html_attrs({:tag => :img, :itemprop => 'photo', :src => str}, opts))
  end

  def phone(str, opts = {})
    type = if opts[:type].to_s != ''
      type_inner_span = content_tag('', :class => 'value-title', :title => opts.delete(:type))
      content_tag(type_inner_span, :class => 'type')
    else
      ''
    end
    content_tag(type + str, merge_html_attrs({:class => 'tel'}, opts))
  end

  def email(str, opts = {})
    type = if opts[:type].to_s != ''
      type_inner_span = content_tag('', :class => 'value-title', :title => opts.delete(:type))
      content_tag(type_inner_span, :class => 'type')
    else
      ''
    end
    if opts[:tag] == :a
      content_tag(type + str, merge_html_attrs({:class => 'email', :href => "mailto:#{str}"}, opts))
    else
      content_tag(type + str, merge_html_attrs({:class => 'email'}, opts))
    end
  end

  def coordinates(lat, lng, opts = {})
    # <span class='geo' itemprop='geo' itemscope='itemscope' itemtype='http://data-vocabulary.org/Geo'>
    # <meta content='37.774929' itemprop='latitude'></meta>
    # <meta content='-122.419416' itemprop='longitude'></meta>
    # <span class='latitude'><span class='value-title' title='37.774929'></span></span>
    # <span class='longitude'><span class='value-title' title='-122.419416'></span></span>
    # </span>
    lat_meta = content_tag('', :tag => :meta, :itemprop => 'latitude', :content => lat)
    lng_meta = content_tag('', :tag => :meta, :itemprop => 'longitude', :content => lng)
    lat_span = content_tag(content_tag('', :class => 'value-title', :title => lat), :class => 'latitude')
    lng_span = content_tag(content_tag('', :class => 'value-title', :title => lng), :class => 'longitude')
    text = opts[:text] || ''
    content_tag(lat_meta + lng_meta + lat_span + lng_span + text, :class => 'geo', :itemprop => 'geo', :itemscope => 'itemscope', :itemtype => 'http://data-vocabulary.org/Geo')
  end

  def download_link(url, opts = {})
    str = opts.delete(:text) || "Download vCard"
    new_url = "http://h2vx.com/vcf/" + url.gsub("http://", '')
    content_tag(str, merge_html_attrs({:tag => :a, :href => new_url, :type => 'text/directory'}, opts))
  end

  def content_tag(content, opts={})
    tag = opts.delete(:tag) || @default_tag
    attrs = opts.inject([]) do |out, tuple|
      k,v = tuple
      out << "#{k}='#{v}'"
    end
    attr_string = attrs.sort.join(' ')
    open_tag = attr_string == '' ? tag : "#{tag} #{attr_string}"
    if [:img].include?(tag)
      "<#{open_tag} />"
    else
      "<#{open_tag}>#{content}</#{tag}>"
    end
  end

  def concat_tag(opts={})
    tag = opts.delete(:tag) || @default_tag
    attrs = opts.inject([]) do |out, tuple|
      k,v = tuple
      out << "#{k}='#{v}'"
    end
    attr_string = attrs.sort.join(' ')
    open_tag = attr_string == '' ? tag : "#{tag} #{attr_string}"
    concat "<#{open_tag}>\n"
    yield
    concat "</#{tag}>\n"
  end

  def merge_html_attrs(base_attrs, overriding_attrs)
    classes = [base_attrs.delete(:class), overriding_attrs.delete(:class)].flatten.compact.sort.join(' ')
    attrs = base_attrs.merge(overriding_attrs)
    attrs[:class] = classes unless classes == '' # [].join #=> ''
    attrs
  end
end