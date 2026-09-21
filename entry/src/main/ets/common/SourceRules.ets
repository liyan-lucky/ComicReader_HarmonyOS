import { ComicSourceRule } from '../model/ComicModels';

const COMMON_USER_AGENT = 'Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/120.0 Mobile Safari/537.36 ComicReaderHarmony/5.5';

const COMMON_SEARCH_ITEM_REGEX = `<a[^>]+href=["']([^"']+)["'][^>]*>([\\s\\S]{0,260}?)<\\/a>`;
const COMMON_DETAIL_CHAPTER_REGEX = `<a[^>]+href=["']([^"']+)["'][^>]*>([\\s\\S]{0,160}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|chapter|Episode|episode|Read Chapter|Start reading|开始阅读|立即阅读)[\\s\\S]{0,120}?)<\\/a>`;
const COMMON_READER_IMAGE_REGEX = `<img[^>]+(?:data-original|data-src|data-lazy-src|data-url|data-cfsrc|src|srcset)=["']([^"']+)["'][^>]*>|["']((?:https?:)?\\/\\/[^"']+\\.(?:jpg|jpeg|png|webp|gif|avif)(?:\\?[^"']*)?)["']|(?:images|chapterImages|comicImages|photos|pics|imgList|chapter_data|readerData)["']?\\s*[:=]\\s*(\\[[\\s\\S]{0,9000}?\\])`;
const COMMON_NEXT_PAGE_REGEX = `<a[^>]+href=["']([^"']+)["'][^>]*>(?:\\s*下一页\\s*|\\s*下页\\s*|\\s*Next\\s*|\\s*next\\s*|\\s*&gt;\\s*|\\s*›\\s*)<\\/a>|rel=["']next["'][^>]+href=["']([^"']+)["']|href=["']([^"']+)["'][^>]+rel=["']next["']`;

const VERIFIED_DESC = '由 1 部作品首/中/末章回放验证；每域一条规则。';
const PUBLIC_ACCESS_DESC = '搜索引擎发现后的公开页面解析规则：支持详情页章节、章节页图片、懒加载字段、JS/JSON直接图片URL、下一页追踪；静态无图时由无地址栏渲染卷轴兜底。不处理登录、付费、验证码或反爬绕过。';

const VERIFIED_DOMAIN_LIST: string[] = [
  '288manhua.com', '590ac.com', '5imanhua.click', 'ac.qq.com', 'akmh666.com',
  'asshow.com', 'b.faloo.com', 'baoziaicomic.com', 'bjzf.org', 'bkmh555.com',
  'bury.bljipeapy.com', 'cdt-gz.cn', 'china-armature.com', 'comic.qq.com',
  'cuimanhua.com', 'cuimh.com', 'cxjob.com.cn', 'dafumh.com', 'dagumh.com',
  'dandanmh.com', 'dayiming.cn', 'dhan.cc', 'digumh.com', 'dongman.qq.com',
  'dongmanmanhua.cn', 'duiduimanhua.com', 'duya.cc', 'ffppt.com',
  'guazimanhua.com', 'guazixs.cn', 'hazelmaka.com', 'hfuodip.com',
  'hongshu.com', 'hqqh.cc', 'htzsgc.cn', 'huayangdm.com', 'huozx.net',
  'jiexi8.com', 'jincs.cn', 'jiujiumanhua.com', 'jjwxc.net',
  'jsmanhuawang.com', 'katadyngroup.com.cn', 'kkwebtoon.com',
  'kuaikan321.com', 'kuaikanmanhua.com', 'm.bikamanhua.com', 'm.bjwsxx.com',
  'm.dagumanhua.cc', 'm.dumanwu.com', 'm.dumanwu1.com', 'm.guozhenglawyer.com',
  'm.haohuagg.com', 'm.jingmingbg.com', 'm.maomimh.com', 'm.ortzn.com',
  'm.sisimanhua.com', 'm.tcsrq.cn', 'manbatu.com', 'mangatoon.mobi',
  'manhua1234.com', 'manhuarenren.com', 'maomaoks.com', 'mdb88.com',
  'medyakey.com', 'mh250.cc', 'mh250.com', 'mhz4.com', 'mobile.ac.qq.com',
  'mwjsiot.com', 'mzywwcm.com', 'nhy2.com', 'nubbub.com', 'pdbgds.com',
  'pufeimanhuaw.com', 'runshua.com', 'sdxqx.com', 'sfmanhua.com',
  'shenqimanhua.net', 'shilunmh.com', 'shoujimanhua.com', 'songyuanman.com',
  'sqmh.app', 'sqrsks.com', 't.shuqi.com', 'tcsrq.cn', 'tzysjx.cn',
  'veryim.com', 'wap.faloo.com', 'xhp119.com', 'xhp124.com',
  'xkanmanhua.com', 'yandans.com', 'yinglifan.com', 'yiningguanggao.com',
  'yinxiang17.com', 'yixiuche.com', 'youzimanhua.com', 'z525.com',
  'zgmanhua.com', 'zhongkeman.com', 'zymk.cn'
];

