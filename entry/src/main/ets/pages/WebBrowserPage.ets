import router from '@ohos.router';
import webview from '@ohos.web.webview';
import drawing from '@ohos.graphics.drawing';
import { isComicDomain } from '../common/SourceRules';

interface WebBrowserParams {
  url: string;
  title: string;
  isDark: boolean;
  statusBarHeight: number;
}

function toArgbColor(color: string): number {
  const normalized = color.trim().startsWith('#') ? color.trim().substring(1) : color.trim();
  if (normalized.length === 8) return parseInt(normalized, 16);
  return 0xFF000000 + parseInt(normalized, 16);
}

function strokeColorFilter(color: string): drawing.ColorFilter {
  return drawing.ColorFilter.createBlendModeColorFilter(toArgbColor(color), drawing.BlendMode.SRC_IN);
}

@Entry
@Component
struct WebBrowserPage {
  @State pageUrl: string = '';
  @State pageTitle: string = '';
  @State isDark: boolean = false;
  @State loading: boolean = true;
  @State errorText: string = '';
  @State statusBarHeight: number = 48;
  @State showReaderHint: boolean = false;
  private lastSuccessfulUrl: string = '';
  private mainFrameLoadFailed: boolean = false;
  private isAlive: boolean = true;
  private restoreTimerId: number = -1;
  private restoreAttempt: number = 0;
  private controller: webview.WebviewController = new webview.WebviewController();
  private darkModeCssScript: string =
    "(function(){" +
    "var s=document.createElement('style');" +
    "s.id='hw-dark-inject';" +
    "s.textContent='html,body,div,section,article,main,aside,nav,header,footer,figure,figcaption,table,tr,td,th,thead,tbody,tfoot,ul,ol,li,dl,dt,dd,p,blockquote,pre,code,form,fieldset,legend,label,option,optgroup,caption,h1,h2,h3,h4,h5,h6{background-color:#1a1a1a !important;color:#e0e0e0 !important;border-color:#333 !important;}a,a *{color:#4a9eff !important;}input,textarea,select,button{background-color:#2a2a2a !important;color:#e0e0e0 !important;border-color:#444 !important;}img,video,canvas{opacity:0.92;}';" +
    "document.documentElement.appendChild(s);" +
    "})();";

  aboutToAppear(): void {
    const params = router.getParams() as WebBrowserParams;
    if (params !== undefined && params.url !== undefined &&
      (params.url.startsWith('http://') || params.url.startsWith('https://'))) {
      this.pageUrl = params.url;
      this.pageTitle = params.title === undefined ? '' : params.title;
      this.isDark = params.isDark === undefined ? false : params.isDark;
      if (params.statusBarHeight !== undefined && params.statusBarHeight > 0) this.statusBarHeight = params.statusBarHeight;
    } else {
      this.errorText = this.isDark ? '无效的网址' : 'Invalid URL';
      this.loading = false;
    }
  }

  aboutToDisappear(): void {
    this.isAlive = false;
    if (this.restoreTimerId !== -1) clearTimeout(this.restoreTimerId);
  }

  onBackPress(): boolean {
    this.navigateBack();
    return true;
  }

  private navigateBack(): void {
    try {
      if (this.controller.accessBackward()) {
        this.errorText = '';
        this.loading = true;
        this.controller.backward();
        return;
      }
    } catch (error) {}
    router.back();
  }

  private openInReader(): void {
    const url: string = this.lastSuccessfulUrl.length > 0 ? this.lastSuccessfulUrl : this.pageUrl;
    if (url.length === 0) return;
    router.back({ url: 'pages/Index', params: { readerUrl: url, readerTitle: this.pageTitle } });
  }

  private pageBg(): string { return this.isDark ? '#111318' : '#F6F8FA'; }
  private primaryText(): string { return this.isDark ? '#E8ECF4' : '#111827'; }
  private secondaryText(): string { return this.isDark ? '#B6BFCC' : '#667085'; }
  private headerBg(): string { return this.isDark ? '#1E232F' : '#FFFFFF'; }

