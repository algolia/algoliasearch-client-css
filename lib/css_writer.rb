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
  def self.cloudinary(url, fetch: false)
    base = 'http://res.cloudinary.com/hilnmyskv/image'
    unless fetch
      # Our cloudinary account is mappting the /team virtual directory to the
      # asset directory of algolia.com
      # t_looflirpa is the name of the named transformation
      return "#{base}/upload/t_looflirpa,f_auto/team/#{url.split('/')[-1]}"
    end

    transformations = 'c_scale,e_grayscale,f_auto,h_220,q_90,r_max,w_220'
    "#{base}/fetch/#{transformations}/#{url}"
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
      label_selector = "#l#{index}"
      radio_selector = "#f#{index}"

      facet_to_selectors[facet_name] = {
        label: label_selector,
        radio: radio_selector
      }
    end

    facet_to_selectors
  end

  # Apply facet counts
  def self.add_facets(css, all_facets, records)
    # We start by pre-filling all the labels already in the page with their
    # default names (they won't still have the correct count nor position, this
    # will be handled on a prefix-by-prefix basis afterward).
    # We also remember the radio and label selectors for ease of use afterward
    facet_to_selectors = facet_selectors(all_facets['__EMPTY_QUERY__'])
    all_facets['__EMPTY_QUERY__'].each do |facet|
      facet_name = facet[:name]
      label_selector = facet_to_selectors[facet_name][:label]
      radio_selector = facet_to_selectors[facet_name][:radio]

      # Filling the labels with the names
      css << "#{label_selector}:before { content: '#{facet_name}'; }"

      # When clicking on any facet, we hide it, and display the placeholder with
      # the new name instead
      css << "#{radio_selector}[id]:checked ~ #f #{label_selector} { display: none; }"
      css << "#{radio_selector}:checked ~ #f label[for=fx]:before { content: '#{facet_name}' }"

      # When selecting this facet, we hide all results that are not part of this
      # facet.
      facet_attribute = facet[:attribute]
      records.each.with_index do |record, index|
        facet_value = record[facet_attribute]
        next if facet_value == facet_name
        # Using [id] is a trick to increase the specificity without using
        # !important (it uses less characters)
        css << "#{radio_selector}[id]:checked ~ #h #h#{index} { display: none; }"
      end
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

        selector = "#{input(prefix)} ~ #f #{label_selector}"
        css << "#{selector} { display: block; order: #{order}; }"
        css << "#{selector}:after { content: '#{facet_count}'; }"

        # If a specific facet is selected we  reflect the count and
        # position in the placeholder
        base_checked_selector = "#{radio_selector}:checked ~ #{input(prefix)} ~ #f "
        css << "#{base_checked_selector} #lx { display: block; order: #{order}; }"
        css << "#{base_checked_selector} #lx:after { content: '#{facet_count}'; }"
      end
    end

    css
  end

  def self.add_results(css, lookup_table)
    record_to_selector = {}

    # We pre-fill all the results with the results of the empty query
    lookup_table['__EMPTY_QUERY__'].each.with_index do |entry, index|
      object_id = entry[:record]['objectID']
      record_to_selector[object_id] = "#h#{index}"

      selector = "#h#{index}"
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
        base_selector = "#{input(prefix_selector)} ~ #h #{hit_selector}"

        # We display the results for the prefix
        css << "#{base_selector} { display: block; order: #{order}; }"
        css << "#{base_selector}:before { content: '#{name}\\A #{role}'; }"
      end
    end

    css
  end
end