const PUBLIC_ACCESS_LIST: [string, string, string][] = [
  ['mh160mh', '漫画160公开访问源（前20公开资源审计）', 'https://m.mh160mh.com'],
  ['shenlanqiyu', '神澜奇域公开访问源（前20公开资源审计）', 'https://www.shenlanqiyu.cc'],
  ['manhuaus', 'MANHUAUS公开访问源（前20公开资源审计）', 'https://manhuaus.com'],
  ['mangafire', 'MangaFire公开访问源（前20公开资源审计）', 'https://mangafire.to'],
  ['mangadna', 'MangaDNA公开访问源（前20公开资源审计）', 'https://mangadna.com'],
  ['mangaread', 'MangaRead公开访问源（前20公开资源审计）', 'https://www.mangaread.org'],
  ['mycomic', 'MYCOMIC公开访问源（前20公开资源审计）', 'https://mycomic.com'],
  ['toomics', 'Toomics公开访问源', 'https://toomics.com'],
  ['lezhin', 'Lezhin公开访问源', 'https://www.lezhin.com'],
  ['webtoons', 'Webtoons公开访问源', 'https://www.webtoons.com'],
  ['tapas', 'Tapas公开访问源', 'https://tapas.io'],
  ['mangadex', 'MangaDex公开访问源', 'https://mangadex.org'],
  ['guya', 'Guya公开访问源', 'https://guya.moe'],
  ['catmanga', 'CatManga公开访问源', 'https://catmanga.org'],
  ['manga4life', 'Manga4Life公开访问源', 'https://manga4life.com'],
  ['asurascans', 'AsuraScans公开访问源', 'https://asurascans.com'],
  ['flamescans', 'FlameScans公开访问源', 'https://flamescans.org'],
  ['reapertranslates', 'ReaperTranslates公开访问源', 'https://reapertranslates.com'],
  ['lhtranslates', 'LHTranslates公开访问源', 'https://lhtranslates.com'],
  ['immortalscans', 'ImmortalScans公开访问源', 'https://immortalscans.com'],
  ['mangakakalot', 'MangaKakalot公开访问源', 'https://mangakakalot.com'],
  ['manganato', 'Manganato公开访问源', 'https://manganato.com'],
  ['readmanga', 'ReadManga公开访问源', 'https://readmanga.app'],
  ['manhuatop', 'ManhuaTop公开访问源', 'https://manhuatop.com'],
  ['manhuaes', 'ManhuaES公开访问源', 'https://manhuaes.com'],
  ['manhwa18', 'Manhwa18公开访问源', 'https://manhwa18.cc'],
  ['toonily', 'Toonily公开访问源', 'https://toonily.com'],
  ['manganelo', 'Manganelo公开访问源', 'https://manganelo.com'],
  ['hentai2read', 'Hentai2Read公开访问源', 'https://hentai2read.com'],
  ['nhentai', 'nhentai公开访问源', 'https://nhentai.net'],
  ['myreadingmanga', 'MyReadingManga公开访问源', 'https://myreadingmanga.info'],
  ['dmzj', '动漫之家公开访问源', 'https://www.dmzj.com'],
  ['chuiyao', '吹妖公开访问源', 'https://www.chuiyao.com'],
  ['57mh', '57漫画公开访问源', 'https://www.57mh.com'],
  ['aikanmanhua', '爱看漫画公开访问源', 'https://www.aikanmanhua.com'],
  ['manhuagui', '漫画柜公开访问源', 'https://www.manhuagui.com'],
  ['manhuaren', '漫画人公开访问源', 'https://www.manhuaren.com'],
  ['ikanman', '爱漫画公开访问源', 'https://www.ikanman.com'],
  ['dm5', '动漫屋公开访问源', 'https://www.dm5.cn'],
  ['manwang', '漫王公开访问源', 'https://www.manwang.net'],
  ['ttkmh', '天天看漫画公开访问源', 'https://www.ttkmh.com'],
  ['labimanhua', '哔哩漫画公开访问源', 'https://www.labimanhua.com'],
  ['hitomi', 'Hitomi公开访问源', 'https://hitomi.la'],
  ['jwxs', '晋江文学城公开访问源', 'https://www.jwxs.org']
];

