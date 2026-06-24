import { ComicSourceRule } from '../model/ComicModels';
import { GENERATED_SOURCES } from './GeneratedSourceRules';

const COMMON_USER_AGENT = 'Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/120.0 Mobile Safari/537.36 ComicReaderHarmony/5.5';


function publicAccessRule(id: string, name: string, homepage: string, referer: string): ComicSourceRule {
  return {
    id: id,
    name: name,
    description: '搜索引擎发现后的公开页面解析规则：支持详情页章节、章节页图片、懒加载字段、JS/JSON直接图片URL、下一页追踪；静态无图时由无地址栏渲染卷轴兜底。不处理登录、付费、验证码或反爬绕过。',
    homepage: homepage,
    searchUrl: '',
    searchMethod: 'url-only',
    searchItemRegex: `<a[^>]+href=["']([^"']+)["'][^>]*>([\\s\\S]{0,260}?)<\\/a>`,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: false,
    detailChapterRegex: `<a[^>]+href=["']([^"']+)["'][^>]*>([\\s\\S]{0,160}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|chapter|Episode|episode|Read Chapter|Start reading|开始阅读|立即阅读)[\\s\\S]{0,120}?)<\\/a>`,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: `<img[^>]+(?:data-original|data-src|data-lazy-src|data-url|data-cfsrc|src|srcset)=["']([^"']+)["'][^>]*>|["']((?:https?:)?\\/\\/[^"']+\\.(?:jpg|jpeg|png|webp|gif|avif)(?:\\?[^"']*)?)["']|(?:images|chapterImages|comicImages|photos|pics|imgList|chapter_data|readerData)["']?\\s*[:=]\\s*(\\[[\\s\\S]{0,9000}?\\])`,
    readerImageGroups: [1, 2, 3],
    userAgent: COMMON_USER_AGENT,
    referer: referer,
    readerNextPageRegex: `<a[^>]+href=["']([^"']+)["'][^>]*>(?:\\s*下一页\\s*|\\s*下页\\s*|\\s*Next\\s*|\\s*next\\s*|\\s*&gt;\\s*|\\s*›\\s*)<\\/a>|rel=["']next["'][^>]+href=["']([^"']+)["']|href=["']([^"']+)["'][^>]+rel=["']next["']`,
    readerNextPageUrlGroups: [1, 2, 3],
    maxReaderPages: 16
  };
}

