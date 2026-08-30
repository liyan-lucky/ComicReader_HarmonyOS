import { ComicSourceRule } from '../model/ComicModels';

/**
 * 自动生成文件：请不要手工修改。
 * 来源：15_ComicReader_Rules/rules/index.zh-Hans.json
 * 仅同步已经过规则仓库回放审计的按域名公开网页规则。
 */
export const GENERATED_SOURCES: ComicSourceRule[] = [
    {
        "id":  "288manhua_com",
        "name":  "288manhua.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://288manhua.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://288manhua.com/",
        "domainApplicabilityList":  [
                                        "288manhua.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "590ac_com",
        "name":  "590ac.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://590ac.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://590ac.com/",
        "domainApplicabilityList":  [
                                        "590ac.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "5imanhua_click",
        "name":  "5imanhua.click 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://5imanhua.click",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://5imanhua.click/",
        "domainApplicabilityList":  [
                                        "5imanhua.click"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "ac_qq_com",
        "name":  "ac.qq.com 已验证公开源",
        "description":  "由 25 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://ac.qq.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://ac.qq.com/",
        "domainApplicabilityList":  [
                                        "ac.qq.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "akmh666_com",
        "name":  "akmh666.com 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://akmh666.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://akmh666.com/",
        "domainApplicabilityList":  [
                                        "akmh666.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "asshow_com",
        "name":  "asshow.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://asshow.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://asshow.com/",
        "domainApplicabilityList":  [
                                        "asshow.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "b_faloo_com",
        "name":  "b.faloo.com 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://b.faloo.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://b.faloo.com/",
        "domainApplicabilityList":  [
                                        "b.faloo.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "baoziaicomic_com",
        "name":  "baoziaicomic.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://baoziaicomic.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://baoziaicomic.com/",
        "domainApplicabilityList":  [
                                        "baoziaicomic.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "bjzf_org",
        "name":  "bjzf.org 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://bjzf.org",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://bjzf.org/",
        "domainApplicabilityList":  [
                                        "bjzf.org"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "bkmh555_com",
        "name":  "bkmh555.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://bkmh555.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://bkmh555.com/",
        "domainApplicabilityList":  [
                                        "bkmh555.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "bury_bljipeapy_com",
        "name":  "bury.bljipeapy.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://bury.bljipeapy.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://bury.bljipeapy.com/",
        "domainApplicabilityList":  [
                                        "bury.bljipeapy.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "cdt-gz_cn",
        "name":  "cdt-gz.cn 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://cdt-gz.cn",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://cdt-gz.cn/",
        "domainApplicabilityList":  [
                                        "cdt-gz.cn"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "china-armature_com",
        "name":  "china-armature.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://china-armature.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://china-armature.com/",
        "domainApplicabilityList":  [
                                        "china-armature.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "comic_qq_com",
        "name":  "comic.qq.com 已验证公开源",
        "description":  "由 10 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://comic.qq.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://comic.qq.com/",
        "domainApplicabilityList":  [
                                        "comic.qq.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "cuimanhua_com",
        "name":  "cuimanhua.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://cuimanhua.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://cuimanhua.com/",
        "domainApplicabilityList":  [
                                        "cuimanhua.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "cuimh_com",
        "name":  "cuimh.com 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://cuimh.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://cuimh.com/",
        "domainApplicabilityList":  [
                                        "cuimh.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "cxjob_com_cn",
        "name":  "cxjob.com.cn 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://cxjob.com.cn",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://cxjob.com.cn/",
        "domainApplicabilityList":  [
                                        "cxjob.com.cn"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "dafumh_com",
        "name":  "dafumh.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://dafumh.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://dafumh.com/",
        "domainApplicabilityList":  [
                                        "dafumh.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "dagumh_com",
        "name":  "dagumh.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://dagumh.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://dagumh.com/",
        "domainApplicabilityList":  [
                                        "dagumh.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "dandanmh_com",
        "name":  "dandanmh.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://dandanmh.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://dandanmh.com/",
        "domainApplicabilityList":  [
                                        "dandanmh.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "dayiming_cn",
        "name":  "dayiming.cn 已验证公开源",
        "description":  "由 4 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://dayiming.cn",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://dayiming.cn/",
        "domainApplicabilityList":  [
                                        "dayiming.cn"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "dhan_cc",
        "name":  "dhan.cc 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://dhan.cc",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://dhan.cc/",
        "domainApplicabilityList":  [
                                        "dhan.cc"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "digumh_com",
        "name":  "digumh.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://digumh.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://digumh.com/",
        "domainApplicabilityList":  [
                                        "digumh.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "dongman_qq_com",
        "name":  "dongman.qq.com 已验证公开源",
        "description":  "由 3 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://dongman.qq.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://dongman.qq.com/",
        "domainApplicabilityList":  [
                                        "dongman.qq.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "dongmanmanhua_cn",
        "name":  "dongmanmanhua.cn 已验证公开源",
        "description":  "由 14 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://dongmanmanhua.cn",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://dongmanmanhua.cn/",
        "domainApplicabilityList":  [
                                        "dongmanmanhua.cn"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "duiduimanhua_com",
        "name":  "duiduimanhua.com 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://duiduimanhua.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://duiduimanhua.com/",
        "domainApplicabilityList":  [
                                        "duiduimanhua.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "duya_cc",
        "name":  "duya.cc 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://duya.cc",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://duya.cc/",
        "domainApplicabilityList":  [
                                        "duya.cc"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "ffppt_com",
        "name":  "ffppt.com 已验证公开源",
        "description":  "由 3 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://ffppt.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://ffppt.com/",
        "domainApplicabilityList":  [
                                        "ffppt.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "guazixs_cn",
        "name":  "guazixs.cn 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://guazixs.cn",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://guazixs.cn/",
        "domainApplicabilityList":  [
                                        "guazixs.cn"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "hazelmaka_com",
        "name":  "hazelmaka.com 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://hazelmaka.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://hazelmaka.com/",
        "domainApplicabilityList":  [
                                        "hazelmaka.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "hfuodip_com",
        "name":  "hfuodip.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://hfuodip.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://hfuodip.com/",
        "domainApplicabilityList":  [
                                        "hfuodip.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "hongshu_com",
        "name":  "hongshu.com 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://hongshu.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://hongshu.com/",
        "domainApplicabilityList":  [
                                        "hongshu.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "hqqh_cc",
        "name":  "hqqh.cc 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://hqqh.cc",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://hqqh.cc/",
        "domainApplicabilityList":  [
                                        "hqqh.cc"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "htzsgc_cn",
        "name":  "htzsgc.cn 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://htzsgc.cn",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://htzsgc.cn/",
        "domainApplicabilityList":  [
                                        "htzsgc.cn"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "huayangdm_com",
        "name":  "huayangdm.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://huayangdm.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://huayangdm.com/",
        "domainApplicabilityList":  [
                                        "huayangdm.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "huozx_net",
        "name":  "huozx.net 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://huozx.net",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://huozx.net/",
        "domainApplicabilityList":  [
                                        "huozx.net"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "jiexi8_com",
        "name":  "jiexi8.com 已验证公开源",
        "description":  "由 8 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://jiexi8.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://jiexi8.com/",
        "domainApplicabilityList":  [
                                        "jiexi8.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "jincs_cn",
        "name":  "jincs.cn 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://jincs.cn",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://jincs.cn/",
        "domainApplicabilityList":  [
                                        "jincs.cn"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "jiujiumanhua_com",
        "name":  "jiujiumanhua.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://jiujiumanhua.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://jiujiumanhua.com/",
        "domainApplicabilityList":  [
                                        "jiujiumanhua.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "jjwxc_net",
        "name":  "jjwxc.net 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://jjwxc.net",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://jjwxc.net/",
        "domainApplicabilityList":  [
                                        "jjwxc.net"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "jsmanhuawang_com",
        "name":  "jsmanhuawang.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://jsmanhuawang.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://jsmanhuawang.com/",
        "domainApplicabilityList":  [
                                        "jsmanhuawang.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "katadyngroup_com_cn",
        "name":  "katadyngroup.com.cn 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://katadyngroup.com.cn",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://katadyngroup.com.cn/",
        "domainApplicabilityList":  [
                                        "katadyngroup.com.cn"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "kkwebtoon_com",
        "name":  "kkwebtoon.com 已验证公开源",
        "description":  "由 5 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://kkwebtoon.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://kkwebtoon.com/",
        "domainApplicabilityList":  [
                                        "kkwebtoon.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "kuaikan321_com",
        "name":  "kuaikan321.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://kuaikan321.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://kuaikan321.com/",
        "domainApplicabilityList":  [
                                        "kuaikan321.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "kuaikanmanhua_com",
        "name":  "kuaikanmanhua.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://kuaikanmanhua.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://kuaikanmanhua.com/",
        "domainApplicabilityList":  [
                                        "kuaikanmanhua.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "m_bikamanhua_com",
        "name":  "m.bikamanhua.com 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://m.bikamanhua.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://m.bikamanhua.com/",
        "domainApplicabilityList":  [
                                        "m.bikamanhua.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "m_bjwsxx_com",
        "name":  "m.bjwsxx.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://m.bjwsxx.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://m.bjwsxx.com/",
        "domainApplicabilityList":  [
                                        "m.bjwsxx.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "m_dagumanhua_cc",
        "name":  "m.dagumanhua.cc 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://m.dagumanhua.cc",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://m.dagumanhua.cc/",
        "domainApplicabilityList":  [
                                        "m.dagumanhua.cc"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "m_dumanwu_com",
        "name":  "m.dumanwu.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://m.dumanwu.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://m.dumanwu.com/",
        "domainApplicabilityList":  [
                                        "m.dumanwu.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "m_dumanwu1_com",
        "name":  "m.dumanwu1.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://m.dumanwu1.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://m.dumanwu1.com/",
        "domainApplicabilityList":  [
                                        "m.dumanwu1.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "m_guozhenglawyer_com",
        "name":  "m.guozhenglawyer.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://m.guozhenglawyer.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://m.guozhenglawyer.com/",
        "domainApplicabilityList":  [
                                        "m.guozhenglawyer.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "m_haohuagg_com",
        "name":  "m.haohuagg.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://m.haohuagg.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://m.haohuagg.com/",
        "domainApplicabilityList":  [
                                        "m.haohuagg.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "m_jingmingbg_com",
        "name":  "m.jingmingbg.com 已验证公开源",
        "description":  "由 3 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://m.jingmingbg.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://m.jingmingbg.com/",
        "domainApplicabilityList":  [
                                        "m.jingmingbg.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "m_maomimh_com",
        "name":  "m.maomimh.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://m.maomimh.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://m.maomimh.com/",
        "domainApplicabilityList":  [
                                        "m.maomimh.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "m_ortzn_com",
        "name":  "m.ortzn.com 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://m.ortzn.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://m.ortzn.com/",
        "domainApplicabilityList":  [
                                        "m.ortzn.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "m_sisimanhua_com",
        "name":  "m.sisimanhua.com 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://m.sisimanhua.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://m.sisimanhua.com/",
        "domainApplicabilityList":  [
                                        "m.sisimanhua.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "m_tcsrq_cn",
        "name":  "m.tcsrq.cn 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://m.tcsrq.cn",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://m.tcsrq.cn/",
        "domainApplicabilityList":  [
                                        "m.tcsrq.cn"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "manbatu_com",
        "name":  "manbatu.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://manbatu.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://manbatu.com/",
        "domainApplicabilityList":  [
                                        "manbatu.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "mangatoon_mobi",
        "name":  "mangatoon.mobi 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://mangatoon.mobi",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://mangatoon.mobi/",
        "domainApplicabilityList":  [
                                        "mangatoon.mobi"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "manhua1234_com",
        "name":  "manhua1234.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://manhua1234.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://manhua1234.com/",
        "domainApplicabilityList":  [
                                        "manhua1234.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "manhuarenren_com",
        "name":  "manhuarenren.com 已验证公开源",
        "description":  "由 3 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://manhuarenren.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://manhuarenren.com/",
        "domainApplicabilityList":  [
                                        "manhuarenren.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "maomaoks_com",
        "name":  "maomaoks.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://maomaoks.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://maomaoks.com/",
        "domainApplicabilityList":  [
                                        "maomaoks.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "mdb88_com",
        "name":  "mdb88.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://mdb88.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://mdb88.com/",
        "domainApplicabilityList":  [
                                        "mdb88.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "medyakey_com",
        "name":  "medyakey.com 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://medyakey.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://medyakey.com/",
        "domainApplicabilityList":  [
                                        "medyakey.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "mh250_cc",
        "name":  "mh250.cc 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://mh250.cc",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://mh250.cc/",
        "domainApplicabilityList":  [
                                        "mh250.cc"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "mh250_com",
        "name":  "mh250.com 已验证公开源",
        "description":  "由 31 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://mh250.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://mh250.com/",
        "domainApplicabilityList":  [
                                        "mh250.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "mhz4_com",
        "name":  "mhz4.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://mhz4.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://mhz4.com/",
        "domainApplicabilityList":  [
                                        "mhz4.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "mobile_ac_qq_com",
        "name":  "mobile.ac.qq.com 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://mobile.ac.qq.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://mobile.ac.qq.com/",
        "domainApplicabilityList":  [
                                        "mobile.ac.qq.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "mwjsiot_com",
        "name":  "mwjsiot.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://mwjsiot.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://mwjsiot.com/",
        "domainApplicabilityList":  [
                                        "mwjsiot.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "mzywwcm_com",
        "name":  "mzywwcm.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://mzywwcm.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://mzywwcm.com/",
        "domainApplicabilityList":  [
                                        "mzywwcm.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "nhy2_com",
        "name":  "nhy2.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://nhy2.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://nhy2.com/",
        "domainApplicabilityList":  [
                                        "nhy2.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "nubbub_com",
        "name":  "nubbub.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://nubbub.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://nubbub.com/",
        "domainApplicabilityList":  [
                                        "nubbub.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "pdbgds_com",
        "name":  "pdbgds.com 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://pdbgds.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://pdbgds.com/",
        "domainApplicabilityList":  [
                                        "pdbgds.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "pufeimanhuaw_com",
        "name":  "pufeimanhuaw.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://pufeimanhuaw.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://pufeimanhuaw.com/",
        "domainApplicabilityList":  [
                                        "pufeimanhuaw.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "runshua_com",
        "name":  "runshua.com 已验证公开源",
        "description":  "由 4 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://runshua.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://runshua.com/",
        "domainApplicabilityList":  [
                                        "runshua.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "sdxqx_com",
        "name":  "sdxqx.com 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://sdxqx.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://sdxqx.com/",
        "domainApplicabilityList":  [
                                        "sdxqx.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "sfmanhua_com",
        "name":  "sfmanhua.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://sfmanhua.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://sfmanhua.com/",
        "domainApplicabilityList":  [
                                        "sfmanhua.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "shenqimanhua_net",
        "name":  "shenqimanhua.net 已验证公开源",
        "description":  "由 23 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://shenqimanhua.net",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://shenqimanhua.net/",
        "domainApplicabilityList":  [
                                        "shenqimanhua.net"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "shilunmh_com",
        "name":  "shilunmh.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://shilunmh.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://shilunmh.com/",
        "domainApplicabilityList":  [
                                        "shilunmh.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "shoujimanhua_com",
        "name":  "shoujimanhua.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://shoujimanhua.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://shoujimanhua.com/",
        "domainApplicabilityList":  [
                                        "shoujimanhua.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "songyuanman_com",
        "name":  "songyuanman.com 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://songyuanman.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://songyuanman.com/",
        "domainApplicabilityList":  [
                                        "songyuanman.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "sqmh_app",
        "name":  "sqmh.app 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://sqmh.app",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://sqmh.app/",
        "domainApplicabilityList":  [
                                        "sqmh.app"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "sqrsks_com",
        "name":  "sqrsks.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://sqrsks.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://sqrsks.com/",
        "domainApplicabilityList":  [
                                        "sqrsks.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "t_shuqi_com",
        "name":  "t.shuqi.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://t.shuqi.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://t.shuqi.com/",
        "domainApplicabilityList":  [
                                        "t.shuqi.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "tcsrq_cn",
        "name":  "tcsrq.cn 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://tcsrq.cn",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://tcsrq.cn/",
        "domainApplicabilityList":  [
                                        "tcsrq.cn"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "tzysjx_cn",
        "name":  "tzysjx.cn 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://tzysjx.cn",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://tzysjx.cn/",
        "domainApplicabilityList":  [
                                        "tzysjx.cn"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "veryim_com",
        "name":  "veryim.com 已验证公开源",
        "description":  "由 8 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://veryim.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://veryim.com/",
        "domainApplicabilityList":  [
                                        "veryim.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "wap_faloo_com",
        "name":  "wap.faloo.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://wap.faloo.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://wap.faloo.com/",
        "domainApplicabilityList":  [
                                        "wap.faloo.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "xhp119_com",
        "name":  "xhp119.com 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://xhp119.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://xhp119.com/",
        "domainApplicabilityList":  [
                                        "xhp119.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "xhp124_com",
        "name":  "xhp124.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://xhp124.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://xhp124.com/",
        "domainApplicabilityList":  [
                                        "xhp124.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "xkanmanhua_com",
        "name":  "xkanmanhua.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://xkanmanhua.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://xkanmanhua.com/",
        "domainApplicabilityList":  [
                                        "xkanmanhua.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "yandans_com",
        "name":  "yandans.com 已验证公开源",
        "description":  "由 2 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://yandans.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://yandans.com/",
        "domainApplicabilityList":  [
                                        "yandans.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "yinglifan_com",
        "name":  "yinglifan.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://yinglifan.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://yinglifan.com/",
        "domainApplicabilityList":  [
                                        "yinglifan.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "yiningguanggao_com",
        "name":  "yiningguanggao.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://yiningguanggao.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://yiningguanggao.com/",
        "domainApplicabilityList":  [
                                        "yiningguanggao.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "yinxiang17_com",
        "name":  "yinxiang17.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://yinxiang17.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://yinxiang17.com/",
        "domainApplicabilityList":  [
                                        "yinxiang17.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "yixiuche_com",
        "name":  "yixiuche.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://yixiuche.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://yixiuche.com/",
        "domainApplicabilityList":  [
                                        "yixiuche.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "youzimanhua_com",
        "name":  "youzimanhua.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://youzimanhua.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://youzimanhua.com/",
        "domainApplicabilityList":  [
                                        "youzimanhua.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "z525_com",
        "name":  "z525.com 已验证公开源",
        "description":  "由 10 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://z525.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://z525.com/",
        "domainApplicabilityList":  [
                                        "z525.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "zgmanhua_com",
        "name":  "zgmanhua.com 已验证公开源",
        "description":  "由 58 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://zgmanhua.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://zgmanhua.com/",
        "domainApplicabilityList":  [
                                        "zgmanhua.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "zhongkeman_com",
        "name":  "zhongkeman.com 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://zhongkeman.com",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://zhongkeman.com/",
        "domainApplicabilityList":  [
                                        "zhongkeman.com"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    },
    {
        "id":  "zymk_cn",
        "name":  "zymk.cn 已验证公开源",
        "description":  "由 1 部作品首/中/末章回放验证；每域一条规则。",
        "homepage":  "https://zymk.cn",
        "searchUrl":  "",
        "searchMethod":  "url-only",
        "searchItemRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{1,240}?)\u003c\\/a\u003e",
        "searchTitleGroups":  [
                                  2
                              ],
        "searchUrlGroups":  [
                                1
                            ],
        "searchCoverGroups":  [

                              ],
        "searchResultIsChapter":  false,
        "searchFilterByKeyword":  true,
        "detailChapterRegex":  "\u003ca[^\u003e]+href=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e([\\s\\S]{0,180}?(?:第\\s*\\d+|第[一二三四五六七八九十百千零〇两]+|话|章|回|Chapter|Episode)[\\s\\S]{0,100}?)\u003c\\/a\u003e",
        "detailChapterTitleGroups":  [
                                         2
                                     ],
        "detailChapterUrlGroups":  [
                                       1
                                   ],
        "detailChapterFilter":  true,
        "readerImageRegex":  "\u003cimg[^\u003e]+(?:data-original|data-src|data-lazy-src|data-url|src|srcset)=[\"\\\u0027]([^\"\\\u0027]+)[\"\\\u0027][^\u003e]*\u003e|[\"\\\u0027]((?:https?:)?\\/\\/[^\"\\\u0027]+\\.(?:jpg|jpeg|png|webp|avif)(?:\\?[^\"\\\u0027]*)?)[\"\\\u0027]",
        "readerImageGroups":  [
                                  1,
                                  2
                              ],
        "userAgent":  "Mozilla/5.0 (Linux; HarmonyOS; Mobile) AppleWebKit/537.36 Chrome/124 Mobile Safari/537.36 ComicReader",
        "referer":  "https://zymk.cn/",
        "domainApplicabilityList":  [
                                        "zymk.cn"
                                    ],
        "maxReaderPages":  12,
        "license":  "MIT",
        "sourceType":  "verified-public-domain-rule"
    }
];