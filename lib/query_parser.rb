require 'awesome_print'
require 'i18n'
I18n.available_locales = [:en]

# Converts records to structure-like object containing all the highlight
# information
class QueryParser
  # Will take a hash as input, and return an EntryList, with all the matches
  # that will yield this record
  # Options:
  #   - matches: And array of hashes
  #     - attribute: What attribute should be highlighted
  #     - keyword: What query should match it
  #   - _highlights: Hash to use to override the highlight data
  def self.index(record, options)
    # Allowed options
    matches = options[:matches]
    matches = [matches] unless matches.is_a? Array
    hl_override = options[:highlights] || {}

    entry_list = {}
    matches.each do |match|
      attribute = match[:attribute]
      keyword = match[:keyword]
      length = keyword.length
      index = 0
      while index < length
        prefix = keyword[0..index]
        after = keyword[index + 1..-1]

        highlights = {}
        highlights[attribute] = {
          keyword: keyword,
          before: nil,
          highlight: prefix,
          after: after
        }
        # We allow overriding the highlight data to give some context
        if hl_override.key? attribute
          highlights[attribute].merge!(hl_override[attribute])
        end

        add_to_entry_list(entry_list, prefix, record, highlights)

        index += 1
      end

      # If there are several words in the attribute, we remove the first one and
      # index the rest. This will be applied recursively.
      word_split = keyword.match(/^((.*?)([ -]))(.*)/)
      next if word_split.nil?

      highlights = {}
      hl_prefix = hl_override[attribute][:before] if hl_override.key? attribute
      highlights[attribute] = {
        before: "#{hl_prefix}#{word_split[1]}"
      }
      options = {
        matches: { attribute: attribute, keyword: word_split[4] },
        highlights: highlights
      }
      entry_list = merge(entry_list, index(record, options))
    end

    entry_list
  end

  def self.add_to_entry_list(entry_list, prefix, record, highlights)
    prefix = prefix.downcase
    entry_list[prefix] = [] unless entry_list.key?(prefix)
    
    # Checking if we already have a record saved for this prefix
    existing_record = entry_list[prefix].find do |checked_record|
      checked_record[:record]['objectID'] == record['objectID']
    end

    # If not in the list, we add it, otherwise we just merge the highlights
    if existing_record.nil?
      entry_list[prefix].push(record: record, highlights: highlights)
    else
      existing_record[:highlights].merge!(highlights)
    end

    # If it contains special chars, we also save it in the normalized version
    normalized_prefix = I18n.transliterate(prefix)
    if normalized_prefix != prefix
      add_to_entry_list(entry_list, normalized_prefix, record, highlights)
    end

    # If it contains separators, we also save the versions with separators
    # replaced with spaces
    normalized_prefix = prefix.tr('-', ' ')
    if normalized_prefix != prefix
      add_to_entry_list(entry_list, normalized_prefix, record, highlights)
    end

    entry_list
  end

  # Will take several EntryList and create a LookupTable of all of them
  def self.merge(*entry_lists)
    lookup_table = {}
    entry_lists.each do |entry_list|
      entry_list.each do |prefix, data|
        lookup_table[prefix] = [] unless lookup_table.key?(prefix)
        lookup_table[prefix].concat(data)
      end
    end

    lookup_table
  end

  # Remove duplicates
  def self.uniq(lookup_table)
    lookup_table.each do |prefix, data|
      lookup_table[prefix] = data.uniq { |x| x[:record]['objectID'] }
    end

    # Making sure keywords with accents, also find results without
    lookup_table.each do |prefix, _data|
      normalized_prefix = I18n.transliterate(prefix)
      next if normalized_prefix == prefix
      count = lookup_table[prefix].length
      normalized_count = lookup_table[normalized_prefix].length
      next if count > normalized_count
      lookup_table[prefix] = lookup_table[normalized_prefix]
    end

    lookup_table
  end

  # Sort entries for each prefix
  def self.sort(lookup_table, ranking = {})
    searchable_attributes = ranking[:searchable_attributes]
    custom_ranking = ranking[:custom_ranking]

    # Sort results, by putting match at the start of the name first
    lookup_table.each do |prefix, entries|
      lookup_table[prefix] = entries.sort do |a, b|
        next 0 if a[:record] == b[:record]
        # Sort by searchable attribute
        score_attribute_a = score_attributes(a[:highlights], searchable_attributes)
        score_attribute_b = score_attributes(b[:highlights], searchable_attributes)
        next -1 if score_attribute_a > score_attribute_b
        next 1 if score_attribute_a < score_attribute_b

        # Sorting by position
        matching_attribute = a[:highlights].keys.first
        position_a = score_position(a[:highlights][matching_attribute])
        position_b = score_position(b[:highlights][matching_attribute])
        next -1 if position_a < position_b
        next 1 if position_a > position_b

        # Sorting by custom ranking
        ranking_value_a = a[:record][custom_ranking]
        ranking_value_b = b[:record][custom_ranking]
        next -1 if ranking_value_a < ranking_value_b
        next 1 if ranking_value_a > ranking_value_b

        0
      end
    end

    lookup_table
  end

  # Return a score based on the highlights and the specified attribute. If the
  # match is in one of the first searchable attributes, the score will be higher
  # than if it's one of the last attributes
  def self.score_attributes(highlights, attributes)
    lowest_position = attributes.length
    highlights.keys.each do |attribute|
      next unless attributes.include? attribute
      position = attributes.index(attribute)
      lowest_position = position if position < lowest_position
    end
    attributes.length - lowest_position
  end

  def self.score_position(highlight)
    return 0 if highlight[:highlight].nil?
    return 1 if highlight[:before].nil?
    highlight[:before].count(' -') + 1
  end

  # Duplicate entries with their synonyms
  def self.add_synonyms(lookup_table, records, synonyms)
    records.each do |record|
      synonyms.each do |synonym|
        attribute = synonym['attribute']
        value = record[attribute]
        original = synonym['original']
        next unless value == original

        replacement = synonym['replace']
        record_copy = Marshal.load(Marshal.dump(record))
        record_copy[attribute] = replacement

        matches = [{ attribute: attribute, keyword: replacement }]
        entry_table = QueryParser.index(record_copy, matches: matches)
        lookup_table = QueryParser.merge(lookup_table, entry_table)
      end
    end

    lookup_table
  end

  # Add entries for common typos
  def self.add_typos(lookup_table)
    min_length = 4
    tmp_table = {}
    lookup_table.each do |prefix, data|
      next if prefix == '__EMPTY_QUERY__'
      length = prefix.length
      next if length < min_length
      next if prefix.include? ' '

      (1..length - 2).each do |index|
        typoed_prefix = "#{prefix[0..index - 1]}#{prefix[index + 1..-1]}"
        tmp_table[typoed_prefix] = data
      end
    end

    merge(lookup_table, tmp_table)
  end

  # Special entry for the empty query, that will contain all the records, with
  # dummy highlight info
  def self.empty_query(people, searchable_attributes)
    searchable_attributes = [searchable_attributes] unless searchable_attributes.is_a?(Array)
    table = { '__EMPTY_QUERY__' => [] }

    # Adding each record
    people.each do |person|
      entry = {
        record: person
      }
      highlights = {}
      # Adding a highlight for each searchable attribute, but making it not
      # highlighted
      searchable_attributes.each do |attribute|
        highlights[attribute] = {
          before: person[attribute],
          highlight: nil,
          after: nil
        }
      end
      entry[:highlights] = highlights
      table['__EMPTY_QUERY__'].push(entry)
    end
    table
  end

  # Generate a hash of facets for each prefix and specified facet
  def self.generate_facets(lookup_table, attribute_for_facetting, dataset = [])
    list_per_facet = {}

    # We create, for each prefix, a hash that assign to each facet, the
    # corresponding list of matching objectIDs
    lookup_table.each do |prefix, entries|
      tmp_list = {}
      entries.each do |entry|
        facet_value = entry[:record][attribute_for_facetting]
        tmp_list[facet_value] = [] unless tmp_list.key? facet_value
        tmp_list[facet_value].push(entry[:record]['objectID'])
      end
      list_per_facet[prefix] = tmp_list
    end

    # We do the same thing for the empty query, based on the initial data
    facet_empty = {}
    dataset.each do |data|
      facet_value = data[attribute_for_facetting]
      facet_empty[facet_value] = [] unless facet_empty.key? facet_value
      facet_empty[facet_value].push(data['objectID'])
    end
    list_per_facet['__EMPTY_QUERY__'] = facet_empty

    # We sort the current list so each prefix now contains an ordered list of
    # facet objects
    facets_per_prefix = {}
    list_per_facet.each do |prefix, facets|
      facet_list = []
      facets.each do |facet_name, items|
        facet_list.push(
          name: facet_name,
          attribute: attribute_for_facetting,
          count: items.length
        )
      end
      facet_list = facet_list.sort_by { |facet| facet[:count] }.reverse
      facets_per_prefix[prefix] = facet_list
    end

    facets_per_prefix
  end
end
