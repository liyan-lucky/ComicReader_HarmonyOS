const fs = require('fs');
const path = require('path');

const INDEX_FILE = path.resolve(__dirname, '../entry/src/main/ets/pages/Index.ets');

function replaceOnce(content, from, to, label) {
  if (!content.includes(from)) {
    console.warn('ComicReader about patch skipped missing marker: ' + label);
    return content;
  }
  return content.replace(from, to);
}

function patchAboutPage() {
  if (!fs.existsSync(INDEX_FILE)) {
    console.warn('ComicReader about patch skipped; Index.ets not found.');
    return;
  }

  let content = fs.readFileSync(INDEX_FILE, 'utf8');

  if (!content.includes('../common/BuildInfo')) {
    content = replaceOnce(
      content,
      "import { RemoteRuleService, DEFAULT_REMOTE_RULE_URL } from '../common/RemoteRuleService';\n",
      "import { RemoteRuleService, DEFAULT_REMOTE_RULE_URL } from '../common/RemoteRuleService';\n" +
        "import { APP_VERSION, APP_VERSION_CODE, APP_BUILD_TYPE, APP_BUILD_TIME, APP_BUILD_TARGET } from '../common/BuildInfo';\n",
      'BuildInfo import'
    );
  }

  if (!content.includes('private AboutInfoRow(')) {
    const aboutBuilder = `
  @Builder
  private AboutInfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(13)
        .fontColor('#666666')
        .layoutWeight(1)
      Text(value)
        .fontSize(13)
        .fontColor('#222222')
        .textAlign(TextAlign.End)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(2)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  private AboutPage() {
    Scroll() {
      Column() {
        Text('关于')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ top: 12, bottom: 6 })
        Text('漫画浏览器 HarmonyOS / OpenHarmony 公开漫画搜索与卷轴阅读项目。')
          .fontSize(13)
          .fontColor('#666666')
          .lineHeight(20)
          .width('100%')
          .margin({ bottom: 12 })

        Column() {
          Text('构建信息')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })
          this.AboutInfoRow('版本', APP_VERSION)
          this.AboutInfoRow('版本结构', '主版本.全量构建号.增量构建号')
          this.AboutInfoRow('versionCode', APP_VERSION_CODE + '')
          this.AboutInfoRow('构建类型', APP_BUILD_TYPE)
          this.AboutInfoRow('构建目标', APP_BUILD_TARGET)
          this.AboutInfoRow('构建时间', APP_BUILD_TIME)
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(10)
        .margin({ bottom: 12 })

        Column() {
          Text('构建说明')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .width('100%')
            .margin({ bottom: 8 })
          Text('第一段主版本由维护者手动指定，当前默认为 0；全量构建脚本每次自动增加第二段并重置第三段；增量构建脚本每次自动增加第三段。')
            .fontSize(13)
            .fontColor('#666666')
            .lineHeight(20)
            .width('100%')
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFFFFF')
        .borderRadius(10)
        .margin({ bottom: 20 })
      }
      .width('100%')
      .padding(14)
    }
    .layoutWeight(1)
    .backgroundColor('#F7F7F7')
  }
`;
    content = replaceOnce(content, '\n  @Builder\n  private BottomTabs() {', aboutBuilder + '\n  @Builder\n  private BottomTabs() {', 'AboutPage builder');
  }

  if (!content.includes("this.activeTab === 'about' ? '关于●' : '关于'")) {
    const oldSettingsButton = `      Button(this.activeTab === 'settings' ? '设置●' : '设置')
        .layoutWeight(1)
        .height(48)
        .fontSize(14)
        .onClick(() => { this.activeTab = 'settings'; })`;
    const newSettingsButton = `      Button(this.activeTab === 'settings' ? '设置●' : '设置')
        .layoutWeight(1)
        .height(48)
        .fontSize(14)
        .margin({ right: 6 })
        .onClick(() => { this.activeTab = 'settings'; })
      Button(this.activeTab === 'about' ? '关于●' : '关于')
        .layoutWeight(1)
        .height(48)
        .fontSize(14)
        .onClick(() => { this.activeTab = 'about'; })`;
    content = replaceOnce(content, oldSettingsButton, newSettingsButton, 'About bottom tab');
  }

  if (!content.includes("this.AboutPage()")) {
    const oldBuildSwitch = `      } else if (this.activeTab === 'shelf') {
        this.ShelfPage()
      } else {
        this.SettingsPage()
      }`;
    const newBuildSwitch = `      } else if (this.activeTab === 'shelf') {
        this.ShelfPage()
      } else if (this.activeTab === 'settings') {
        this.SettingsPage()
      } else {
        this.AboutPage()
      }`;
    content = replaceOnce(content, oldBuildSwitch, newBuildSwitch, 'About build switch');
  }

  fs.writeFileSync(INDEX_FILE, content);
  console.log('ComicReader CI ensured About page in Index.ets.');
}

patchAboutPage();

module.exports = { patchAboutPage };
