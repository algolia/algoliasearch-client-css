require 'awesome_print'

# Writes CSS rules that match a given LookupTable
class CSSWriter
  # From an highlight hash, return a string, replacing highlighted text with
  # private unicode
  def self.highlight(data)
    # Highlighting the middle part
    middle = data[:highlight] || ''
    highlight = ''
    middle.split('').each do |char|
      char_code = char.ord
      # There is no char for a space, so we keep it that way
      if char_code == 32
        highlight += ' '
        next
      end
      private_char_code = char_code + 58_880

      css_char = private_char_code.to_s(16)

      highlight += '\\' + css_char + ' '
    end

    "#{data[:before]}#{highlight}#{data[:after]}"
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
    'https://res.cloudinary.com/hilnmyskv/image/upload/t_looflirpa,f_auto/team/' \
      + url.split('/')[-1]
  end

  # Return a selector for the input with a specific query
  def self.input(query)
    "#i[value='#{query}' i]"
  end

  # Create a hash table of the list of all facets, and the way to target the
  # corresponding radio or label
  def self.facet_selectors(empty_query_facet)
    facet_to_selectors = {}
    empty_query_facet.each.with_index do |facet, index|
      facet_name = facet[:name]
      label_selector = "label[for='f#{index}']"
      radio_selector = "#f#{index}"

      facet_to_selectors[facet_name] = {
        label: label_selector,
        radio: radio_selector
      }
    end

    facet_to_selectors
  end

  # Apply facet counts
  def self.add_facet_counts(css, all_facets)
    # We start by pre-filling all the labels already in the page with their
    # default names (they won't still have the correct count nor position, this
    # will be handled on a prefix-by-prefix basis afterward).
    # We also remember the radio and label selectors for ease of use afterward
    facet_to_selectors = facet_selectors(all_facets['__EMPTY_QUERY__'])
    all_facets['__EMPTY_QUERY__'].each.with_index do |facet, index|
      facet_name = facet[:name]
      label_selector = facet_to_selectors[facet_name][:label]
      radio_selector = facet_to_selectors[facet_name][:radio]

      # Filling the labels with the names
      css << "#{label_selector}:before { content: '#{facet_name}'; }"

      # When clicking on any facet, we hide it, and display the placeholder with
      # the new name instead
      base_checked_selector = "#{radio_selector}:checked ~ aside"
      css << "#{base_checked_selector} #{label_selector} { display: none !important; }"
      css << "#{base_checked_selector} label[for=fx]:before { content: '#{facet_name}' }"
    end
    
    # For each prefix, we will display the matching facets, and update their
    # position and count
    all_facets.each do |prefix, facets|
      prefix = '' if prefix == '__EMPTY_QUERY__'
      available_facets = []

      facets.each.with_index do |facet, order|
        facet_name = facet[:name]
        available_facets.push(facet_name)
        facet_count = facet[:count]
        label_selector = facet_to_selectors[facet_name][:label]
        radio_selector = facet_to_selectors[facet_name][:radio]

        selector = "#{input(prefix)} ~ aside #{label_selector}"
        css << "#{selector} { display: block; order: #{order}; }"
        css << "#{selector}:after { content: '#{facet_count}'; }"

        # If a specific facet is selected we  reflect the count and
        # position in the placeholder
        base_checked_selector = "#{radio_selector}:checked ~ #{input(prefix)} ~ aside "
        css << "#{base_checked_selector} label[for=fx] { display: block; order: #{order}; }"
        css << "#{base_checked_selector} label[for=fx]:after { content: '#{facet_count}'; }"
      end
    end

    css
  end

  def self.add_results(css, lookup_table, all_facets)
    facet_to_selectors = facet_selectors(all_facets['__EMPTY_QUERY__'])
    record_to_selector = {}

    # We pre-fill all the results with the results of the empty query
    lookup_table['__EMPTY_QUERY__'].each.with_index do |entry, index|
      object_id = entry[:record]['objectID']
      record_to_selector[object_id] = "#h#{index}"

      selector = "#i ~ section #h#{index}"
      quote = "#{entry[:record]['emoji']}\\A #{entry[:record]['funny_quote']}".gsub("'", '\\\0027 ')

      css << "#{selector} { background-image: url(#{entry[:record]['image']}); }"
      css << "#{selector}:after { content: '#{quote}'; }"
    end

    # For each prefix, we display the results that match, update their name and
    # position
    lookup_table.each do |prefix, entries|
      prefix_selector = prefix
      prefix_selector = '' if prefix == '__EMPTY_QUERY__'

      # We had a counter
      count = entries.length
      css << "#{input(prefix_selector)} ~ #r:before { content: '#{count}'; }"
      if count == 1
        css << "#{input(prefix_selector)} ~ #r:after { content: ' result'; }"
      end

      entries.each.with_index do |entry, order|
        name = entry[:record]['name']
        name = highlight(entry[:highlights]['name']) if entry[:highlights].key? 'name'
        role = entry[:record]['role']
        role = highlight(entry[:highlights]['role']) if entry[:highlights].key? 'role'

        hit_selector = record_to_selector[entry[:record]['objectID']]
        base_selector = "#{input(prefix_selector)} ~ section #{hit_selector}"

        # We display the results for the prefix
        css << "#{base_selector} { display: block; order: #{order}; }"
        css << "#{base_selector}:before { content: '#{name}\\A #{role}'; }"

        # We hide the results if the selected facet is not the facet of the
        # result
        next unless all_facets.key? prefix
        all_facets[prefix].each do |facet|
          facet_name = facet[:name]
          attribute = facet[:attribute]
          entry_facet_value = entry[:record][attribute]

          # We skip if the selected facet is equal to the facet of this result
          next if facet_name == entry_facet_value

          # We hide the result that match an unselected facet
          radio_selector = facet_to_selectors[facet_name][:radio]
          checked_base_selector = "#{radio_selector}:checked ~ #{base_selector}"
          css << "#{checked_base_selector} { display: none; }"
        end
      end
    end


    css
  end
end
