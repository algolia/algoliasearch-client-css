import CleanCSS from 'clean-css';
import _ from 'lodash';
import Promise from 'bluebird';
import fs from 'fs';

const Minify = {
  writeFile(path, content) {
    return Promise.promisify(fs.writeFile)(path, content);
  },

  restructureRules(input) {
    console.info('Restructure rules');
    const options = {
      level: {
        1: true,
        2: {
          all: false,
          removeEmpty: true,
          restructureRules: true,
        },
      },
    };
    const instance = new CleanCSS(options);
    // clean-css 4.0.10 does not allow updating it from the options directly
    instance.options.compatibility.selectors.mergeLimit = 1000;
    return instance.minify(input).styles;
  },

  mergeNonAdjacent(input) {
    console.info('Merge non-adjacent rules');
    const options = {
      level: {
        2: {
          all: false,
          mergeNonAdjacentRules: true,
        },
      },
    };
    const instance = new CleanCSS(options);
    return instance.minify(input).styles;
  },

  format(input) {
    console.info('Format output');
    const options = {
      format: {
        breaks: {
          betweenSelectors: true,
          afterRuleEnds: true,
        },
      },
    };
    const instance = new CleanCSS(options);
    return instance.minify(input).styles;
  },

  run(args) {
    args = _.slice(args, 2);
    const inputFile = args[0] || './public/css/search.css';
    const outputFile = args[1] || './public/css/search.min.css';

    const input = fs.readFileSync(inputFile, 'utf-8');
    console.info('Minifying... this can take up to one minute');

    let minified = Minify.restructureRules(input);
    // minified = Minify.mergeNonAdjacent(minified);
    // minified = Minify.format(minified);
    console.info('Write output to file');
    Minify.writeFile(outputFile, minified);
  },
};
Minify.run(process.argv);
