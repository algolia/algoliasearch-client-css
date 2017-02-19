require 'spec_helper'

describe(CSSWriter) do
  let(:tim) do
    [{
      highlight: {
        after: '',
        before: 'Tim ',
        highlight: 'Carry',
        keyword: 'Carry'
      },
      record: {
        'image' => 'foo'
      }
    }]
  end
  let(:pln) do
    [{
      highlight: {
        after: '',
        before: 'Paul-Louis ',
        highlight: 'Nech',
        keyword: 'Nech'
      },
      record: {
        'image' => 'bar'
      }
    }]
  end
  let(:multiple) { [tim[0], pln[0]] }

  describe 'rule' do
    it 'should have a rule for the exact word' do
      # Given
      keyword = 'foo'
      entry = tim

      # When
      actual = CSSWriter.rule(keyword, entry)

      # Then
      expect(actual).to include "[value='foo'"
    end

    it 'should match in case-insensitive fashion' do
      # Given
      keyword = 'foo'
      entry = tim

      # When
      actual = CSSWriter.rule(keyword, entry)

      # Then
      expect(actual).to include "[value='foo' i]"
    end

    it 'should have the image as background' do
      # Given
      keyword = 'foo'
      entry = tim

      # When
      actual = CSSWriter.rule(keyword, entry)

      # Then
      expect(actual).to include 'background-image: url(foo)'
    end

    it 'should define multiple rules for multiple entries' do
      # Given
      keyword = 'foo'
      entries = multiple

      # When
      actual = CSSWriter.rule(keyword, entries)

      # Then
      expect(actual).to include "input[value='foo' i] + div {"
      expect(actual).to include "input[value='foo' i] + div + div {"
    end
  end
end
