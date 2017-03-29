require 'spec_helper'

describe(CSSWriter) do
  describe 'highlight' do
    it 'should concatenate before and after' do
      # Given
      input = {
        before: 'nic',
        after: 'olas'
      }

      # When
      actual = CSSWriter.highlight(input)

      # Then
      expect(actual).to eq 'nicolas'
    end

    it 'should replace highlight wth private space unicode' do
      # Given
      input = {
        before: 'nic',
        highlight: 'foo',
        after: 'olas'
      }

      # When
      actual = CSSWriter.highlight(input)

      # Then
      expect(actual).to eq 'nic\\e666 \\e66f \\e66f olas'
    end

    it 'should not highlight spaces' do
      # Given
      input = {
        before: 'kung',
        highlight: 'foo',
        after: ' panda'
      }

      # When
      actual = CSSWriter.highlight(input)

      # Then
      expect(actual).to eq 'kung\\e666 \\e66f \\e66f  panda'
    end
  end
end
