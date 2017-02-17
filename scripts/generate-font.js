import Promise from 'bluebird';
import fs from 'fs';
import glob from 'glob';
import ttf2svg from 'ttf2svg';
import svg2ttf from 'svg2ttf';
import svg2font from 'svgicons2svgfont';
import fontBlast from 'font-blast';
import _ from 'lodash';
import basename from 'basename';
import mkdirp from 'mkdirp';

const GenerateFont = {
  parseArguments(args) {
    args = _.slice(args, 2);
    GenerateFont.boldFont = args[0];

    if (_.isEmpty(GenerateFont.boldFont)) {
      console.info('Usage:');
      console.info('yarn run generate-fonts ./path/to/bold/font.ttf');
      process.exit(1);
    }
  },

  ls(pattern) {
    return Promise.promisify(glob)(pattern);
  },

  readFile(path) {
    return Promise.promisify(fs.readFile)(path);
  },

  writeFile(path, content) {
    return Promise.promisify(fs.writeFile)(path, content);
  },

  mkdir(path) {
    return Promise.promisify(mkdirp)(path);
  },

  // Convert a ttf file to an svg one
  ttf2svg(filepath) {
    const output = `./tmp/${basename(filepath)}.svg`;

    if (fs.existsSync(output)) {
      return Promise.resolve(output);
    }

    return GenerateFont.readFile(filepath)
      .then(buffer => GenerateFont.writeFile(output, new Buffer(ttf2svg(buffer, {})).buffer))
      .then(() => { console.info('Converted to SVG'); })
      .then(() => output);
  },

  // Convert a svg font into a ttf one
  svg2ttf(filepath) {
    const output = filepath.replace('.svg', '.ttf');

    if (fs.existsSync(output)) {
      return Promise.resolve(output);
    }

    const svg = fs.readFileSync(filepath, 'utf-8');
    fs.writeFileSync(output, new Buffer(svg2ttf(svg).buffer));
    console.info('Converted to TTF');
    return Promise.resolve(output);
  },

  // Explode a font into a list of all its glyphs
  explodeGlyphs(font) {
    const output = `./tmp/${basename(font)}/`;
    if (fs.existsSync(output)) {
      return Promise.resolve(output);
    }
    return GenerateFont.mkdir(output)
      .then(() => {
        fontBlast(font, output);
        console.info(`Extracted glyphs in ${output}`);
        return output;
      });
  },

  // Gets all characters that could be used for highlighting
  getAllNeededCharacters() {
    return GenerateFont.readFile('./data/members.json')
      .then(content => JSON.parse(content))
      .then(members => {
        const namesAggregate = _.reduce(members, (aggregate, member) => `${aggregate}${member.name}`, '');
        const uniqueChars = _.uniq(namesAggregate.split('').sort()).join('');
        return uniqueChars;
      })
      .then(chars => {
        console.info(`Needed characters: ${chars}`);
        return chars;
      });
  },

  createHighlightFont(fontPath) {
    return Promise.all([
      GenerateFont.ttf2svg(fontPath)
        .then(boldFontSVG => GenerateFont.explodeGlyphs(boldFontSVG)),
      GenerateFont.getAllNeededCharacters(),
    ]).then(results => {
      const boldGlyphsDirectory = results[0];
      const characters = results[1];

      const outputPath = './public/fonts/Highlight.svg';
      const deferred = Promise.pending();
      const fontStream = svg2font({
        fontName: 'Highlight',
        descent: -450
      });
      fontStream.pipe(fs.createWriteStream(outputPath))
                .on('finish', () => { deferred.resolve(outputPath); })
                .on('error', err => { deferred.reject(err); });

      const privateSpaceStart = 58880; // \e6XX private space
      _.each(characters, char => {
        const baseCodePoint = char.charCodeAt(0);
        const baseUnicodeCodePoint = baseCodePoint.toString(16);
        const glyphPath = `${boldGlyphsDirectory}svg/uni${baseUnicodeCodePoint}.svg`;

        if (!fs.existsSync(glyphPath)) {
          console.info(`⚠ No glyph for ${char} (${glyphPath})`);
          return;
        }

        const privateCodePoint = baseCodePoint + privateSpaceStart;
        const privateUnicodeCharacter = String.fromCodePoint(privateCodePoint);

        const glyphStream = fs.createReadStream(glyphPath);
        const glyphName = `HIGHLIGHT_${char}`;

        glyphStream.metadata = {
          name: glyphName,
          unicode: [privateUnicodeCharacter],
        };

        fontStream.write(glyphStream);
      });
      fontStream.end();

      return deferred.promise;
    })
    .then(fontPathSVG => {
      console.info(`Created new Highlight font ${fontPathSVG}`);
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

    GenerateFont.createHighlightFont(GenerateFont.boldFont);
  },
};
GenerateFont.run(process.argv);