export const DEFAULT_SOURCES: ComicSourceRule[] = [
  {
    id: 'generic_verified',
    name: '已验证公开源通用规则',
    description: VERIFIED_DESC,
    homepage: '',
    searchUrl: '',
    searchMethod: 'url-only',
    searchItemRegex: COMMON_SEARCH_ITEM_REGEX,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: false,
    detailChapterRegex: COMMON_DETAIL_CHAPTER_REGEX,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: COMMON_READER_IMAGE_REGEX,
    readerImageGroups: [1, 2, 3],
    userAgent: COMMON_USER_AGENT,
    referer: '',
    maxReaderPages: 12
  },
  {
    id: 'generic_public_access',
    name: '公开访问源通用规则',
    description: PUBLIC_ACCESS_DESC,
    homepage: '',
    searchUrl: '',
    searchMethod: 'url-only',
    searchItemRegex: COMMON_SEARCH_ITEM_REGEX,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: false,
    detailChapterRegex: COMMON_DETAIL_CHAPTER_REGEX,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: COMMON_READER_IMAGE_REGEX,
    readerImageGroups: [1, 2, 3],
    userAgent: COMMON_USER_AGENT,
    referer: '',
    readerNextPageRegex: COMMON_NEXT_PAGE_REGEX,
    readerNextPageUrlGroups: [1, 2, 3],
    maxReaderPages: 16
  }
];

export const VERIFIED_DOMAIN_COUNT = VERIFIED_DOMAIN_LIST.length;
export const PUBLIC_ACCESS_DOMAIN_COUNT = PUBLIC_ACCESS_LIST.length;

export function isComicDomain(url: string): boolean {
  let host = url.toLowerCase().trim();
  const proto = host.indexOf('://');
  if (proto >= 0) host = host.substring(proto + 3);
  const slash = host.indexOf('/');
  if (slash >= 0) host = host.substring(0, slash);
  if (host.startsWith('www.')) host = host.substring(4);
  for (let i = 0; i < VERIFIED_DOMAIN_LIST.length; i++) {
    const d = VERIFIED_DOMAIN_LIST[i];
    if (host === d || host.endsWith('.' + d)) return true;
  }
  for (let i = 0; i < PUBLIC_ACCESS_LIST.length; i++) {
    const d = PUBLIC_ACCESS_LIST[i][2];
    let dh = d.toLowerCase();
    const dp = dh.indexOf('://');
    if (dp >= 0) dh = dh.substring(dp + 3);
    const ds = dh.indexOf('/');
    if (ds >= 0) dh = dh.substring(0, ds);
    if (dh.startsWith('www.')) dh = dh.substring(4);
    if (host === dh || host.endsWith('.' + dh)) return true;
  }
  if (/(?:manhua|manga|comic|webtoon|manhwa|mh|dm|cartoon|onemanga)\b/i.test(host)) return true;
  return false;
}

