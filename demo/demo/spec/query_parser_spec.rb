require 'spec_helper'

describe(QueryParser) do
  describe 'index' do
    it 'should create an EntryList for each prefix' do
      # Given
      record = { name: 'tim' }
      options = { matches: [{ attribute: 'name', keyword: 'tim' }] }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual).to include 't'
      expect(actual).to include 'ti'
      expect(actual).to include 'tim'
    end

    it 'should return an array for each prefix' do
      # Given
      record = { name: 'tim' }
      options = { matches: [{ attribute: 'name', keyword: 'tim' }] }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual['t']).to be_an Array
      expect(actual['ti']).to be_an Array
      expect(actual['tim']).to be_an Array
    end

    it 'should create entries in downcase format' do
      # Given
      record = { name: 'Tim' }
      options = { matches: [{ attribute: 'name', keyword: 'Tim' }] }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual).to include 't'
      expect(actual).to include 'ti'
      expect(actual).to include 'tim'
      expect(actual).to_not include 'Tim'
    end

    it 'should have highlight information for one attribute' do
      # Given
      record = { name: 'tim' }
      options = { matches: [{ attribute: 'name', keyword: 'tim' }] }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual['ti'][0][:highlights]['name'][:keyword]).to eq 'tim'
      expect(actual['ti'][0][:highlights]['name'][:before]).to eq nil
      expect(actual['ti'][0][:highlights]['name'][:highlight]).to eq 'ti'
      expect(actual['ti'][0][:highlights]['name'][:after]).to eq 'm'
    end

    it 'should allow passing only one attribute' do
      # Given
      record = { name: 'tim' }
      options = { matches: { attribute: 'name', keyword: 'tim' } }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual['ti'][0][:highlights]['name'][:keyword]).to eq 'tim'
      expect(actual['ti'][0][:highlights]['name'][:before]).to eq nil
      expect(actual['ti'][0][:highlights]['name'][:highlight]).to eq 'ti'
      expect(actual['ti'][0][:highlights]['name'][:after]).to eq 'm'
    end

    it 'should add highlight for all attributes' do
      # Given
      record = { name: 'tim', role: 'dev' }
      options = { matches: [
        { attribute: 'name', keyword: 'tim' },
        { attribute: 'role', keyword: 'dev' }
      ] }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual).to include 'ti'
      expect(actual).to include 'de'
      expect(actual['ti'][0][:highlights]).to include 'name'
      expect(actual['ti'][0][:highlights]['name'][:before]).to eq nil
      expect(actual['ti'][0][:highlights]['name'][:highlight]).to eq 'ti'
      expect(actual['ti'][0][:highlights]['name'][:after]).to eq 'm'
      expect(actual['ti'][0][:highlights]['name'][:keyword]).to eq 'tim'
      expect(actual['de'][0][:highlights]).to include 'role'
      expect(actual['de'][0][:highlights]['role'][:before]).to eq nil
      expect(actual['de'][0][:highlights]['role'][:highlight]).to eq 'de'
      expect(actual['de'][0][:highlights]['role'][:after]).to eq 'v'
      expect(actual['de'][0][:highlights]['role'][:keyword]).to eq 'dev'
    end

    it 'should allow multiple highlight for the same prefix' do
      # Given
      record = { 'objectId' => 0, name: 'marie', role: 'marketing' }
      options = { matches: [
        { attribute: 'name', keyword: 'marie' },
        { attribute: 'role', keyword: 'marketing' }
      ] }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual).to include 'mar'
      expect(actual['mar'][0][:highlights]).to include 'name'
      expect(actual['mar'][0][:highlights]).to include 'role'
    end

    it 'should keep the record data linked to each EntryList' do
      # Given
      record = { name: 'Tim' }
      options = { matches: { attribute: 'name', keyword: 'Tim' } }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual['t'][0][:record]).to eq record
      expect(actual['ti'][0][:record]).to eq record
      expect(actual['tim'][0][:record]).to eq record
    end

    it 'should let me override highlight data' do
      # Given
      record = { name: 'tim' }
      options = {
        matches: { attribute: 'name', keyword: 'tim' },
        highlights: {
          'name' => {
            before: 'foo'
          }
        }
      }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual['t'][0][:highlights]['name'][:before]).to eq 'foo'
    end

    it 'should index each word of the searchable_attribute' do
      # Given
      record = { name: 'tim carry' }
      options = { matches: { attribute: 'name', keyword: 'tim carry' } }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual).to include 'ti'
      expect(actual).to include 'car'
    end

    it 'should remember the highlight prefix for additional words' do
      # Given
      record = { name: 'tim carry' }
      options = { matches: { attribute: 'name', keyword: 'tim carry' } }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual['car'][0][:highlights]['name'][:keyword]).to eq 'carry'
      expect(actual['car'][0][:highlights]['name'][:before]).to eq 'tim '
      expect(actual['car'][0][:highlights]['name'][:highlight]).to eq 'car'
      expect(actual['car'][0][:highlights]['name'][:after]).to eq 'ry'
    end

    it 'should index without accented characters' do
      # Given
      record = { name: 'gaëtan' }
      options = { matches: { attribute: 'name', keyword: 'gaëtan' } }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual).to include 'gae'
      expect(actual).to include 'gaë'
    end

    it 'should keep the accents in the highlight' do
      # Given
      record = { name: 'gaëtan' }
      options = { matches: { attribute: 'name', keyword: 'gaëtan' } }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual['gae'][0][:highlights]['name'][:keyword]).to eq 'gaëtan'
    end

    it 'should keep the case sensitivity in the highlight' do
      # Given
      record = { name: 'Tim' }
      options = { matches: { attribute: 'name', keyword: 'Tim' } }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual['t'][0][:highlights]['name'][:keyword]).to eq 'Tim'
      expect(actual['t'][0][:highlights]['name'][:highlight]).to eq 'T'
    end

    it 'should index without accented characters in the last name' do
      # Given
      record = { name: 'adam surák' }
      options = { matches: { attribute: 'name', keyword: 'adam surák' } }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual).to include 'adam surak'
      expect(actual).to include 'adam surák'
    end

    it 'should find names with multiples words with each of them' do
      # Given
      record = { name: 'jeremy ben sadoun' }
      options = { matches: { attribute: 'name', keyword: 'jeremy ben sadoun' } }

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
      record = { name: 'paul-louis nech' }
      options = { matches: { attribute: 'name', keyword: 'paul-louis nech' } }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual).to include 'paul'
      expect(actual).to include 'louis'
      expect(actual).to include 'nech'
      expect(actual['louis'][0][:highlights]['name'][:before]).to eq 'paul-'
      expect(actual['nech'][0][:highlights]['name'][:before]).to eq 'paul-louis '
    end

    it 'should find composed words when typing dash' do
      # Given
      record = { name: 'paul-louis nech' }
      options = { matches: { attribute: 'name', keyword: 'paul-louis nech' } }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual).to include 'paul-louis'
    end

    it 'should find composed words when typing space' do
      # Given
      record = { name: 'paul-louis' }
      options = { matches: { attribute: 'name', keyword: 'paul-louis' } }

      # When
      actual = QueryParser.index(record, options)

      # Then
      expect(actual).to include 'paul louis'
      expect(actual['paul louis'][0][:highlights]['name'][:keyword]).to eq 'paul-louis'
    end
  end

  describe 'merge' do
    it 'should merge several EntryTables' do
      # Given
      record_1 = { name: 'tim' }
      record_2 = { name: 'josh' }
      options_1 = { matches: [{ attribute: 'name', keyword: 'tim' }] }
      options_2 = { matches: [{ attribute: 'name', keyword: 'josh' }] }
      entry_table_1 = QueryParser.index(record_1, options_1)
      entry_table_2 = QueryParser.index(record_2, options_2)

      # When
      actual = QueryParser.merge(entry_table_1, entry_table_2)

      # Then
      expect(actual).to include 't'
      expect(actual).to include 'ti'
      expect(actual).to include 'tim'
      expect(actual).to include 'j'
      expect(actual).to include 'jo'
      expect(actual).to include 'jos'
      expect(actual).to include 'josh'
    end

    it 'should group EntryTables sharing the same prefix' do
      # Given
      record_1 = { name: 'tim' }
      record_2 = { name: 'tom' }
      options_1 = { matches: [{ attribute: 'name', keyword: 'tim' }] }
      options_2 = { matches: [{ attribute: 'name', keyword: 'tom' }] }
      entry_table_1 = QueryParser.index(record_1, options_1)
      entry_table_2 = QueryParser.index(record_2, options_2)

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
      record_1 = { 'objectID' => 0, name: 'tim' }
      record_2 = { 'objectID' => 0, name: 'tom' }
      options_1 = { matches: [{ attribute: 'name', keyword: 'tim' }] }
      options_2 = { matches: [{ attribute: 'name', keyword: 'tom' }] }
      entry_table_1 = QueryParser.index(record_1, options_1)
      entry_table_2 = QueryParser.index(record_2, options_2)
      lookup_table = QueryParser.merge(entry_table_1, entry_table_2)

      # When
      actual = QueryParser.uniq(lookup_table)

      # Then
      expect(actual['t'].length).to eq 1
    end

    it 'should make sure normalized and non-normalized version have the same results' do
      # Given
      record_1 = { 'objectID' => 0, name: 'clement' }
      record_2 = { 'objectID' => 1, name: 'clément' }
      options_1 = { matches: [{ attribute: 'name', keyword: 'clement' }] }
      options_2 = { matches: [{ attribute: 'name', keyword: 'clément' }] }
      entry_table_1 = QueryParser.index(record_1, options_1)
      entry_table_2 = QueryParser.index(record_2, options_2)
      lookup_table = QueryParser.merge(entry_table_1, entry_table_2)

      # When
      actual = QueryParser.uniq(lookup_table)

      # Then
      expect(actual['clement'].length).to eq 2
      expect(actual['clément'].length).to eq 2
    end
  end

  describe 'score_attribute' do
    it 'should give a score of zero if no highlight found' do
      # Given
      highlights = {}
      attributes = %w(name role)

      # When
      actual = QueryParser.score_attributes(highlights, attributes)

      # Then
      expect(actual).to eq 0
    end

    it 'should give a score of one if found in the only attribute' do
      # Given
      highlights = {
        'name' => {}
      }
      attributes = %w(name)

      # When
      actual = QueryParser.score_attributes(highlights, attributes)

      # Then
      expect(actual).to eq 1
    end

    it 'should give a max score if found in the top attribute' do
      # Given
      highlights = {
        'name' => {}
      }
      attributes = %w(name role)

      # When
      actual = QueryParser.score_attributes(highlights, attributes)

      # Then
      expect(actual).to eq 2
    end
  end

  describe 'score_position' do
    it 'should return 1 if the match is at the start' do
      # Given
      highlight = {
        before: nil,
        highlight: 'ca',
        after: 'rry'
      }

      # When
      actual = QueryParser.score_position(highlight)

      # Then
      expect(actual).to eq 1
    end

    it 'should return the index of the matched word' do
      # Given
      highlight = {
        before: 'jeremy ben ',
        highlight: 'sa',
        after: 'doun'
      }

      # When
      actual = QueryParser.score_position(highlight)

      # Then
      expect(actual).to eq 3
    end

    it 'should return 0 if there is not highlight (empty query)' do
      # Given
      highlight = {
        before: 'jeremy ben sadoun',
        highlight: nil,
        after: nil
      }

      # When
      actual = QueryParser.score_position(highlight)

      # Then
      expect(actual).to eq 0
    end
  end

  describe 'sort' do
    it 'should return hits found in first searchable attribute before found in second' do
      # Given
      record_1 = { name: 'neil', role: 'marketing' }
      record_2 = { name: 'marie', role: 'dev' }
      options_1 = { matches: [
        { attribute: 'name', keyword: 'neil' },
        { attribute: 'role', keyword: 'marketing' }
      ] }
      options_2 = { matches: [
        { attribute: 'name', keyword: 'marie' },
        { attribute: 'role', keyword: 'dev' }
      ] }
      entry_table_1 = QueryParser.index(record_1, options_1)
      entry_table_2 = QueryParser.index(record_2, options_2)
      lookup_table = QueryParser.merge(entry_table_1, entry_table_2)

      # When
      ranking = {
        searchable_attributes: %w(name role)
      }
      actual = QueryParser.sort(lookup_table, ranking)

      # Then
      expect(actual['mar'][0][:record][:name]).to eq 'marie'
      expect(actual['mar'][1][:record][:name]).to eq 'neil'
    end

    it 'should find in last name before in role' do
      # Given
      record_1 = { name: 'Nicolas Dessaigne', role: 'Co-founder & CEO' }
      record_2 = { name: 'Lucas Cerdan', role: 'Product UX Specialist' }
      options_1 = { matches: [
        { attribute: 'name', keyword: 'Nicolas Dessaigne' },
        { attribute: 'role', keyword: 'Co-founder & CEO' }
      ] }
      options_2 = { matches: [
        { attribute: 'name', keyword: 'Lucas Cerdan' },
        { attribute: 'role', keyword: 'Product UX Specialist' }
      ] }
      entry_table_1 = QueryParser.index(record_1, options_1)
      entry_table_2 = QueryParser.index(record_2, options_2)
      lookup_table = QueryParser.merge(entry_table_1, entry_table_2)

      # When
      ranking = {
        searchable_attributes: %w(name role)
      }
      actual = QueryParser.sort(lookup_table, ranking)

      # Then
      expect(actual['ce'][0][:record][:name]).to eq 'Lucas Cerdan'
      expect(actual['ce'][1][:record][:name]).to eq 'Nicolas Dessaigne'
    end

    it 'should return hits found at start of attribute before found at end of attributes' do
      # Given
      record_1 = { name: 'alexandre collin' }
      record_2 = { name: 'cory dobson' }
      options_1 = { matches: [{ attribute: 'name', keyword: 'alexandre collin' }] }
      options_2 = { matches: [{ attribute: 'name', keyword: 'cory dobson' }] }
      entry_table_1 = QueryParser.index(record_1, options_1)
      entry_table_2 = QueryParser.index(record_2, options_2)
      lookup_table = QueryParser.merge(entry_table_1, entry_table_2)

      # When
      ranking = {
        searchable_attributes: %w(name)
      }
      actual = QueryParser.sort(lookup_table, ranking)

      # Then
      expect(actual['co'][0][:record][:name]).to eq 'cory dobson'
      expect(actual['co'][1][:record][:name]).to eq 'alexandre collin'
    end

    it 'should return match in word 2 before match in word 3' do
      # Given
      record_1 = { 'name' => 'jeremy ben sadoun' }
      record_2 = { 'name' => 'martin sallé' }
      options_1 = { matches: [{ attribute: 'name', keyword: 'jeremy ben sadoun' }] }
      options_2 = { matches: [{ attribute: 'name', keyword: 'martin sallé' }] }
      entry_table_1 = QueryParser.index(record_1, options_1)
      entry_table_2 = QueryParser.index(record_2, options_2)
      lookup_table = QueryParser.merge(entry_table_1, entry_table_2)

      # When
      ranking = {
        searchable_attributes: %w(name)
      }
      actual = QueryParser.sort(lookup_table, ranking)

      # Then
      expect(actual['sa'][0][:record]['name']).to eq 'martin sallé'
      expect(actual['sa'][1][:record]['name']).to eq 'jeremy ben sadoun'
    end

    it 'should return hits found with a higher custom ranking first' do
      # Given
      record_1 = { 'name' => 'nicolas baissas', 'order' => 12 }
      record_2 = { 'name' => 'nicolas dessaigne', 'order' => 1 }
      options_1 = { matches: [{ attribute: 'name', keyword: 'nicolas baissas' }] }
      options_2 = { matches: [{ attribute: 'name', keyword: 'nicolas dessaigne' }] }
      entry_table_1 = QueryParser.index(record_1, options_1)
      entry_table_2 = QueryParser.index(record_2, options_2)
      lookup_table = QueryParser.merge(entry_table_1, entry_table_2)

      # When
      ranking = {
        searchable_attributes: %w(name),
        custom_ranking: 'order'
      }
      actual = QueryParser.sort(lookup_table, ranking)

      # Then
      expect(actual['nicolas'][0][:record]['name']).to eq 'nicolas dessaigne'
      expect(actual['nicolas'][1][:record]['name']).to eq 'nicolas baissas'
    end

    it 'should correctly sort by order even with composed names' do
      # Given
      records = [
        { 'name' => 'jeremy ben sadoun', 'order' => 6 },
        { 'name' => 'julien paroche', 'order' => 50 }
      ]
      lookup_table = QueryParser.empty_query(records, 'name')

      # When
      ranking = {
        searchable_attributes: %w(name),
        custom_ranking: 'order'
      }
      actual = QueryParser.sort(lookup_table, ranking)

      # Then
      expect(actual['__EMPTY_QUERY__'][0][:record]['name']).to eq 'jeremy ben sadoun'
      expect(actual['__EMPTY_QUERY__'][1][:record]['name']).to eq 'julien paroche'
    end
  end

  describe 'add_synonyms' do
    it 'should add an entry for the synonym' do
      # Given
      records = [
        { 'name' => 'Rémy-Christophe Schermesser' }
      ]
      synonyms = [
        {
          'attribute' => 'name',
          'original' => 'Rémy-Christophe Schermesser',
          'replace' => 'RCS'
        }
      ]

      # When
      actual = QueryParser.add_synonyms({}, records, synonyms)

      # Then
      expect(actual).to include 'rcs'
    end

    it 'should not add entries for non-existent words' do
      # Given
      records = [
        { 'name' => 'Paul-Louis Nech' }
      ]
      synonyms = [
        {
          'attribute' => 'name',
          'original' => 'Rémy-Christophe Schermesser',
          'replace' => 'RCS'
        }
      ]

      # When
      actual = QueryParser.add_synonyms({}, records, synonyms)

      # Then
      expect(actual).to_not include 'RCS'
    end

    it 'should highlight part of the synonym' do
      # Given
      records = [
        { 'name' => 'Matthieu Dumont' },
        { 'role' => 'Customer Success Engineer' }
      ]
      synonyms = [
        {
          'attribute' => 'name',
          'original' => 'Matthieu Dumont',
          'replace' => 'Jerska'
        },
        {
          'attribute' => 'role',
          'original' => 'Customer Success Engineer',
          'replace' => 'CSE'
        }
      ]

      # When
      actual = QueryParser.add_synonyms({}, records, synonyms)

      # Then
      expect(actual['jer'][0][:highlights]['name'][:highlight]).to eq 'Jer'
      expect(actual['jer'][0][:highlights]['name'][:after]).to eq 'ska'
      expect(actual['cs'][0][:highlights]['role'][:highlight]).to eq 'CS'
      expect(actual['cs'][0][:highlights]['role'][:after]).to eq 'E'
    end
  end

  describe 'empty_query' do
    it 'should create entries for each record, with an highlight entry' do
      # Given
      inputs = [
        { 'name' => 'foo' },
        { 'name' => 'bar' },
        { 'name' => 'baz' }
      ]

      # When
      actual = QueryParser.empty_query(inputs, ['name'])

      # Then
      expect(actual).to include '__EMPTY_QUERY__'
      expect(actual['__EMPTY_QUERY__'].length).to eq 3
      expect(actual['__EMPTY_QUERY__'][0][:highlights]).to include 'name'
    end

    it 'should allow to pass only one searchable attribute' do
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
      expect(actual['__EMPTY_QUERY__'][0][:highlights]).to include 'name'
    end

    it 'should create a highlight group for each searchable attribute specified' do
      # Given
      inputs = [
        { 'name' => 'foo', 'role' => 'bar' },
        { 'name' => 'bar', 'role' => 'baz' }
      ]

      # When
      actual = QueryParser.empty_query(inputs, %w(name role))

      # Then
      expect(actual).to include '__EMPTY_QUERY__'
      expect(actual['__EMPTY_QUERY__'].length).to eq 2
      expect(actual['__EMPTY_QUERY__'][0][:highlights]).to include 'name'
      expect(actual['__EMPTY_QUERY__'][0][:highlights]).to include 'role'
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

    it 'should contain non-highlighted highlight' do
      # Given
      inputs = [
        { 'name' => 'foo' },
        { 'name' => 'bar' },
        { 'name' => 'baz' }
      ]

      # When
      actual = QueryParser.empty_query(inputs, 'name')

      # Then
      expect(actual['__EMPTY_QUERY__'][0][:highlights]['name'][:before]).to eq 'foo'
      expect(actual['__EMPTY_QUERY__'][0][:highlights]['name'][:highlight]).to eq nil
      expect(actual['__EMPTY_QUERY__'][0][:highlights]['name'][:after]).to eq nil
    end
  end

  describe 'add_typos' do
    it 'should add typos for one missing letter (except first and last)' do
      # Given
      record = { 'name' => 'Dustin' }
      options = { matches: [{ attribute: 'name', keyword: 'Dustin' }] }
      entry_table = QueryParser.index(record, options)
      lookup_table = QueryParser.sort(entry_table)

      # When
      actual = QueryParser.add_typos(lookup_table)

      # Then
      expect(actual).to include 'dustin'
      expect(actual).to include 'dut'
      expect(actual).to include 'dusi'
      expect(actual).to include 'dustn'
      expect(actual).to include 'dutin'
    end

    it 'should not generate typos for the empty query' do
      # Given
      inputs = [
        { 'name' => 'foo' },
        { 'name' => 'bar' },
        { 'name' => 'baz' }
      ]
      lookup_table = QueryParser.empty_query(inputs, ['name'])

      # When
      actual = QueryParser.add_typos(lookup_table)

      # Then
      expect(actual).to_not include '__EMTY_QUERY__'
    end
  end

  describe 'generate_facets' do
    it 'should generate a list of facets for each entry' do
      # Given
      record_1 = { 'name' => 'Alex C.', 'team' => 'SE' }
      record_2 = { 'name' => 'Alex M.', 'team' => 'Dev' }
      record_3 = { 'name' => 'Alex K.', 'team' => 'Sales' }
      record_4 = { 'name' => 'Alex S.', 'team' => 'Dev' }
      options_1 = { matches: [{ attribute: 'name', keyword: 'Alex C.' }] }
      options_2 = { matches: [{ attribute: 'name', keyword: 'Alex M.' }] }
      options_3 = { matches: [{ attribute: 'name', keyword: 'Alex K.' }] }
      options_4 = { matches: [{ attribute: 'name', keyword: 'Alex S.' }] }
      entry_table_1 = QueryParser.index(record_1, options_1)
      entry_table_2 = QueryParser.index(record_2, options_2)
      entry_table_3 = QueryParser.index(record_3, options_3)
      entry_table_4 = QueryParser.index(record_4, options_4)
      lookup_table = QueryParser.merge(entry_table_1,
                                       entry_table_2,
                                       entry_table_3,
                                       entry_table_4)

      # When
      actual = QueryParser.generate_facets(lookup_table, 'team')

      # Then
      expect(actual['alex'].length).to eq 3
    end

    it 'should order facets by count desc' do
      # Given
      record_1 = { 'name' => 'bat', 'team' => 'Dev' }
      record_2 = { 'name' => 'bar', 'team' => 'Dev' }
      record_3 = { 'name' => 'baz', 'team' => 'Sales' }
      options_1 = { matches: [{ attribute: 'name', keyword: 'bat' }] }
      options_2 = { matches: [{ attribute: 'name', keyword: 'bar' }] }
      options_3 = { matches: [{ attribute: 'name', keyword: 'baz' }] }
      entry_table_1 = QueryParser.index(record_1, options_1)
      entry_table_2 = QueryParser.index(record_2, options_2)
      entry_table_3 = QueryParser.index(record_3, options_3)
      lookup_table = QueryParser.merge(entry_table_1,
                                       entry_table_2,
                                       entry_table_3)

      # When
      actual = QueryParser.generate_facets(lookup_table, 'team')

      # Then
      expect(actual['ba'].length).to eq 2
      expect(actual['ba'][0][:name]).to eq 'Dev'
      expect(actual['ba'][0][:count]).to eq 2
      expect(actual['ba'][1][:name]).to eq 'Sales'
      expect(actual['ba'][1][:count]).to eq 1
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
