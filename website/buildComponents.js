const fs = require('fs');
const algoliaComponents = require('algolia-frontend-components');

const output = algoliaComponents.communityHeader({
  menu: {
    project: {
      label: "Algolia CSS API Client",
      url: "https://community.algolia.com/algoliasearch-client-css/"
    }
  },
  sideMenu: [
    { name: "Live demo", url: "./demo" },
    { name: "Blog", url: "https://blog.algolia.com/introducing-our-css-api-client", target: '_blank' },
    { name: "Community forum", url: "https://discourse.algolia.com", target: '_blank'},
    { image: '<img src="./images/github.svg" />', url: "https://github.com/algolia/algoliasearch-client-css", target: '_blank' }
  ],
  mobileMenu: [
    { name: "Live demo", url: "./demo" },
    { name: "Blog", url: "https://blog.algolia.com/introducing-our-css-api-client", target: '_blank' },
    { name: "Community forum", url: "https://discourse.algolia.com", target: '_blank' },
    { image: '<img src="./images/github.svg" />', url: "https://github.com/algolia/algoliasearch-client-css", target: '_blank' }
  ],
  docSearch: null
});

const file = fs.readFileSync('node_modules/algolia-frontend-components/dist/_communityHeader.js');

try {
  fs.writeFileSync('source/partials/common/_header.html', output, 'utf-8');
  fs.writeFileSync('source/javascripts/communityHeader.js', file, 'utf-8')
} catch (e) {
  throw new Error('Failed to write header file');
}