export function buildRuleForVerifiedDomain(domain: string): ComicSourceRule {
  return {
    id: domain.replace(/\./g, '_'),
    name: domain + ' 已验证公开源',
    description: VERIFIED_DESC,
    homepage: 'https://' + domain,
    searchUrl: '',
    searchMethod: 'url-only',
    searchItemRegex: COMMON_SEARCH_ITEM_REGEX,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: false,
    detailChapterRegex: COMMON_DETAIL_CHAPTER_REGEX,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: COMMON_READER_IMAGE_REGEX,
    readerImageGroups: [1, 2, 3],
    userAgent: COMMON_USER_AGENT,
    referer: 'https://' + domain + '/',
    maxReaderPages: 12,
    domainApplicabilityList: [domain]
  };
}

export function buildRuleForPublicAccess(idSuffix: string, displayName: string, homepage: string): ComicSourceRule {
  return {
    id: idSuffix + '_public_access',
    name: displayName,
    description: PUBLIC_ACCESS_DESC,
    homepage: homepage,
    searchUrl: '',
    searchMethod: 'url-only',
    searchItemRegex: COMMON_SEARCH_ITEM_REGEX,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: false,
    detailChapterRegex: COMMON_DETAIL_CHAPTER_REGEX,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: COMMON_READER_IMAGE_REGEX,
    readerImageGroups: [1, 2, 3],
    userAgent: COMMON_USER_AGENT,
    referer: homepage + '/',
    readerNextPageRegex: COMMON_NEXT_PAGE_REGEX,
    readerNextPageUrlGroups: [1, 2, 3],
    maxReaderPages: 16
  };
}

function hostOf(url: string): string {
  let host = url.toLowerCase().trim();
  const protocol = host.indexOf('://');
  if (protocol >= 0) host = host.substring(protocol + 3);
  const slash = host.indexOf('/');
  if (slash >= 0) host = host.substring(0, slash);
  const port = host.indexOf(':');
  if (port >= 0) host = host.substring(0, port);
  return host.startsWith('www.') ? host.substring(4) : host;
}

const PUBLIC_ACCESS_HOSTS: string[] = PUBLIC_ACCESS_LIST.map((item: [string, string, string]) => hostOf(item[2]));

const EXTRA_UNVERIFIED_DOMAINS: string[] = [
  'kaixinman.com', 'soullandmanga.com', 'mgeko.cc', 'happymh.com',
  'douluodalu.cc', 'tangmen.app', 'longwangchuanshuo.com', 'shenlanqiyu.org',
  'bilibili.com', 'lpsdimataram.com', 'ycymh.com', 'manhuaba.com',
  'manwame.com', 'xiaoaimh.com', 'mechacomic.jp', 'yanmaga.jp',
  'pocket.shonenmagazine.com', 'kodansha.co.jp'
];

const UNVERIFIED_PUBLIC_HOSTS: string[] = [
  'm.mh160mh.com', 'shenlanqiyu.cc', 'manhuaus.com', 'mangafire.to',
  'mangadna.com', 'mangaread.org', 'mycomic.com',
  'manhuagui.com', 'labimanhua.com', 'dm5.cn', 'manwang.net',
  'ttkmh.com', 'hitomi.la', 'jwxs.org',
  ...EXTRA_UNVERIFIED_DOMAINS
];

const TOP20_AUDITED_HOSTS: string[] = [
  ...PUBLIC_ACCESS_HOSTS,
  ...EXTRA_UNVERIFIED_DOMAINS,
  'm.ac.qq.com', 'ac.qq.com', 'shenqimanhua.net'
];

const OFFICIAL_COLLECTION_DOMAINS: string[] = [
  'm.ac.qq.com', 'comic.qq.com', 'ac.qq.com', 'qidian.com',
  'webtoons.com', 'archive.org', 'openlibrary.org', 'loc.gov',
  'wikimedia.org', 'xkcd.com', 'peppercarrot.com'
];

const LOGIN_OR_PAY_DOMAINS: string[] = [
  'qidian.com', 'mkzhan.com', 'inkr.com', 'utoon.net',
  'comix.to', 'scribd.com', 'webnovel.com', 'jd.com',
  'amazon.', 'youtube.com', 'pinterest.', 'reddit.com',
  'fandom.com', 'readsoulland.com', 'dstranslating.com'
];

