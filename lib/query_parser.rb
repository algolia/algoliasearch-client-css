require 'awesome_print'
require 'i18n'
I18n.available_locales = [:en]

# Converts records to structure-like object containing all the highlight
# information
class QueryParser
  # Will take a hash as input, and return an EntryList, with all the matches
  # that will yield this record
  # Options:
  #   - keyword: What query should match this document
  #   - highlight: Hash to us to override the highlight data
  def self.index(record, options)
    keyword = options[:keyword]
    highlight_override = options[:highlight] || {}

    entry_list = {}

    # Generate an entry for each prefix
    length = keyword.length
    index = 0
    while index < length
      prefix = keyword[0..index]
      after = keyword[index + 1..-1]

      # We allow overriding the highlight data to give some context
      highlight = {
        keyword: keyword,
        highlight: prefix,
        after: after
      }.merge(highlight_override)

      add_to_entry_list(entry_list, prefix, record, highlight)

      index += 1
    end

    # If several words, we recursively apply the same principle to the subset
    # that does not include the first word
    matches = keyword.match(/^((.*?)([ -]))(.*)/)
    return entry_list if matches.nil?
    options = {
      keyword: matches[4],
      highlight: {
        before: "#{highlight_override[:before]}#{matches[1]}"
      }
    }
    entry_list = merge(entry_list, index(record, options))

    entry_list
  end

  def self.add_to_entry_list(entry_list, prefix, record, highlight)
    entry_list[prefix] = [] unless entry_list.key?(prefix)
    entry_list[prefix].push(
      record: record,
      highlight: highlight
    )

    # If it contains special chars, we also save it in the normalized version
    normalized_prefix = I18n.transliterate(prefix)
    if normalized_prefix != prefix
      add_to_entry_list(entry_list, normalized_prefix, record, highlight)
    end

    # If it contains separators, we also save the versions with separators
    # replaced with spaces
    normalized_prefix = prefix.tr('-', ' ')
    if normalized_prefix != prefix
      add_to_entry_list(entry_list, normalized_prefix, record, highlight)
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

  # Sort entries for each prefix
  def self.sort(lookup_table, custom_ranking = nil)
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

    # Sort results, by putting match at the start of the name first
    lookup_table.each do |prefix, data|
      lookup_table[prefix] = data.sort do |a, b|
        has_a_before = a[:highlight][:before].nil?
        has_b_before = b[:highlight][:before].nil?
        next -1 if has_a_before && !has_b_before
        next 1 if has_b_before && !has_a_before

        unless custom_ranking.nil?
          next a[:record][custom_ranking] - b[:record][custom_ranking]
        end
        next 0
      end
    end

    lookup_table
  end

  # Duplicate entries with ther synonyms
  def self.add_synonyms(lookup_table, synonyms)
    tmp_table = {}
    lookup_table.each do |prefix, data|
      # No synonym defined for this prefix
      next unless synonyms.key?(prefix)

      # Creating new entries for each synonym
      synonyms[prefix].each do |synonym|
        tmp_table[synonym] = data.map do |entry|
          new_entry = Marshal.load(Marshal.dump(entry))
          new_entry[:highlight][:is_synonym] = true
          new_entry
        end
      end
    end

    merge(lookup_table, tmp_table)
  end

  # Special entry for the empty query, that will contain all the records, with
  # dummy highlight info
  def self.empty_query(people, keyword_attribute)
    table = { '__EMPTY_QUERY__' => [] }

    people.each do |person|
      table['__EMPTY_QUERY__'].push(
        highlight: {
          before: person[keyword_attribute]
        },
        record: person
      )
    end
    table
  end
end