export const DEFAULT_SOURCES: ComicSourceRule[] = [
  ...GENERATED_SOURCES,

  publicAccessRule('mh160mh_public_access', '漫画160公开访问源（前20公开资源审计）', 'https://m.mh160mh.com', 'https://m.mh160mh.com/'),
  publicAccessRule('shenlanqiyu_public_access', '神澜奇域公开访问源（前20公开资源审计）', 'https://www.shenlanqiyu.cc', 'https://www.shenlanqiyu.cc/'),
  publicAccessRule('manhuaus_public_access', 'MANHUAUS公开访问源（前20公开资源审计）', 'https://manhuaus.com', 'https://manhuaus.com/'),
  publicAccessRule('mangafire_public_access', 'MangaFire公开访问源（前20公开资源审计）', 'https://mangafire.to', 'https://mangafire.to/'),
  publicAccessRule('mangadna_public_access', 'MangaDNA公开访问源（前20公开资源审计）', 'https://mangadna.com', 'https://mangadna.com/'),
  publicAccessRule('mangaread_public_access', 'MangaRead公开访问源（前20公开资源审计）', 'https://www.mangaread.org', 'https://www.mangaread.org/'),
  publicAccessRule('mycomic_public_access', 'MYCOMIC公开访问源（前20公开资源审计）', 'https://mycomic.com', 'https://mycomic.com/'),

  {
    id: 'tencent_ac_official_catalog',
    name: '腾讯动漫官方目录源（合规目录，不抓付费图）',
    description: '腾讯动漫官方/正版平台。用于搜索作品、显示封面与目录、识别可试读章节；不绕过登录、APP限制、付费或图片保护，不做章节图片抓取。',
    homepage: 'https://m.ac.qq.com',
    searchUrl: 'https://m.ac.qq.com/search/result?word={keyword}',
    searchMethod: 'get',
    searchItemRegex: `<a[^>]+href=["']([^"']*\/comic\/index\/id\/[0-9]+[^"']*)["'][^>]*>([\\s\\S]{0,420}?)<\/a>`,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: true,
    detailChapterRegex: `<a[^>]+href=["']([^"']*\/chapter\/index\/id\/[0-9]+\/cid\/[0-9]+[^"']*)["'][^>]*>([\\s\\S]{1,120}?)<\/a>`,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: `__NO_IMAGE_SCRAPING_FOR_OFFICIAL_SOURCE__`,
    readerImageGroups: [1],
    userAgent: COMMON_USER_AGENT,
    referer: 'https://m.ac.qq.com/',
    maxReaderPages: 1
  },
  {
    id: 'xkcd_public_webcomic',
    name: 'XKCD公开网页漫画源',
    description: '公开网页漫画演示源。输入英文关键词后会搜索归档，自动进入单话页提取封面/漫画图并支持卷轴阅读。',
    homepage: 'https://xkcd.com',
    searchUrl: 'https://xkcd.com/archive/',
    searchMethod: 'get',
    searchItemRegex: `<a\\s+href=["']([^"']+)["']\\s+title=["'][^"']*["']\\s*>([^<]+)<\\/a>`,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: true,
    searchFilterByKeyword: true,
    detailChapterRegex: `<a\\s+href=["']([^"']+)["']\\s+title=["'][^"']*["']\\s*>([^<]+)<\\/a>`,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: false,
    readerImageRegex: `<div\\s+id=["']comic["'][\\s\\S]*?<img[^>]+src=["']([^"']+)["']|"img"\\s*:\\s*"([^"]+)"`,
    readerImageGroups: [1, 2],
    userAgent: COMMON_USER_AGENT,
    referer: 'https://xkcd.com/',
    maxReaderPages: 1
  },

  {
    id: 'kaixinman_public_access',
    name: '开心漫公开访问源（可在过滤中开关）',
    description: '公开网页可访问源：已针对开心漫详情页/章节页做专用审计，支持详情封面、章节目录、JS转义图片URL、静态懒加载图片和无地址栏渲染卷轴兜底；不处理登录、验证码、付费或反爬绕过。',
    homepage: 'https://www.kaixinman.com',
    searchUrl: 'https://www.kaixinman.com/search?keyword={keyword}',
    searchMethod: 'get',
    searchItemRegex: `<a[^>]+href=["']([^"']*\/comic\/[^"']+)["'][^>]*>([\\s\\S]{0,680}?)<\/a>`,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: true,
    detailChapterRegex: `<a[^>]+href=["']([^"']*\/chapter\/[^"']+)["'][^>]*>([\\s\\S]{0,220}?(?:第|话|章|Chapter|立即阅读|下一章)[\\s\\S]{0,100}?)<\/a>`,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: `<img[^>]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=["']([^"']+)["'][^>]*>|["']((?:https?:)?(?:\\/\\/|\/\/)[^"']+\\.(?:jpg|jpeg|png|webp|gif|avif)(?:\\?[^"']*)?)["']|(?:images|chapterImages|comicImages|photos|pics|imgList)["']?\\s*[:=]\\s*(\\[[\\s\\S]{0,6000}?\\])`,
    readerImageGroups: [1, 2, 3],
    userAgent: COMMON_USER_AGENT,
    referer: 'https://www.kaixinman.com/',
    readerNextPageRegex: `<a[^>]+href=["']([^"']+)["'][^>]*>(?:\\s*下一页\\s*|\\s*下页\\s*|\\s*Next\\s*|\\s*&gt;\\s*)<\/a>|rel=["']next["'][^>]+href=["']([^"']+)["']|href=["']([^"']+)["'][^>]+rel=["']next["']`,
    readerNextPageUrlGroups: [1, 2, 3],
    maxReaderPages: 12
  },
  {
    id: 'soullandmanga_public_access',
    name: 'SoulLandManga公开访问源（可在过滤中开关）',
    description: '公开网页可访问源：支持 Soul Land/Douluo Dalu 首页目录、章节链接和章节页图片提取；不绕过站点限制。',
    homepage: 'https://soullandmanga.com',
    searchUrl: 'https://soullandmanga.com/?s={keyword}',
    searchMethod: 'get',
    searchItemRegex: `<a[^>]+href=["']([^"']*soullandmanga\\.com\/manga\/[^"']+|\/manga\/[^"']+)["'][^>]*>([\\s\\S]{0,180}?)<\/a>`,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: false,
    detailChapterRegex: `<a[^>]+href=["']([^"']*\/manga\/soul-land-douluo-dalu-chapter-[^"']+)["'][^>]*>([\\s\\S]{0,180}?)<\/a>`,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: `<img[^>]+(?:data-original|data-src|data-lazy-src|data-url|src)=["']([^"']+)["'][^>]*>|["']((?:https?:)?\/\/[^"']+\\.(?:jpg|jpeg|png|webp|gif|avif)(?:\\?[^"']*)?)["']`,
    readerImageGroups: [1, 2],
    userAgent: COMMON_USER_AGENT,
    referer: 'https://soullandmanga.com/',
    readerNextPageRegex: `<a[^>]+href=["']([^"']+)["'][^>]*>(?:\\s*Next\\s*|\\s*下一页\\s*|\\s*&gt;\\s*)<\/a>|rel=["']next["'][^>]+href=["']([^"']+)["']|href=["']([^"']+)["'][^>]+rel=["']next["']`,
    readerNextPageUrlGroups: [1, 2, 3],
    maxReaderPages: 10
  },
  {
    id: 'mgeko_public_access',
    name: 'Mgeko公开访问源（可在过滤中开关）',
    description: '公开网页可访问源：用于搜索引擎发现后的作品页/章节页解析；只读取静态HTML和图片URL。',
    homepage: 'https://www.mgeko.cc',
    searchUrl: 'https://www.mgeko.cc/search?keyword={keyword}',
    searchMethod: 'get',
    searchItemRegex: `<a[^>]+href=["']([^"']*\/manga\/[^"']+)["'][^>]*>([\\s\\S]{0,240}?)<\/a>`,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: false,
    detailChapterRegex: `<a[^>]+href=["']([^"']*(?:\/chapter\/|\/read\/|chapter)[^"']+)["'][^>]*>([\\s\\S]{0,140}?)<\/a>`,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: `<img[^>]+(?:data-original|data-src|data-lazy-src|data-url|src)=["']([^"']+)["'][^>]*>|["']((?:https?:)?\/\/[^"']+\\.(?:jpg|jpeg|png|webp|gif|avif)(?:\\?[^"']*)?)["']`,
    readerImageGroups: [1, 2],
    userAgent: COMMON_USER_AGENT,
    referer: 'https://www.mgeko.cc/',
    readerNextPageRegex: `<a[^>]+href=["']([^"']+)["'][^>]*>(?:\\s*Next\\s*|\\s*下一页\\s*|\\s*&gt;\\s*)<\/a>|rel=["']next["'][^>]+href=["']([^"']+)["']|href=["']([^"']+)["'][^>]+rel=["']next["']`,
    readerNextPageUrlGroups: [1, 2, 3],
    maxReaderPages: 10
  },
  {
    id: 'webtoon_canvas_public_access',
    name: 'WEBTOON公开访问源（公开章节/Canvas）',
    description: '公开网页可访问源：用于 WEBTOON/CANVAS 搜索结果和公开章节图片解析；不处理App专属、登录墙或地区限制内容。',
    homepage: 'https://www.webtoons.com',
    searchUrl: 'https://www.webtoons.com/search?keyword={keyword}',
    searchMethod: 'get',
    searchItemRegex: `<a[^>]+href=["']([^"']*webtoons\\.com[^"']*(?:\/list|\/viewer)[^"']*)["'][^>]*>([\\s\\S]{0,360}?)<\/a>`,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: true,
    detailChapterRegex: `<a[^>]+href=["']([^"']*\/viewer\\?[^"']*episode_no=[^"']+)["'][^>]*>([\\s\\S]{0,220}?)<\/a>`,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: `<img[^>]+(?:data-original|data-src|data-lazy-src|data-url|src)=["']([^"']+)["'][^>]*>|["']((?:https?:)?\/\/[^"']+\\.(?:jpg|jpeg|png|webp|gif|avif)(?:\\?[^"']*)?)["']`,
    readerImageGroups: [1, 2],
    userAgent: COMMON_USER_AGENT,
    referer: 'https://www.webtoons.com/',
    maxReaderPages: 1
  },
  {
    id: 'manhuagui_catalog_public_access',
    name: '漫画柜公开目录源（可在过滤中开关）',
    description: '公开网页可访问源：主要用于目录/封面/搜索结果整理；章节图片若采用脚本加密或动态清单则不会绕过。',
    homepage: 'https://m.manhuagui.com',
    searchUrl: 'https://m.manhuagui.com/s/{keyword}.html',
    searchMethod: 'get',
    searchItemRegex: `<a[^>]+href=["']([^"']*\/comic\/[0-9]+\/[^"']*)["'][^>]*>([\\s\\S]{0,420}?)<\/a>`,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: true,
    detailChapterRegex: `<a[^>]+href=["']([^"']*\/comic\/[0-9]+\/[0-9]+\\.html[^"']*)["'][^>]*>([\\s\\S]{0,120}?)<\/a>`,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: `<img[^>]+(?:data-original|data-src|data-lazy-src|data-url|src)=["']([^"']+)["'][^>]*>|["']((?:https?:)?\/\/[^"']+\\.(?:jpg|jpeg|png|webp|gif|avif)(?:\\?[^"']*)?)["']`,
    readerImageGroups: [1, 2],
    userAgent: COMMON_USER_AGENT,
    referer: 'https://m.manhuagui.com/',
    maxReaderPages: 1
  },
  {
    id: 'douluodalu_cc_public_access',
    name: '斗罗大陆网公开访问源（可在过滤中开关）',
    description: '公开网页可访问源：适配 douluodalu.cc 系列作品页/目录/章节页；只解析页面里可直接访问的图片。',
    homepage: 'https://www.douluodalu.cc',
    searchUrl: 'https://www.douluodalu.cc/search?keyword={keyword}',
    searchMethod: 'get',
    searchItemRegex: `<a[^>]+href=["']([^"']*(?:\/manhua\/|\/comic\/)[^"']+)["'][^>]*>([\\s\\S]{0,260}?)<\/a>`,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: false,
    detailChapterRegex: `<a[^>]+href=["']([^"']*(?:\/manhua\/|\/comic\/)[^"']+)["'][^>]*>([\\s\\S]{0,120}?(?:第|话|章|Chapter)[\\s\\S]{0,80}?)<\/a>`,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: `<img[^>]+(?:data-original|data-src|data-lazy-src|data-url|src)=["']([^"']+)["'][^>]*>|["']((?:https?:)?\/\/[^"']+\\.(?:jpg|jpeg|png|webp|gif|avif)(?:\\?[^"']*)?)["']`,
    readerImageGroups: [1, 2],
    userAgent: COMMON_USER_AGENT,
    referer: 'https://www.douluodalu.cc/',
    readerNextPageRegex: `<a[^>]+href=["']([^"']+)["'][^>]*>(?:\\s*下一页\\s*|\\s*下页\\s*|\\s*Next\\s*|\\s*&gt;\\s*)<\/a>`,
    readerNextPageUrlGroups: [1],
    maxReaderPages: 10
  },
  {
    id: 'generic_html_public',
    name: '通用公开HTML源',
    description: '高级源：适合粘贴公开漫画详情页/章节页，支持静态HTML、懒加载、srcset、内联JS图片URL、多页章节的通用解析。主界面搜索不会默认使用它。',
    homepage: '',
    searchUrl: '',
    searchMethod: 'url-only',
    searchItemRegex: `<a[^>]+href=["']([^"']+)["'][^>]*>([\\s\\S]{0,160}?)<\\/a>`,
    searchTitleGroups: [2],
    searchUrlGroups: [1],
    searchCoverGroups: [],
    searchResultIsChapter: false,
    searchFilterByKeyword: false,
    detailChapterRegex: `<a[^>]+href=["']([^"']+)["'][^>]*>([\\s\\S]{0,180}?)<\\/a>`,
    detailChapterTitleGroups: [2],
    detailChapterUrlGroups: [1],
    detailChapterFilter: true,
    readerImageRegex: `<img[^>]+(?:data-original|data-src|data-lazy-src|data-url|src)=["']([^"']+)["'][^>]*>|srcset=["']([^"']+?\\.(?:jpg|jpeg|png|webp|gif)(?:\\?[^"']*)?)[^"']*["']|["']((?:https?:)?//[^"']+\\.(?:jpg|jpeg|png|webp|gif)(?:\\?[^"']*)?)["']`,
    readerImageGroups: [1, 2, 3],
    userAgent: COMMON_USER_AGENT,
    referer: '',
    readerNextPageRegex: `<a[^>]+href=["']([^"']+)["'][^>]*>(?:\\s*下一页\\s*|\\s*下页\\s*|\\s*Next\\s*|\\s*&gt;\\s*)<\\/a>|rel=["']next["'][^>]+href=["']([^"']+)["']|href=["']([^"']+)["'][^>]+rel=["']next["']`,
    readerNextPageUrlGroups: [1, 2, 3],
    maxReaderPages: 8
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


export function ruleForPublicUrl(url: string, fallback: ComicSourceRule): ComicSourceRule {
  const lower = url.toLowerCase();
  const find = (id: string): ComicSourceRule => {
    const found = DEFAULT_SOURCES.find((item: ComicSourceRule) => item.id === id);
    return found ? found : fallback;
  };
  if (lower.indexOf('m.ac.qq.com') >= 0 || lower.indexOf('comic.qq.com') >= 0 || lower.indexOf('ac.qq.com') >= 0) {
    return find('tencent_ac_official_catalog');
  }
  if (lower.indexOf('kaixinman.com') >= 0) {
    return find('kaixinman_public_access');
  }
  if (lower.indexOf('soullandmanga.com') >= 0) {
    return find('soullandmanga_public_access');
  }
  if (lower.indexOf('mgeko.cc') >= 0) {
    return find('mgeko_public_access');
  }
  if (lower.indexOf('webtoons.com') >= 0) {
    return find('webtoon_canvas_public_access');
  }
  if (lower.indexOf('manhuagui.com') >= 0 || lower.indexOf('happymh.com') >= 0) {
    return find('manhuagui_catalog_public_access');
  }
  if (lower.indexOf('douluodalu.cc') >= 0 || lower.indexOf('tangmen.app') >= 0 || lower.indexOf('longwangchuanshuo.com') >= 0) {
    return find('douluodalu_cc_public_access');
  }
  if (lower.indexOf('mh160mh.com') >= 0) {
    return find('mh160mh_public_access');
  }
  if (lower.indexOf('shenlanqiyu.cc') >= 0 || lower.indexOf('shenlanqiyu.org') >= 0) {
    return find('shenlanqiyu_public_access');
  }
  if (lower.indexOf('manhuaus.com') >= 0) {
    return find('manhuaus_public_access');
  }
  if (lower.indexOf('mangafire.to') >= 0) {
    return find('mangafire_public_access');
  }
  if (lower.indexOf('mangadna.com') >= 0) {
    return find('mangadna_public_access');
  }
  if (lower.indexOf('mangaread.org') >= 0) {
    return find('mangaread_public_access');
  }
  if (lower.indexOf('mycomic.com') >= 0) {
    return find('mycomic_public_access');
  }
  return fallback;
}

export function isUnverifiedPublicDomain(url: string): boolean {
  const lower = url.toLowerCase();
  return lower.indexOf('kaixinman.com') >= 0 ||
    lower.indexOf('soullandmanga.com') >= 0 ||
    lower.indexOf('mgeko.cc') >= 0 ||
    lower.indexOf('manhuagui.com') >= 0 ||
    lower.indexOf('happymh.com') >= 0 ||
    lower.indexOf('douluodalu.cc') >= 0 ||
    lower.indexOf('tangmen.app') >= 0 ||
    lower.indexOf('longwangchuanshuo.com') >= 0 ||
    lower.indexOf('mh160mh.com') >= 0 ||
    lower.indexOf('shenlanqiyu.cc') >= 0 ||
    lower.indexOf('shenlanqiyu.org') >= 0 ||
    lower.indexOf('manhuaus.com') >= 0 ||
    lower.indexOf('mangafire.to') >= 0 ||
    lower.indexOf('mangadna.com') >= 0 ||
    lower.indexOf('mangaread.org') >= 0 ||
    lower.indexOf('mycomic.com') >= 0;
}

export function isOfficialOrPublicCollectionDomain(url: string): boolean {
  const lower = url.toLowerCase();
  return lower.indexOf('m.ac.qq.com') >= 0 ||
    lower.indexOf('comic.qq.com') >= 0 ||
    lower.indexOf('ac.qq.com') >= 0 ||
    lower.indexOf('qidian.com') >= 0 ||
    lower.indexOf('webtoons.com') >= 0 ||
    lower.indexOf('archive.org') >= 0 ||
    lower.indexOf('openlibrary.org') >= 0 ||
    lower.indexOf('loc.gov') >= 0 ||
    lower.indexOf('wikimedia.org') >= 0 ||
    lower.indexOf('xkcd.com') >= 0 ||
    lower.indexOf('peppercarrot.com') >= 0;
}

export function isKnownLoginOrPayDomain(url: string): boolean {
  const lower = url.toLowerCase();
  return lower.indexOf('qidian.com') >= 0 ||
    lower.indexOf('mkzhan.com') >= 0 ||
    lower.indexOf('inkr.com') >= 0 ||
    lower.indexOf('utoon.net') >= 0 ||
    lower.indexOf('comix.to') >= 0 ||
    lower.indexOf('scribd.com') >= 0 ||
    lower.indexOf('webnovel.com') >= 0 ||
    lower.indexOf('jd.com') >= 0 ||
    lower.indexOf('amazon.') >= 0 ||
    lower.indexOf('youtube.com') >= 0 ||
    lower.indexOf('pinterest.') >= 0 ||
    lower.indexOf('reddit.com') >= 0 ||
    lower.indexOf('fandom.com') >= 0 ||
    lower.indexOf('readsoulland.com') >= 0 ||
    lower.indexOf('dstranslating.com') >= 0;
}

export function isTop20AuditedPublicReadableDomain(url: string): boolean {
  const lower = url.toLowerCase();
  return lower.indexOf('kaixinman.com') >= 0 ||
    lower.indexOf('soullandmanga.com') >= 0 ||
    lower.indexOf('manhuagui.com') >= 0 ||
    lower.indexOf('happymh.com') >= 0 ||
    lower.indexOf('mh160mh.com') >= 0 ||
    lower.indexOf('mgeko.cc') >= 0 ||
    lower.indexOf('webtoons.com') >= 0 ||
    lower.indexOf('manhuaus.com') >= 0 ||
    lower.indexOf('mangafire.to') >= 0 ||
    lower.indexOf('mangadna.com') >= 0 ||
    lower.indexOf('mangaread.org') >= 0 ||
    lower.indexOf('douluodalu.cc') >= 0 ||
    lower.indexOf('tangmen.app') >= 0 ||
    lower.indexOf('shenlanqiyu.cc') >= 0 ||
    lower.indexOf('shenlanqiyu.org') >= 0 ||
    lower.indexOf('mycomic.com') >= 0 ||
    lower.indexOf('m.ac.qq.com') >= 0 ||
    lower.indexOf('ac.qq.com') >= 0;
}