function urlContainsAny(url: string, domains: string[]): boolean {
  const lower = url.toLowerCase();
  for (let i = 0; i < domains.length; i++) {
    if (lower.indexOf(domains[i]) >= 0) return true;
  }
  return false;
}

export function ruleForPublicUrl(url: string, fallback: ComicSourceRule): ComicSourceRule {
  const targetHost = hostOf(url);
  for (let i = 0; i < VERIFIED_DOMAIN_LIST.length; i++) {
    const domain = VERIFIED_DOMAIN_LIST[i];
    if (targetHost === domain || targetHost.endsWith('.' + domain)) {
      return buildRuleForVerifiedDomain(domain);
    }
  }
  for (let i = 0; i < PUBLIC_ACCESS_LIST.length; i++) {
    const item = PUBLIC_ACCESS_LIST[i];
    const ruleHost = hostOf(item[2]);
    if (targetHost === ruleHost || targetHost.endsWith('.' + ruleHost)) {
      return buildRuleForPublicAccess(item[0], item[1], item[2]);
    }
  }
  return fallback;
}

export function isUnverifiedPublicDomain(url: string): boolean {
  return urlContainsAny(url, UNVERIFIED_PUBLIC_HOSTS);
}

export function isOfficialOrPublicCollectionDomain(url: string): boolean {
  return urlContainsAny(url, OFFICIAL_COLLECTION_DOMAINS);
}

export function isKnownLoginOrPayDomain(url: string): boolean {
  return urlContainsAny(url, LOGIN_OR_PAY_DOMAINS);
}

export function isTop20AuditedPublicReadableDomain(url: string): boolean {
  return urlContainsAny(url, TOP20_AUDITED_HOSTS);
}

