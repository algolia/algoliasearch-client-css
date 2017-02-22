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
  def self.sort(lookup_table)
    lookup_table.each do |prefix, data|
      lookup_table[prefix] = data.uniq { |x| x[:record]['objectID'] }
    end
    lookup_table
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
