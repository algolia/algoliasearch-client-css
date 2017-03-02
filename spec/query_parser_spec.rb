require 'spec_helper'

describe(QueryParser) do

  describe 'index' do
    it 'should create an EntryList for each prefix' do
      # Given
      record = { foo: 'bar' }
      options = { keyword: 'tim' }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual).to include 't'
      expect(actual).to include 'ti'
      expect(actual).to include 'tim'
    end

    it 'should return an array for each prefix' do
      # Given
      record = { foo: 'bar' }
      options = { keyword: 'tim' }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual['t']).to be_an Array
    end

    it 'should have highlight information' do
      # Given
      record = { foo: 'bar' }
      options = { keyword: 'tim' }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual['ti'][0][:highlight][:keyword]).to eq 'tim'
      expect(actual['ti'][0][:highlight][:highlight]).to eq 'ti'
      expect(actual['ti'][0][:highlight][:after]).to eq 'm'
    end

    it 'should keep the record data linked to each EntryList' do
      # Given
      record = { foo: 'bar' }
      options = { keyword: 'tim' }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual['t'][0][:record]).to eq record
      expect(actual['ti'][0][:record]).to eq record
      expect(actual['tim'][0][:record]).to eq record
    end

    it 'should let me override highlight data' do
      # Given
      record = { foo: 'bar' }
      options = {
        keyword: 'tim',
        highlight: {
          before: 'foo'
        }
      }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual['t'][0][:highlight][:before]).to eq 'foo'
    end

    it 'should index each word of the searchable_attribute' do
      # Given
      record = { foo: 'bar' }
      options = { keyword: 'tim carry' }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual).to include 'ti'
      expect(actual).to include 'car'
    end

    it 'should remember the highlight prefix for additional words' do
      # Given
      record = { foo: 'bar' }
      options = { keyword: 'tim carry' }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual['car'][0][:highlight][:keyword]).to eq 'carry'
      expect(actual['car'][0][:highlight][:before]).to eq 'tim '
      expect(actual['car'][0][:highlight][:highlight]).to eq 'car'
      expect(actual['car'][0][:highlight][:after]).to eq 'ry'
    end

    it 'should index without accented characters' do
      # Given
      record = { foo: 'bar' }
      options = { keyword: 'gaëtan' }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual).to include 'gae'
      expect(actual).to include 'gaë'
    end

    it 'should keep the accents in the highlight' do
      # Given
      record = { foo: 'bar' }
      options = { keyword: 'gaëtan' }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual['gae'][0][:highlight][:keyword]).to eq 'gaëtan'
    end

    it 'should index without accented characters in the last name' do
      # Given
      record = { foo: 'bar' }
      options = { keyword: 'adam surák' }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual).to include 'adam surak'
      expect(actual).to include 'adam surák'
    end

    it 'should find names with multiples words with each of them' do
      # Given
      record = { foo: 'bar' }
      options = { keyword: 'jeremy ben sadoun' }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual).to include 'jeremy'
      expect(actual).to include 'ben'
      expect(actual).to include 'sadoun'
      expect(actual).to include 'jeremy ben'
      expect(actual).to include 'jeremy ben sadoun'
      expect(actual).to include 'ben sadoun'
    end

    it 'should split words on dashes' do
      # Given
      record = { foo: 'bar' }
      options = { keyword: 'paul-louis nech' }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual).to include 'paul'
      expect(actual).to include 'louis'
      expect(actual).to include 'nech'
      expect(actual['louis'][0][:highlight][:before]).to eq 'paul-'
      expect(actual['nech'][0][:highlight][:before]).to eq 'paul-louis '
    end

    it 'should find composed words when typing dash' do
      # Given
      record = { foo: 'bar' }
      options = { keyword: 'remy-christophe' }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual).to include 'remy-christophe'
    end

    it 'should find composed words when typing space' do
      # Given
      record = { foo: 'bar' }
      options = { keyword: 'remy-christophe' }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual).to include 'remy christophe'
      expect(actual['remy christophe'][0][:highlight][:keyword]).to eq 'remy-christophe'
    end
  end

  describe 'merge' do
    it 'should merge several EntryTables' do
      # Given
      record_1 = { foo: 'bar' }
      record_2 = { foo: 'baz' }
      entry_table_1 = QueryParser.index(record_1, keyword: 'tim')
      entry_table_2 = QueryParser.index(record_2, keyword: 'mark')

      # When
      actual = QueryParser.merge(entry_table_1, entry_table_2)

      # Then
      expect(actual).to include 't'
      expect(actual).to include 'ti'
      expect(actual).to include 'tim'
      expect(actual).to include 'm'
      expect(actual).to include 'ma'
      expect(actual).to include 'mar'
      expect(actual).to include 'mark'
    end

    it 'should group EntryTables sharing the same prefix' do
      # Given
      record_1 = { foo: 'bar' }
      record_2 = { foo: 'baz' }
      entry_table_1 = QueryParser.index(record_1, keyword: 'tim')
      entry_table_2 = QueryParser.index(record_2, keyword: 'tom')

      # When
      actual = QueryParser.merge(entry_table_1, entry_table_2)

      # Then
      expect(actual).to include 't'
      expect(actual['t'].length).to eq 2
    end
  end

  describe 'uniq' do
    it 'should remove duplicates for a given prefix' do
      # Given
      record_1 = { 'objectID' => 'A' }
      record_2 = { 'objectID' => 'A' }
      entry_table_1 = QueryParser.index(record_1, keyword: 'f')
      entry_table_2 = QueryParser.index(record_2, keyword: 'f')
      lookup_table = QueryParser.merge(entry_table_1, entry_table_2)

      # When
      actual = QueryParser.uniq(lookup_table)

      # Then
      expect(actual['f'].length).to eq 1
    end

    it 'should make sure normalized and non-normalized version have the same results' do
      # Given
      record_1 = { 'objectID' => 'foo' }
      record_2 = { 'objectID' => 'bar' }
      entry_table_1 = QueryParser.index(record_1, keyword: 'clément')
      entry_table_2 = QueryParser.index(record_2, keyword: 'clement')
      lookup_table = QueryParser.merge(entry_table_1, entry_table_2)

      # When
      actual = QueryParser.uniq(lookup_table)

      # Then
      expect(actual['clement'].length).to eq 2
      expect(actual['clément'].length).to eq 2
    end
  end

  describe 'sort' do
    it 'should order results based on match on first name / last name' do
      # Given
      record_1 = { 'objectID' => 1, 'name' => 'paul-louis nech' }
      record_2 = { 'objectID' => 2, 'name' => 'neil richler' }
      entry_table_1 = QueryParser.index(record_1, keyword: 'paul-louis nech')
      entry_table_2 = QueryParser.index(record_2, keyword: 'neil richler')
      lookup_table = QueryParser.merge(entry_table_1, entry_table_2)

      # When
      actual = QueryParser.sort(lookup_table)

      # Then
      expect(actual['ne'].length).to eq 2
      expect(actual['ne'][0][:record]['name']).to eq 'neil richler'
      expect(actual['ne'][1][:record]['name']).to eq 'paul-louis nech'
    end

    it 'should order equalities based on the specified customRanking' do
      # Given
      record_1 = { 'objectID' => 'foo', 'order' => 12, 'name' => 'clément leprovost' }
      record_2 = { 'objectID' => 'bar', 'order' => 6, 'name' => 'dustin coates' }
      record_3 = { 'objectID' => 'baz', 'order' => 3, 'name' => 'tim carry' }
      entry_table_1 = QueryParser.index(record_1, keyword: 'clément leprovost')
      entry_table_2 = QueryParser.index(record_2, keyword: 'dustin coates')
      entry_table_3 = QueryParser.index(record_3, keyword: 'tim carry')
      lookup_table = QueryParser.merge(entry_table_1, entry_table_2, entry_table_3)

      # When
      actual = QueryParser.sort(lookup_table, 'order')

      # Then
      expect(actual['c'].length).to eq 3
      expect(actual['c'][0][:record]['name']).to eq 'clément leprovost'
      expect(actual['c'][1][:record]['name']).to eq 'tim carry'
      expect(actual['c'][2][:record]['name']).to eq 'dustin coates'
    end
  end

  describe 'add_synonyms' do
    it 'should add entries if original word is found' do
      # Given
      record = { 'objectID' => 'foo', 'name' => 'Rémy-Christophe' }
      entry_table = QueryParser.index(record, keyword: 'Rémy-Christophe')
      lookup_table = QueryParser.sort(entry_table)
      synonyms = {
        'Rémy-Christophe' => %w(rcs scala)
      }

      # When
      actual = QueryParser.add_synonyms(lookup_table, synonyms)

      # Then
      expect(actual).to include 'rcs'
      expect(actual).to include 'scala'
    end

    it 'should not add entries if original word not is found' do
      # Given
      record = { 'objectID' => 'foo', 'name' => 'Rémy-Christophe' }
      entry_table = QueryParser.index(record, keyword: 'Rémy-Christophe')
      lookup_table = QueryParser.sort(entry_table)
      synonyms = {
        'foo' => %w(rcs scala)
      }

      # When
      actual = QueryParser.add_synonyms(lookup_table, synonyms)

      # Then
      expect(actual).to_not include 'rcs'
    end

    it 'should replace highlight with synonym' do
      # Given
      record = { 'objectID' => 'foo', 'name' => 'Rémy-Christophe' }
      entry_table = QueryParser.index(record, keyword: 'Rémy-Christophe')
      lookup_table = QueryParser.sort(entry_table)
      synonyms = {
        'Rémy-Christophe' => %w(rcs scala)
      }

      # When
      actual = QueryParser.add_synonyms(lookup_table, synonyms)

      # Then
      expect(actual['rcs'][0][:highlight][:keyword]).to eq 'Rémy-Christophe'
      expect(actual['rcs'][0][:highlight][:is_synonym]).to eq true
    end
  end

  describe 'empty_query' do
    it 'should create an entry for the empty query with one entry per person' do
      # Given
      inputs = [
        { 'name' => 'foo' },
        { 'name' => 'bar' },
        { 'name' => 'baz' }
      ]

      # When
      actual = QueryParser.empty_query(inputs, 'name')

      # Then
      expect(actual).to include '__EMPTY_QUERY__'
      expect(actual['__EMPTY_QUERY__'].length).to eq 3
    end

    it 'should contain the whole initial records' do
      # Given
      inputs = [
        { 'name' => 'foo' },
        { 'name' => 'bar' },
        { 'name' => 'baz' }
      ]

      # When
      actual = QueryParser.empty_query(inputs, 'name')

      # Then
      expect(actual['__EMPTY_QUERY__'][0][:record]['name']).to eq 'foo'
    end

    it 'should have the specified keyword highlighted' do
      # Given
      inputs = [
        { 'name' => 'foo' },
        { 'name' => 'bar' },
        { 'name' => 'baz' }
      ]

      # When
      actual = QueryParser.empty_query(inputs, 'name')

      # Then
      expect(actual['__EMPTY_QUERY__'][0][:highlight][:before]).to eq 'foo'
      expect(actual['__EMPTY_QUERY__'][0][:highlight][:highlight]).to eq nil
      expect(actual['__EMPTY_QUERY__'][0][:highlight][:after]).to eq nil
    end
  end

  describe 'add_typos' do
    it 'should add typos of missing previous to last character' do
      record = { 'objectID' => 'foo' }
      entry_table = QueryParser.index(record, keyword: 'Dustin')
      lookup_table = QueryParser.sort(entry_table)

      # When
      actual = QueryParser.add_typos(lookup_table)

      # Then
      expect(actual).to include 'Dustin'
      expect(actual).to include 'Dut'
      expect(actual).to include 'Dusi'
      expect(actual).to include 'Dustn'
      expect(actual).to include 'Dutin'
    end
  end

  fdescribe 'generate_facets' do
    it 'should generate an entry with potential facets for each prefix' do
      # Given
      record_1 = { 'objectID' => 0, 'team' => 'Community' }
      record_2 = { 'objectID' => 1, 'team' => 'Sales' }
      record_3 = { 'objectID' => 2, 'team' => 'Marketing' }
      entry_table_1 = QueryParser.index(record_1, keyword: 'aaa')
      entry_table_2 = QueryParser.index(record_2, keyword: 'abb')
      entry_table_3 = QueryParser.index(record_3, keyword: 'abc')
      lookup_table = QueryParser.merge(entry_table_1, entry_table_2, entry_table_3)

      # When
      actual = QueryParser.generate_facets(lookup_table, 'team')

      # Then
      expect(actual['a'].length).to eq 3
      expect(actual['ab'].length).to eq 2
      expect(actual['abc'].length).to eq 1
    end

    it 'should have the facet name, count and items' do
      # Given
      record_1 = { 'objectID' => 0, 'team' => 'Community' }
      record_2 = { 'objectID' => 1, 'team' => 'Sales' }
      record_3 = { 'objectID' => 2, 'team' => 'Sales' }
      entry_table_1 = QueryParser.index(record_1, keyword: 'foo')
      entry_table_2 = QueryParser.index(record_2, keyword: 'bar')
      entry_table_3 = QueryParser.index(record_3, keyword: 'baz')
      lookup_table = QueryParser.merge(entry_table_1, entry_table_2, entry_table_3)

      # When
      actual = QueryParser.generate_facets(lookup_table, 'team')

      # Then
      expect(actual['ba'][0][:name]).to eq 'Sales'
      expect(actual['ba'][0][:count]).to eq 2
      expect(actual['ba'][0][:items]).to include 1
      expect(actual['ba'][0][:items]).to include 2
    end

    it 'should sort facets by count' do
      # Given
      record_1 = { 'objectID' => 0, 'team' => 'Community' }
      record_2 = { 'objectID' => 1, 'team' => 'Sales' }
      record_3 = { 'objectID' => 2, 'team' => 'Sales' }
      entry_table_1 = QueryParser.index(record_1, keyword: 'aaa')
      entry_table_2 = QueryParser.index(record_2, keyword: 'abb')
      entry_table_3 = QueryParser.index(record_3, keyword: 'abc')
      lookup_table = QueryParser.merge(entry_table_1, entry_table_2, entry_table_3)

      # When
      actual = QueryParser.generate_facets(lookup_table, 'team')

      # Then
      expect(actual['a'][0][:name]).to eq 'Sales'
      expect(actual['a'][1][:name]).to eq 'Community'
    end

    it 'should generate facets for the empty query' do
      # Given
      inputs = [
        { 'objectID' => 0, 'team' => 'Community' },
        { 'objectID' => 1, 'team' => 'Sales' },
        { 'objectID' => 2, 'team' => 'Sales' }
      ]

      # When
      actual = QueryParser.generate_facets({}, 'team', inputs)

      # Then
      expect(actual).to include '__EMPTY_QUERY__'
      expect(actual['__EMPTY_QUERY__'].length).to eq 2
      expect(actual['__EMPTY_QUERY__'][0][:name]).to eq 'Sales'
      expect(actual['__EMPTY_QUERY__'][1][:name]).to eq 'Community'
    end
  end
end
