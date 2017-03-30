const fs = require('fs');
const algoliaComponents = require('algolia-frontend-components');

const output = algoliaComponents.communityHeader({
  menu: {
    project: {
      label: "Algolia CSS Client",
      url: "https://community.algolia.com/magento/"
    }
  },
  sideMenu: [
    { name: "Blog", url: "" },
    { name: "Discourse", url: "" }
  ],
  mobileMenu: [
    { name: "Blog", url: "" },
    { name: "Discourse", url: "" }
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