  private handleMainFrameError(errorInfo: string): void {
    this.mainFrameLoadFailed = true;
    if (errorInfo.indexOf('ERR_CONNECTION_CLOSED') >= 0 && this.lastSuccessfulUrl.length > 0 && this.restoreAttempt < 3) {
      this.restoreAttempt++;
      this.loading = true;
      this.errorText = '';
      const restoreUrl: string = this.lastSuccessfulUrl;
      if (this.restoreTimerId !== -1) clearTimeout(this.restoreTimerId);
      this.restoreTimerId = setTimeout((): void => {
        if (!this.isAlive) return;
        try { this.controller.loadUrl(restoreUrl); }
        catch (error) { this.loading = false; this.errorText = errorInfo; }
      }, 1500);
      return;
    }
    this.restoreAttempt = 0;
    this.loading = false;
    this.errorText = errorInfo;
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      if (this.pageUrl.length > 0) {
        Stack() {
          Web({ src: this.pageUrl, controller: this.controller, renderMode: RenderMode.SYNC_RENDER })
            .width('100%').height('100%')
            .javaScriptAccess(true).domStorageAccess(true)
            .mixedMode(MixedMode.None).cacheMode(CacheMode.Default)
            .imageAccess(true).zoomAccess(true)
            .fileAccess(false).databaseAccess(false)
            .userAgent('Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
            .darkMode(this.isDark ? WebDarkMode.On : WebDarkMode.Off)
            .forceDarkAccess(this.isDark)
            .javaScriptOnDocumentStart(this.isDark ? [{ script: this.darkModeCssScript, scriptRules: ['*'] }] : [])
            .backgroundColor(this.isDark ? '#1a1a1a' : '#F6F8FA')
            .onPageBegin(() => {
              this.mainFrameLoadFailed = false;
              this.loading = true;
              this.errorText = '';
              if (this.isDark) {
                try { this.controller.runJavaScript(this.darkModeCssScript); } catch (e) {}
              }
            })
            .onPageEnd((event: OnPageEndEvent) => {
              this.loading = false;
              if (!this.mainFrameLoadFailed && event !== undefined && event.url !== undefined &&
                (event.url.startsWith('http://') || event.url.startsWith('https://'))) {
                this.lastSuccessfulUrl = event.url;
                if (event.url !== this.pageUrl) this.pageTitle = '';
                this.showReaderHint = isComicDomain(event.url);
              }
              if (this.isDark) {
                try {
                  this.controller.runJavaScript(this.darkModeCssScript);
                } catch (e) {}
              }
            })
            .onSslErrorEventReceive((event: OnSslErrorEventReceiveEvent) => {
              if (event !== undefined && event.handler !== undefined) event.handler.handleCancel();
            })
            .onErrorReceive((event: OnErrorReceiveEvent) => {
              if (event !== undefined && event.request !== undefined && event.request.isMainFrame() &&
                event.error !== undefined) {
                this.handleMainFrameError(event.error.getErrorInfo());
              }
            })
          if (this.loading) {
            Stack({ alignContent: Alignment.Center }) {
              Column({ space: 12 }) {
                LoadingProgress().width(36).height(36).color(this.secondaryText())
                Text(this.isDark ? '加载中...' : 'Loading...').fontSize(14).fontColor(this.secondaryText())
              }
            }.width('100%').height('100%').backgroundColor(this.pageBg())
          }
          if (this.errorText.length > 0) {
            Column({ space: 12 }) {
              Text(this.errorText).fontSize(14).fontColor(this.secondaryText()).textAlign(TextAlign.Center).padding({ left: 24, right: 24 })
              Text(this.isDark ? '点击返回重试' : 'Press back to retry').fontSize(12).fontColor(this.secondaryText())
            }.width('100%').height('100%').justifyContent(FlexAlign.Center).backgroundColor(this.pageBg())
          }
        }.width('100%').height('100%').backgroundColor(this.pageBg())
      }
      this.HeaderOverlay()
      if (this.showReaderHint) {
        Stack({ alignContent: Alignment.Center }) {
          Image($rawfile('ic_reader.svg')).width(26).height(26)
            .colorFilter(strokeColorFilter(this.isDark ? '#FF2D92' : '#167A36'))
        }
        .width(56).height(56)
        .borderRadius(28)
        .backgroundColor('#40FFFFFF')
        .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THIN)
        .border({ width: 1, color: this.isDark ? '#30FFFFFF' : '#20000000' })
        .shadow({ radius: 8, color: '#40000000', offsetY: 2 })
        .position({ x: '82%', y: '70%' })
        .onClick(() => { this.openInReader(); })
      }
    }
    .width('100%').height('100%')
    .backgroundColor(this.pageBg())
  }

  @Builder
  HeaderOverlay() {
    Column() {
      Blank().height(this.statusBarHeight)
      Row() {
        Image($rawfile('ic_back.svg')).width(24).height(24).margin({ left: 4, right: 12 })
          .colorFilter(strokeColorFilter(this.primaryText())).onClick(() => this.navigateBack())
        Blank().layoutWeight(1)
        if (this.loading) {
          LoadingProgress().width(22).height(22).color(this.secondaryText()).margin({ right: 8 })
        }
        Image($rawfile('ic_reader.svg')).width(22).height(22).margin({ right: 4 })
          .colorFilter(strokeColorFilter(this.isDark ? '#34C759' : '#167A36')).onClick(() => this.openInReader())
      }.width('100%').height(50).padding({ left: 12, right: 16 })
    }
    .width('100%')
  }
}
