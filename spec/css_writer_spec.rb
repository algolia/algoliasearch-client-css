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