export const SEARCHABLE_COMIC_SOURCES: ComicSourceRule[] = [
  {
    id: 'search_manhuagui',
    name: '漫画柜站内搜索',
    description: '漫画柜 manhuagui.com 站内搜索，直接在站点搜索页提取漫画链接。',
    homepage: 'https://www.manhuagui.com',
    searchUrl: 'https://www.manhuagui.com/s/{keyword}.html',
    searchMethod: 'get',
    searchItemRegex: `<a[^>]+href=["']([^"']+)["'][^>]*>([\\s\\S]{0,260}?)<\\/a>`,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: false,
    detailChapterRegex: COMMON_DETAIL_CHAPTER_REGEX,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: COMMON_READER_IMAGE_REGEX,
    readerImageGroups: [1, 2, 3],
    userAgent: COMMON_USER_AGENT,
    referer: 'https://www.manhuagui.com/',
    maxReaderPages: 12
  },
  {
    id: 'search_dm5',
    name: '动漫屋站内搜索',
    description: '动漫屋 dm5.cn 站内搜索，直接在站点搜索页提取漫画链接。',
    homepage: 'https://www.dm5.cn',
    searchUrl: 'https://www.dm5.cn/search?title={keyword}',
    searchMethod: 'get',
    searchItemRegex: `<a[^>]+href=["']([^"']+)["'][^>]*>([\\s\\S]{0,260}?)<\\/a>`,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: false,
    detailChapterRegex: COMMON_DETAIL_CHAPTER_REGEX,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: COMMON_READER_IMAGE_REGEX,
    readerImageGroups: [1, 2, 3],
    userAgent: COMMON_USER_AGENT,
    referer: 'https://www.dm5.cn/',
    maxReaderPages: 16
  },
  {
    id: 'search_manhuaren',
    name: '漫画人站内搜索',
    description: '漫画人 manhuaren.com 站内搜索，直接在站点搜索页提取漫画链接。',
    homepage: 'https://www.manhuaren.com',
    searchUrl: 'https://www.manhuaren.com/search?query={keyword}',
    searchMethod: 'get',
    searchItemRegex: `<a[^>]+href=["']([^"']+)["'][^>]*>([\\s\\S]{0,260}?)<\\/a>`,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: true,
    detailChapterRegex: COMMON_DETAIL_CHAPTER_REGEX,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: COMMON_READER_IMAGE_REGEX,
    readerImageGroups: [1, 2, 3],
    userAgent: COMMON_USER_AGENT,
    referer: 'https://www.manhuaren.com/',
    maxReaderPages: 12
  },
  {
    id: 'search_ikanman',
    name: '爱漫画站内搜索',
    description: '爱漫画 ikanman.com 站内搜索，直接在站点搜索页提取漫画链接。',
    homepage: 'https://www.ikanman.com',
    searchUrl: 'https://www.ikanman.com/search?query={keyword}',
    searchMethod: 'get',
    searchItemRegex: `<a[^>]+href=["']([^"']+)["'][^>]*>([\\s\\S]{0,260}?)<\\/a>`,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: false,
    detailChapterRegex: COMMON_DETAIL_CHAPTER_REGEX,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: COMMON_READER_IMAGE_REGEX,
    readerImageGroups: [1, 2, 3],
    userAgent: COMMON_USER_AGENT,
    referer: 'https://www.ikanman.com/',
    maxReaderPages: 12
  },
  {
    id: 'search_57mh',
    name: '57漫画站内搜索',
    description: '57漫画 57mh.com 站内搜索，直接在站点搜索页提取漫画链接。',
    homepage: 'https://www.57mh.com',
    searchUrl: 'https://www.57mh.com/search?query={keyword}',
    searchMethod: 'get',
    searchItemRegex: `<a[^>]+href=["']([^"']+)["'][^>]*>([\\s\\S]{0,260}?)<\\/a>`,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: false,
    detailChapterRegex: COMMON_DETAIL_CHAPTER_REGEX,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: COMMON_READER_IMAGE_REGEX,
    readerImageGroups: [1, 2, 3],
    userAgent: COMMON_USER_AGENT,
    referer: 'https://www.57mh.com/',
    maxReaderPages: 12
  },
  {
    id: 'search_aikanmanhua',
    name: '爱看漫画站内搜索',
    description: '爱看漫画 aikanmanhua.com 站内搜索，直接在站点搜索页提取漫画链接。',
    homepage: 'https://www.aikanmanhua.com',
    searchUrl: 'https://www.aikanmanhua.com/search?query={keyword}',
    searchMethod: 'get',
    searchItemRegex: `<a[^>]+href=["']([^"']+)["'][^>]*>([\\s\\S]{0,260}?)<\\/a>`,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: false,
    detailChapterRegex: COMMON_DETAIL_CHAPTER_REGEX,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: COMMON_READER_IMAGE_REGEX,
    readerImageGroups: [1, 2, 3],
    userAgent: COMMON_USER_AGENT,
    referer: 'https://www.aikanmanhua.com/',
    maxReaderPages: 12
  },
  {
    id: 'search_mangakakalot',
    name: 'MangaKakalot站内搜索',
    description: 'MangaKakalot 站内搜索，英文漫画站点直接搜索。',
    homepage: 'https://mangakakalot.com',
    searchUrl: 'https://mangakakalot.com/search/story/{keyword}',
    searchMethod: 'get',
    searchItemRegex: `<a[^>]+href=["']([^"']+)["'][^>]*>([\\s\\S]{0,260}?)<\\/a>`,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: false,
    detailChapterRegex: COMMON_DETAIL_CHAPTER_REGEX,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: COMMON_READER_IMAGE_REGEX,
    readerImageGroups: [1, 2, 3],
    userAgent: COMMON_USER_AGENT,
    referer: 'https://mangakakalot.com/',
    maxReaderPages: 12
  },
  {
    id: 'search_manganato',
    name: 'Manganato站内搜索',
    description: 'Manganato 站内搜索，英文漫画站点直接搜索。',
    homepage: 'https://manganato.com',
    searchUrl: 'https://manganato.com/search/story/{keyword}',
    searchMethod: 'get',
    searchItemRegex: `<a[^>]+href=["']([^"']+)["'][^>]*>([\\s\\S]{0,260}?)<\\/a>`,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: false,
    detailChapterRegex: COMMON_DETAIL_CHAPTER_REGEX,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: COMMON_READER_IMAGE_REGEX,
    readerImageGroups: [1, 2, 3],
    userAgent: COMMON_USER_AGENT,
    referer: 'https://manganato.com/',
    maxReaderPages: 12
  },
  {
    id: 'search_mh160',
    name: '漫画160站内搜索',
    description: '漫画160 mh160mh.com 站内搜索，直接在站点搜索页提取漫画链接。',
    homepage: 'https://m.mh160mh.com',
    searchUrl: 'https://m.mh160mh.com/search?query={keyword}',
    searchMethod: 'get',
    searchItemRegex: `<a[^>]+href=["']([^"']+)["'][^>]*>([\\s\\S]{0,260}?)<\\/a>`,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: false,
    detailChapterRegex: COMMON_DETAIL_CHAPTER_REGEX,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: COMMON_READER_IMAGE_REGEX,
    readerImageGroups: [1, 2, 3],
    userAgent: COMMON_USER_AGENT,
    referer: 'https://m.mh160mh.com/',
    maxReaderPages: 12
  },
  {
    id: 'search_dmzj',
    name: '动漫之家站内搜索',
    description: '动漫之家 dmzj.com 站内搜索，直接在站点搜索页提取漫画链接。',
    homepage: 'https://www.dmzj.com',
    searchUrl: 'https://www.dmzj.com/search?title={keyword}',
    searchMethod: 'get',
    searchItemRegex: `<a[^>]+href=["']([^"']+)["'][^>]*>([\\s\\S]{0,260}?)<\\/a>`,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: false,
    detailChapterRegex: COMMON_DETAIL_CHAPTER_REGEX,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: COMMON_READER_IMAGE_REGEX,
    readerImageGroups: [1, 2, 3],
    userAgent: COMMON_USER_AGENT,
    referer: 'https://www.dmzj.com/',
    maxReaderPages: 12
  }
];

