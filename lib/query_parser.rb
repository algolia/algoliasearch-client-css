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

      # If the keywords contain non-ascii chars, we also index the full-ascii
      # version

      add_to_entry_list(entry_list, prefix, record, highlight)

      index += 1
    end

    # If the SearchableAttribute has several words, we need to index them as
    # well
    split_words = keyword.split(' ')
    return entry_list if split_words.length == 1

    # We index each succession of words after the first one
    before = split_words[0] + ' '
    keyword_subset = split_words[1..-1].join(' ')
    options = {
      keyword: keyword_subset,
      highlight: {
        before: before
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
      entry_list[normalized_prefix] = [] unless entry_list.key?(normalized_prefix)
      entry_list[normalized_prefix].push(
        record: record,
        highlight: highlight
      )
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

end
