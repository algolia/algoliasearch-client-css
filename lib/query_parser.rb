require 'awesome_print'

# Converts records to structure-like object containing all the highlight
# information
class QueryParser
  # Given a single record, will create the object structure
  def self.record_to_struct(record)
    keyword = record[:keyword]
    data = record[:data]

    struct = {}
    length = keyword.length
    index = 0
    while index < length
      highlight = keyword[0..index]
      after = keyword[index + 1..-1]
      struct[highlight] = {
        highlight: highlight,
        after: after,
        data: data,
        keyword: keyword
      }
      index += 1
    end

    struct
  end

  # Given a set of records, will create the object strucure
  # def self.words_to_struct(records)
  #   struct = {}
  #   words.each do |word|
  #     word_struct = word_to_struct(word)
  #     word_struct.each do |key, value|
  #       struct[key] = [] unless struct.key?(key)
  #       struct[key].push(value)
  #     end
  #   end
  #   struct
  # end
end
