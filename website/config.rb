###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

# With alternative layout
# page "/path/to/file.html", layout: :otherlayout

# Proxy pages (http://middlemanapp.com/basics/dynamic-pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", locals: {
#  which_fake_page: "Rendering a fake page with a local variable" }

# General configuration

# Reload the browser automatically whenever files change
configure :development do
  activate :livereload
end

###
# Helpers
###



# Methods defined in the helpers block are available in templates
helpers do
  def inline_svg(path, className = '')
    dir = 'source/images'
    full_path = "#{root}/#{dir}/#{path}"
    raise "Could not find SVG file @ #{full_path}" unless File.exist?(full_path)
    "<span class=#{className}>#{IO.read(full_path)}</span>".html_safe
  end
end

# Build-specific configuration
configure :build do
  activate :relative_assets
  # Minify CSS on build
  # activate :minify_css

  # Minify Javascript on build
  # activate :minify_javascript
end
