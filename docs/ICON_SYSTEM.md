# ComicReader 图标系统

## 官方来源

- 图标库：Iconoir
- 官方网站：https://iconoir.com/
- 官方包：`iconoir@7.12.1`
- 包完整性：`sha512-7ei4jd1bss0Uk…9oG7IslW3hrLg==`
- 许可证：MIT
- 基础规格：24 × 24 SVG、规则线性描边

项目中的 `entry/src/main/resources/rawfile/ic_*.svg` 均从上述官方包的
`icons/regular/` 目录复制，保留 Iconoir 原始几何路径；界面层只通过
HarmonyOS `ColorFilter` 赋色，不修改图标比例或描边结构。

## 九尾九色

内部图标使用与九尾狐桌面图标一致的九色体系。同一功能在底部导航、
标题栏、设置页和弹窗中保持同色。

| 色系 | 色值 | 主要语义 |
| --- | --- | --- |
| 红 | `#FF3B30` | 关闭、返回、信息与其他控制 |
| 橙 | `#FF9500` | 书架、书籍、收藏 |
| 黄 | `#F5C400` | 语言、筛选 |
| 绿 | `#34C759` | 设置、调节 |
| 青 | `#00C7BE` | 刷新、搜索引擎 |
| 蓝 | `#0A84FF` | 搜索、网页、全网 |
| 靛 | `#5856D6` | 规则、代码 |
| 紫 | `#AF52DE` | 历史、时间 |
| 洋红 | `#FF2D92` | 阅读、布局、全屏 |

## 功能到 Iconoir 原名映射

| 项目资源 | Iconoir 7.12.1 原名 |
| --- | --- |
| `ic_search.svg` | `search.svg` |
| `ic_shelf.svg` | `bookmark-book.svg` |
| `ic_history.svg` | `clock-rotate-right.svg` |
| `ic_settings.svg` | `settings.svg` |
| `ic_home.svg` | `home-simple.svg` |
| `ic_rule.svg` | `database-script.svg` |
| `ic_engine.svg` | `search-engine.svg` |
| `ic_filter.svg` | `filter-list.svg` |
| `ic_language.svg` | `language.svg` |
| `ic_reader.svg`, `ic_reading.svg` | `open-book.svg` |
| `ic_refresh.svg` | `refresh-double.svg` |
| `ic_layout.svg` | `view-grid.svg` |
| `ic_fullscreen.svg` | `expand.svg` |
| `ic_moon.svg` | `half-moon.svg` |
| `ic_back.svg` | `nav-arrow-left.svg` |
| `ic_close.svg`, `ic_x.svg` | `xmark.svg` |
| `ic_more.svg` | `more-horiz.svg` |
| `ic_add_shelf.svg` | `plus-circle.svg` |
| `ic_info.svg`, `ic_about.svg` | `info-circle.svg` |

新增图标时必须从同一锁定版本选择，并同步更新本表；不得混入其他图标库。
