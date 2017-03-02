require 'awesome_print'

# Writes CSS rules that match a given LookupTable
class CSSWriter
  # Given a prefix and an entry, should return the matching CSS rule
  def self.rule(prefix, entries)
    css = []
    prefix = '' if prefix == '__EMPTY_QUERY__'

    entries.each_with_index do |entry, i|
      h = entry[:highlight]
      content = "#{h[:before]}#{highlight(h[:highlight])}#{h[:after]}"
      quote = "#{entry[:record]['emoji']}\\A #{entry[:record]['funny_quote']}".gsub("'", '\\\0027 ')

      base_selector = "#{input(prefix)} ~ section > div:nth-child(#{i + 1})"

      css << "#{base_selector} { display: block; background-image: url(#{entry[:record]['image']}); display: block; }"
      css << "#{base_selector}:before { content: '#{content}\\A #{entry[:record]['role']}'; }"
      css << "#{base_selector}:after { content: '#{quote}'; }"
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

  # Return a selector for the input with a specific query
  def self.input(query)
    "#i[value='#{query}' i]"
  end

  # Apply facet counts
  def self.add_facet_counts(css, all_facets)
    # We start by pre-filling all the labels already in the page with their
    # default names (they won't still have the correct count nor position, this
    # will be handled on a prefix-by-prefix basis afterward).
    # We also remember the radio and label selectors for ease of use afterward
    facet_to_selectors = {}
    all_facets['__EMPTY_QUERY__'].each.with_index do |facet, index|
      facet_name = facet[:name]
      label_selector = "label[for='f#{index}']"
      radio_selector = "#f#{index}"

      facet_to_selectors[facet_name] = {
        label: label_selector,
        radio: radio_selector
      }

      # Filling the labels with the names
      css << "#{label_selector}:before { content: '#{facet_name}'; }"

      # When clicking on any facet, we hide it, and display the placeholder with
      # the new name instead
      base_checked_selector = "#{radio_selector}:checked ~ aside "
      css << "#{base_checked_selector} label[for=fx] { display: block; }"
      css << "#{base_checked_selector} label[for=fx]:before { content: '#{facet_name}' }"
    end
    
    # For each prefix, we will display the matching facets, and update their
    # position and count
    all_facets.each do |prefix, facets|
      prefix = '' if prefix == '__EMPTY_QUERY__'

      facets.each.with_index do |facet, order|
        facet_name = facet[:name]
        facet_count = facet[:count]
        label_selector = facet_to_selectors[facet_name][:label]
        radio_selector = facet_to_selectors[facet_name][:radio]

        selector = "#{input(prefix)} ~ aside #{label_selector}"
        css << "#{selector} { display: block; order: #{order}; }"
        css << "#{selector}:after { content: '#{facet_count}'; }"

        # If a specific facet is selected, we hide it, but reflect the count and
        # position in the placeholder
        base_checked_selector = "#{radio_selector}:checked ~ #{input(prefix)} ~ aside "
        css << "#{base_checked_selector} #{label_selector} { display: none; }"
        css << "#{base_checked_selector} label[for=fx] { order: #{order}; }"
        css << "#{base_checked_selector} label[for=fx]:after { content: '#{facet_count}'; }"
      end
    end

    css
  end

  def self.add_facet_results(css, all_facets)
  end
end
