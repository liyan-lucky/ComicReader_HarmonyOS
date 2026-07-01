export interface ComicSourceRule {
  id: string;
  name: string;
  description: string;
  homepage: string;
  searchUrl: string;
  searchMethod: string;
  searchItemRegex: string;
  searchTitleGroups: number[];
  searchUrlGroups: number[];
  searchCoverGroups: number[];
  searchResultIsChapter: boolean;
  searchFilterByKeyword: boolean;
  detailChapterRegex: string;
  detailChapterTitleGroups: number[];
  detailChapterUrlGroups: number[];
  detailChapterFilter: boolean;
  readerImageRegex: string;
  readerImageGroups: number[];
  userAgent: string;
  referer: string;
  /** 章节页下一页正则。用于一话拆成多页的公开 HTML 源。 */
  readerNextPageRegex?: string;
  /** 下一页 URL 所在捕获组，默认 [1]。 */
  readerNextPageUrlGroups?: number[];
  /** 章节页最多追踪页数，避免死循环，默认 1。 */
  maxReaderPages?: number;
}

export interface SearchEngineConfig {
  id: string;
  name: string;
  description: string;
  engineType: string;
  searchUrl: string;
  requiresKey: boolean;
  enabled: boolean;
}

export interface SearchResultItem {
  title: string;
  url: string;
  cover: string;
  sourceId: string;
  sourceName: string;
  isChapter: boolean;
  resultType?: string;
  groupName?: string;
  description?: string;
  /** 作者，搜索源未提供时留空，UI 会显示未知作者。 */
  author?: string;
  /** 最新章节，搜索源未提供时留空，UI 会显示待获取。 */
  latestChapter?: string;
  /** 更新时间，搜索源未提供时留空，UI 会显示待获取。 */
  updateTime?: string;
  /** 题材分类，搜索页不再按此分组，后续用于书架题材推荐。 */
  category?: string;
}

export interface ResultGroup {
  name: string;
  key: string;
  count: number;
  items: SearchResultItem[];
}

export interface ChapterItem {
  title: string;
  url: string;
  index: number;
  sourceId: string;
}

export interface ReaderImageItem {
  url: string;
  index: number;
  status: string;
}

export interface ReadingHistoryItem {
  title: string;
  chapterTitle: string;
  url: string;
  sourceName: string;
  timeText: string;
}

export interface BookshelfItem {
  title: string;
  url: string;
  cover: string;
  sourceId: string;
  sourceName: string;
  lastChapterTitle: string;
  addedTimeText: string;
  lastReadTimeText: string;
  /** 最近阅读章节 URL，用于从书架继续阅读。 */
  lastReadUrl?: string;
  /** 估算阅读进度百分比。章节目录无法准确计算时保留最近值。 */
  progressPercent?: number;
  /** 累计打开阅读次数，用于书架管理排序和展示。 */
  readCount?: number;
}
