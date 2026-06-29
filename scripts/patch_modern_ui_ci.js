const fs = require('fs');
const path = require('path');

const INDEX_FILE = path.resolve(__dirname, '../entry/src/main/ets/pages/Index.ets');

function replaceAll(content, from, to, label) {
  if (!content.includes(from)) {
    console.warn('ComicReader modern UI fix skipped missing marker: ' + label);
    return content;
  }
  return content.split(from).join(to);
}

function patchModernUiFixes() {
  if (!fs.existsSync(INDEX_FILE)) {
    console.warn('ComicReader modern UI fix skipped; Index.ets not found.');
    return;
  }

  let content = fs.readFileSync(INDEX_FILE, 'utf8');

  content = replaceAll(
    content,
    `          this.ReaderFloatingButton('‹')
            .onClick(() => { this.mode = this.chapters.length > 0 ? 'chapters' : (this.results.length > 0 ? 'results' : 'home'); })`,
    `          Column() { this.ReaderFloatingButton('‹') }
            .onClick(() => { this.mode = this.chapters.length > 0 ? 'chapters' : (this.results.length > 0 ? 'results' : 'home'); })`,
    'reader back floating button wrapper'
  );

  content = replaceAll(
    content,
    `          this.ReaderFloatingButton('＋')
            .onClick(() => this.addCurrentToShelf())`,
    `          Column() { this.ReaderFloatingButton('＋') }
            .onClick(() => this.addCurrentToShelf())`,
    'reader shelf floating button wrapper'
  );

  content = replaceAll(
    content,
    `          this.ReaderFloatingButton('↻')
            .margin({ left: 10 })
            .onClick(() => this.loadChapterByUrl(this.currentUrl, this.currentChapterTitle, this.findRule(this.currentSourceId)))`,
    `          Column() { this.ReaderFloatingButton('↻') }
            .margin({ left: 10 })
            .onClick(() => this.loadChapterByUrl(this.currentUrl, this.currentChapterTitle, this.findRule(this.currentSourceId)))`,
    'reader reload floating button wrapper'
  );

  fs.writeFileSync(INDEX_FILE, content);
  console.log('ComicReader CI applied modern UI compatibility fixes.');
}

patchModernUiFixes();

module.exports = { patchModernUiFixes };
