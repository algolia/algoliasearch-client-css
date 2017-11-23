import Promise from 'bluebird';
import fs from 'fs';
import path from 'path';
import glob from 'glob';
import ttf2svg from 'ttf2svg';
import svg2ttf from 'svg2ttf';
import svg2font from 'svgicons2svgfont';
import fontBlast from 'font-blast';
import _ from 'lodash';
import basename from 'basename';
import mkdirp from 'mkdirp';

function debug(message) {
  return function (arg) {
    console.info(message);
    return arg;
  };
}

const GenerateFont = {
  parseArguments(args) {
    args = _.slice(args, 2);
    GenerateFont.baseFont = args[0];
    GenerateFont.boldFont = args[1];

    if (_.isEmpty(GenerateFont.baseFont) || _.isEmpty(GenerateFont.boldFont)) {
      console.info('Usage:');
      console.info('yarn run generate-fonts ./path/to/base/font.ttf ./path/to/bold/font.ttf');
      process.exit(1);
    }
  },

  ls(pattern) {
    return Promise.promisify(glob)(pattern);
  },

  readFile(filepath) {
    return Promise.promisify(fs.readFile)(filepath);
  },

  writeFile(filepath, content) {
    return GenerateFont.mkdir(path.dirname(filepath))
      .then(() => Promise.promisify(fs.writeFile)(filepath, content));
  },

  mkdir(filepath) {
    return Promise.promisify(mkdirp)(filepath);
  },

  // Convert a ttf file to an svg one
  ttf2svg(filepath) {
    const output = `./demo/tmp/${basename(filepath)}.svg`;

    return GenerateFont.readFile(filepath)
      .then(buffer => GenerateFont.writeFile(output, ttf2svg(buffer)))
      .then(() => output);
  },

  // Convert a svg font into a ttf one
  svg2ttf(filepath) {
    const output = filepath.replace('.svg', '.ttf');

    const svg = fs.readFileSync(filepath, 'utf-8');
    fs.writeFileSync(output, new Buffer(svg2ttf(svg).buffer));
    return Promise.resolve(output);
  },

  // Explode a font into a list of all its glyphs
  explodeGlyphs(font) {
    const output = `./demo/tmp/${basename(font)}/`;
    if (fs.existsSync(output)) {
      return Promise.resolve(output);
    }
    return GenerateFont.mkdir(output)
      .then(() => {
        fontBlast(font, output);
        return output;
      });
  },

  // Gets all characters that could be used for highlighting
  getAllNeededCharacters() {
    return GenerateFont.readFile('./demo/data/members.json')
      .then(content => JSON.parse(content))
      .then(members => {
        const highlightAggregate = _.reduce(members, (aggregate, member) => `${aggregate}${member.name}${member.role}`, '');
        const uniqueChars = _.uniq(highlightAggregate.split('').sort()).join('');
        return uniqueChars;
      })
      .then(chars => {
        console.info(`Needed characters: ${chars}`);
        return chars;
      });
  },

  createHighlightFont(baseFont, boldFont) {
    return Promise.all([
      GenerateFont.ttf2svg(baseFont)
        .then(baseFontSVG => GenerateFont.explodeGlyphs(baseFontSVG))
        .then(debug(`Converted ${baseFont} to SVG and extracted files`)),
      GenerateFont.ttf2svg(boldFont)
        .then(boldFontSVG => GenerateFont.explodeGlyphs(boldFontSVG))
        .then(debug(`Converted ${boldFont} to SVG and extracted files`)),
      GenerateFont.getAllNeededCharacters(),
    ]).then(results => {
      const baseGlyphsDirectory = results[0];
      const boldGlyphsDirectory = results[1];
      const characters = results[2];

      const outputPath = './demo/public/fonts/Raleway.svg';
      const deferred = Promise.pending();
      const fontStream = svg2font({
        fontName: 'Raleway',
        normalize: true,
      });
      fontStream.pipe(fs.createWriteStream(outputPath))
                .on('finish', () => { deferred.resolve(outputPath); })
                .on('error', err => { deferred.reject(err); });

      const privateSpaceStart = 58880; // \e6XX private space
      _.each(characters, char => {
        const baseCodePoint = char.charCodeAt(0);
        const baseUnicodeCodePoint = baseCodePoint.toString(16);
        const baseGlyphPath = `${baseGlyphsDirectory}svg/uni${baseUnicodeCodePoint}.svg`;
        if (!fs.existsSync(baseGlyphPath)) {
          console.info(`⚠ No glyph for ${char} (${baseGlyphPath})`);
          return;
        }

        // Adding the regular character
        const baseGlyphStream = fs.createReadStream(baseGlyphPath);
        const baseGlyphName = `BASE_${char}`;

        baseGlyphStream.metadata = {
          name: baseGlyphName,
          unicode: [char],
        };
        fontStream.write(baseGlyphStream);

        // Adding the highlighted characters
        const boldGlyphPath = `${boldGlyphsDirectory}svg/uni${baseUnicodeCodePoint}.svg`;
        if (!fs.existsSync(boldGlyphPath)) {
          console.info(`⚠ No glyph for ${char} (${boldGlyphPath})`);
          return;
        }

        const privateCodePoint = baseCodePoint + privateSpaceStart;
        const privateUnicodeCharacter = String.fromCodePoint(privateCodePoint);

        const privateGlyphStream = fs.createReadStream(boldGlyphPath);
        const privateGlyphName = `HIGHLIGHT_${char}`;

        privateGlyphStream.metadata = {
          name: privateGlyphName,
          unicode: [privateUnicodeCharacter],
        };
        fontStream.write(privateGlyphStream);
      });

      fontStream.end();

      return deferred.promise;
    })
    .then(fontPathSVG => {
      console.info(`Created new Raleway font ${fontPathSVG}`);
      return fontPathSVG;
    })
    // Convert to ttf
    .then(fontPathSVG => GenerateFont.svg2ttf(fontPathSVG))
    .then(fontPathTTF => {
      console.info(`Converted font to ${fontPathTTF}`);
      return fontPathTTF;
    });
  },

  run(args) {
    GenerateFont.parseArguments(args);

    GenerateFont.createHighlightFont(GenerateFont.baseFont, GenerateFont.boldFont);
  },
};
GenerateFont.run(process.argv);