export const RULE_TEMPLATE = `{
  "id": "my_public_source",
  "name": "我的公开漫画源",
  "description": "仅填写你有权抓取或允许公开访问的站点规则。搜索结果建议包含封面图片，章节页支持下一页追踪。",
  "homepage": "https://example.com",
  "searchUrl": "https://example.com/search?q={keyword}",
  "searchMethod": "get",
  "searchItemRegex": "<div[^>]+class=\\\"comic-item\\\"[\\\\s\\\\S]*?<a[^>]+href=\\\"([^\\\"]+)\\\"[\\\\s\\\\S]*?<img[^>]+(?:data-src|data-original|src)=\\\"([^\\\"]+)\\\"[\\\\s\\\\S]*?<h3[^>]*>([\\\\s\\\\S]*?)<\\/h3>[\\\\s\\\\S]*?<\\/div>",
  "searchTitleGroups": [3],
  "searchUrlGroups": [1],
  "searchCoverGroups": [2],
  "searchResultIsChapter": false,
  "searchFilterByKeyword": false,
  "detailChapterRegex": "<a[^>]+href=\\\"([^\\\"]+)\\\"[^>]*>(第[\\\\s\\\\S]{1,40}?话|Chapter[\\\\s\\\\S]{1,40}?)<\\/a>",
  "detailChapterTitleGroups": [2],
  "detailChapterUrlGroups": [1],
  "detailChapterFilter": true,
  "readerImageRegex": "<img[^>]+(?:data-src|data-original|data-lazy-src|src)=\\\"([^\\\"]+)\\\"[^>]*>|\\\"((?:https?:)?//[^\\\"]+\\\\.(?:jpg|jpeg|png|webp|gif)(?:\\\\?[^\\\"]*)?)\\\"",
  "readerImageGroups": [1, 2],
  "readerNextPageRegex": "<a[^>]+href=\\\"([^\\\"]+)\\\"[^>]*>(?:下一页|Next|&gt;)<\\/a>|rel=\\\"next\\\"[^>]+href=\\\"([^\\\"]+)\\\"",
  "readerNextPageUrlGroups": [1, 2],
  "maxReaderPages": 8,
  "userAgent": "Mozilla/5.0 HarmonyOS ComicReader",
  "referer": ""
}`;
