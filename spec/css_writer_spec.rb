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
      expect(actual).to include "input[value='foo' i] + div > div:nth-child(1) {"
      expect(actual).to include "input[value='foo' i] + div > div:nth-child(2) {"
    end

    it 'should handle the empty query special case' do
      # Given
      keyword = '__EMPTY_QUERY__'
      entries = tim

      # When
      actual = CSSWriter.rule(keyword, entries)

      # Then
      expect(actual).to include "input[value='' i] + div > div:nth-child(1) {"
    end
  end

  describe 'highlight' do
    it 'should change nothing if no highlight' do
      # Given
      input = ''

      # When
      actual = CSSWriter.highlight(input)

      # Then
      expect(actual).to eq ''
    end

    it 'should replace highlighted characters with private space unicode' do
      # Given
      input = 'foo'

      # When
      actual = CSSWriter.highlight(input)

      # Then
      expect(actual).to eq '\\e666 \\e66f \\e66f '
    end

    it 'should not highlight spaces' do
      # Given
      input = 'a b'

      # When
      actual = CSSWriter.highlight(input)

      # Then
      expect(actual).to eq '\\e661  \\e662 '
    end

    it 'should not highlight if nil' do
      # Given
      input = nil

      # When
      actual = CSSWriter.highlight(input)

      # Then
      expect(actual).to eq ''
    end
  end
end
