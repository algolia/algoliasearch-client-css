require 'awesome_print'

# Writes CSS rules that match a given LookupTable
class CSSWriter
  # Given a prefix and an entry, should return the matching CSS rule
  def self.rule(keyword, entries)
    css = []
    keyword = '' if keyword == '__EMPTY_QUERY__'

    entries.each_with_index do |entry, i|
      h = entry[:highlight]
      content = "#{h[:before]}#{highlight(h[:highlight])}#{h[:after]}"
      quote = "#{entry[:record]['emoji']}\\A #{entry[:record]['funny_quote']}".gsub("'", '\\\0027 ')

      div_selector = " + div > div:nth-child(#{i + 1})"

      css << "input[value='#{keyword}' i]#{div_selector} {"
      css << "background-image: url(#{entry[:record]['image']});"
      css << 'display: block;'
      css << '}'
      css << "input[value='#{keyword}' i]#{div_selector}:before {"
      css << "content: '#{content}\\A #{entry[:record]['role']}'"
      css << '}'
      css << "input[value='#{keyword}' i]#{div_selector}:after {"
      css << "content: '#{quote}'"
      css << '}'
    end

    css.join("\n")
  end

  # Highlighting is done using characters in the private area of Unicode
  def self.highlight(text)
    return '' if text.nil?

    highlighted_text = ''
    text.split('').each do |char|
      char_code = char.ord
      # There is no char for a space, so we keep it that way
      if char_code == 32
        highlighted_text += ' '
        next
      end
      private_char_code = char_code + 58_880
      css_char = private_char_code.to_s(16)

      highlighted_text += '\\' + css_char + ' '
    end
    highlighted_text
  end

  # Base CSS to be added to the search
  def self.base
    []
  end

  # Get the Cloudinary link to an image
  def self.cloudinary(url)
    'https://res.cloudinary.com/pixelastic-parisweb/image/fetch/' \
    "w_220,h_220,q_90,c_scale,r_max,f_auto,e_grayscale/#{url}"
  end

  # Preload all images by loading the images in the body background
  def self.preload_images(css, records)
    preloaded_images = []
    records.each do |record|
      preloaded_images.push("url(#{record['image']})")
    end
    css.push('body:before{content:""; display:none; '\
           "background:#{preloaded_images.join(',')}}")
    css
  end

  # Apply rules to display
end
