require 'spec_helper'

describe(QueryParser) do
  describe 'record_to_struct' do
    it 'should return an object with keys for each keystroke' do
      # Given
      input = {
        keyword: 'tim',
        data: { foo: 'bar' }
      }

      # When
      actual = QueryParser.record_to_struct(input)

      # Then
      expect(actual).to include 't'
      expect(actual).to include 'ti'
      expect(actual).to include 'tim'
    end

    it 'should give an after and highlight for each prefixed word' do
      # Given
      input = {
        keyword: 'tim',
        data: { foo: 'bar' }
      }

      # When
      actual = QueryParser.record_to_struct(input)

      # Then
      expect(actual['t'][:highlight]).to eq 't'
      expect(actual['t'][:after]).to eq 'im'
      expect(actual['tim'][:highlight]).to eq 'tim'
      expect(actual['tim'][:after]).to eq ''
    end

    it 'should keep the associated raw data' do
      # Given
      data = { foo: 'bar' }
      input = {
        keyword: 'tim',
        data: data
      }

      # When
      actual = QueryParser.record_to_struct(input)

      # Then
      expect(actual['t'][:data]).to eq data
      expect(actual['ti'][:data]).to eq data
      expect(actual['tim'][:data]).to eq data
    end
  end

  describe 'words_to_struct' do
    it 'should return an object with keys for each keystroke' do
      # Given
      input = [
        { keyword: 'tim', data: { name: 'foo' } },
        { keyword: 'tom', data: { name: 'bar' } }
      ]

      # When
      actual = QueryParser.words_to_struct(input)

      # Then
      expect(actual).to include 't'
      expect(actual).to include 'ti'
      expect(actual).to include 'to'
      expect(actual).to include 'tim'
      expect(actual).to include 'tom'
    end

    it 'should keep the associated data with each entry' do
      # Given
      input = %w(tim tom)

      # When
      actual = QueryParser.words_to_struct(input)
      ap actual['t']

      # Then
      # expect(actual).to include 't'
      # expect(actual).to include 'ti'
      # expect(actual).to include 'to'
      # expect(actual).to include 'tim'
      # expect(actual).to include 'tom'
    end
  end
end
