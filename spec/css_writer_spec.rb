require 'spec_helper'

describe(CSSWriter) do
  let(:tim) {
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
  }

  describe 'rule' do
    it 'should have a rule for the exact word' do
      # Given
      keyword = 'tim'
      entry = tim

      # When
      actual = CSSWriter.rule(keyword, entry)

      # Then
      expect(actual).to include "[value='tim'"
    end

    it 'should match in case-insensitive fashion' do
      # Given
      keyword = 'tim'
      entry = tim

      # When
      actual = CSSWriter.rule(keyword, entry)

      # Then
      expect(actual).to include "[value='tim' i]"
    end

    it 'should have the image as background' do
      # Given
      keyword = 'tim'
      entry = tim

      # When
      actual = CSSWriter.rule(keyword, entry)

      # Then
      expect(actual).to include 'background-image: url(foo)'
    end
  end
end
