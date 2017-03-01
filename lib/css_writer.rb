require 'awesome_print'

# Writes CSS rules that match a given LookupTable
class CSSWriter
  # Given a prefix and an entry, should return the matching CSS rule
  def self.rule(keyword, entries)
    css = []
    keyword = '' if keyword == '__EMPTY_QUERY__'

    entries.each_with_index do |entry, i|
      h = entry[:highlight]
      content = "#{h[:before]}#{highlight(h[:highlight])}#{h[:after]}"
      quote = "#{entry[:record]['emoji']}\\A #{entry[:record]['funny_quote']}".gsub("'", '\\\0027 ')

      div_selector = " ~ section > div:nth-child(#{i + 1})"

      css << "input[value='#{keyword}' i]#{div_selector} {"
      css << "background-image: url(#{entry[:record]['image']});"
      css << 'display: block;'
      css << '}'
      css << "input[value='#{keyword}' i]#{div_selector}:before {"
      css << "content: '#{content}\\A #{entry[:record]['role']}'"
      css << '}'
      css << "input[value='#{keyword}' i]#{div_selector}:after {"
      css << "content: '#{quote}'"
      css << '}'
    end

    css.join('')
  end

  # Highlighting is done using characters in the private area of Unicode
  def self.highlight(text)
    return '' if text.nil?

    highlighted_text = ''
    text.split('').each do |char|
      char_code = char.ord
      # There is no char for a space, so we keep it that way
      if char_code == 32
        highlighted_text += ' '
        next
      end
      private_char_code = char_code + 58_880
      css_char = private_char_code.to_s(16)

      highlighted_text += '\\' + css_char + ' '
    end
    highlighted_text
  end

  # Base CSS to be added to the search
  def self.base
    []
  end

  # Get the Cloudinary link to an image
  def self.cloudinary(url)
    # Our cloudinary account is mappting the /team virtual directory to the
    # asset directory of algolia.com
    # t_looflirpa is the name of the named transformation
    'https://res.cloudinary.com/hilnmyskv/image/upload/t_looflirpa/team/' \
      + url.split('/')[-1]
  end

  # Preload all images by loading the images in the body background
  def self.preload_images(css, records)
    preloaded_images = []
    records.each do |record|
      preloaded_images.push("url(#{record['image']})")
    end
    css.push('body:before{content:""; display:none; '\
           "background:#{preloaded_images.join(',')}}")
    css
  end

  # Apply facet counts
  def self.add_facet_counts(css, all_facets)
    # Create an array with the name and count of each
    counts = {}
    all_facets.each do |prefix, facets|
      counts[prefix] = [] unless counts.key? prefix
      facets.each do |facet_name, values|
        counts[prefix].push(name: facet_name, count: values.length)
      end
    end

    # Create the CSS rules
    counts.each do |prefix, facets|
      prefix = '' if prefix == '__EMPTY_QUERY__'
      facets = facets.sort_by { |facet| facet[:count] }.reverse
      facets.each.with_index do |facet, i|
        base_selector = "input[value='#{prefix}' i] ~ aside > label:nth-child(#{i + 1})"
        css << "#{base_selector} { display: block; }"
        css << "#{base_selector}:before { content: '#{facet[:name]}'; }"
        css << "#{base_selector}:after { content: '#{facet[:count]}'; }"
      end
    end

    css
  end
end
